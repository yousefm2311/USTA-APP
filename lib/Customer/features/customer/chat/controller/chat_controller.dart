import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:get/get.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/features/customer/chat/services/chat_realtime_service.dart';
import 'package:usta/Customer/core/utils/constants/api_endpoints.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/Customer/core/services/upload/media_upload_service.dart';
import 'package:usta/Customer/core/services/upload/image_compressor.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/core/services/network/api_client.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/realtime/realtime_controller.dart';
import 'package:path_provider/path_provider.dart';

class ChatController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final ChatRealtimeService _rtService = Get.find<ChatRealtimeService>(tag: 'customer');
  final AuthController? _auth = Get.isRegistered<AuthController>(tag: 'customer')
      ? Get.find<AuthController>(tag: 'customer')
      : null;
  final ApiClient _apiClient = Get.find<ApiClient>(tag: 'customer');
  late final MediaUploadService _uploadService;
  final TokenStorage _tokenStorage = Get.find<TokenStorage>(tag: 'customer');
  final RealtimeController _rtController = Get.find<RealtimeController>(tag: 'customer');

  final RxList<Map<String, dynamic>> chats = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  final RxBool loadingChats = false.obs;
  final RxBool loadingMessages = false.obs;
  final RxBool sending = false.obs;
  final RxBool isBlocked = false.obs;

  String? _activeRequestId;
  String? _activeArtisanId;
  String? _customerId;
  int _inFlightSends = 0;
  int _localCounter = 0;
  Timer? _chatsPollTimer;

  String? get activeRequestId => _activeRequestId;
  String? get activeArtisanId => _activeArtisanId;
  String? get customerId => _customerId;
  bool get _socketReady => _rtService.isConnected;

  @override
  void onInit() {
    super.onInit();
    _uploadService = MediaUploadService(dio: _apiClient.dio);
    _bootstrapUserId();
    fetchChats();
    _rtService.start();
  }

  void _bootstrapUserId() {
    final id = _ensureCustomerId();
    if (id != null && id.isNotEmpty) {
      _rtService.subscribeToDirect(id);
      _rtController.joinCustomerRoom(id);
    }
  }

  Future<void> fetchChats() async {
    loadingChats.value = true;
    try {
      final res = await _repo.api.listChats();
      final data = res['data'] ?? res;
      final requestChatsRaw =
          (data is Map ? data['requestChats'] ?? data['requests'] : []) ?? [];
      final directChatsRaw =
          (data is Map ? data['directChats'] ?? data['direct'] : []) ?? [];
      final combined = <Map<String, dynamic>>[];

      if (requestChatsRaw is List) {
        combined.addAll(
          requestChatsRaw
              .map<Map<String, dynamic>>(
                (e) => _normalizeChatItem(e, type: 'request'),
              )
              .where((e) => e.isNotEmpty),
        );
      }
      if (directChatsRaw is List) {
        combined.addAll(
          directChatsRaw
              .map<Map<String, dynamic>>(
                (e) => _normalizeChatItem(e, type: 'direct'),
              )
              .where((e) => e.isNotEmpty),
        );
      }
      final merged = _mergeChatsWithLocal(combined);
      chats.assignAll(merged);
      for (final chat in combined) {
        final type = chat['type']?.toString();
        if (type == 'request') {
          final rid = chat['requestId']?.toString() ?? '';
          if (rid.isNotEmpty) _rtService.subscribeToRequest(rid);
        } else if (type == 'direct') {
          final cid = chat['customerId']?.toString() ?? _customerId ?? '';
          final aid = chat['artisanId']?.toString() ?? '';
          if (cid.isNotEmpty && aid.isNotEmpty) {
            _rtService.subscribeToDirect(cid, artisanId: aid);
          }
        }
      }
      final selfId = _ensureCustomerId();
      if (selfId != null && selfId.isNotEmpty) {
        _rtService.subscribeToDirect(selfId);
        _rtController.joinCustomerRoom(selfId);
      }
      if (!_rtService.isConnected) {
        _rtController.reconnect();
      }
      if (_customerId == null && combined.isNotEmpty) {
        _customerId = combined
            .map((c) => c['customerId']?.toString())
            .firstWhere(
              (id) => id != null && id.isNotEmpty,
              orElse: () => null,
            );
      }
    } on ApiException catch (e) {
      AppSnackBar.show('خطأ'.tr, e.message);
    } catch (e) {
      AppSnackBar.show('خطأ'.tr, 'تعذر جلب المحادثات'.tr);
    } finally {
      loadingChats.value = false;
    }
  }

  List<Map<String, dynamic>> _mergeChatsWithLocal(
    List<Map<String, dynamic>> fresh,
  ) {
    if (chats.isEmpty) return fresh;

    final existingByKey = <String, Map<String, dynamic>>{};
    for (final chat in chats) {
      final key = _chatKey(chat);
      if (key.isNotEmpty) {
        existingByKey[key] = chat;
      }
    }

    final merged = <Map<String, dynamic>>[];
    for (final chat in fresh) {
      final key = _chatKey(chat);
      final local = key.isNotEmpty ? existingByKey[key] : null;
      if (local == null) {
        merged.add(chat);
        continue;
      }

      final localUnread = _toInt(local['unreadCount']);
      final freshUnread = _toInt(chat['unreadCount']);
      final keepLocalUnread =
          freshUnread == 0 && localUnread > 0 && !_isActiveChat(local);

      final localLastAt =
          (local['lastMessageAt'] ?? local['updatedAt'])?.toString() ?? '';
      final freshLastAt =
          (chat['lastMessageAt'] ?? chat['updatedAt'])?.toString() ?? '';
      final keepLocalLastAt = freshLastAt.isEmpty && localLastAt.isNotEmpty;

      merged.add({
        ...local,
        ...chat,
        if (keepLocalUnread) 'unreadCount': localUnread,
        if (keepLocalLastAt) 'lastMessageAt': localLastAt,
        if (chat['adminNotice'] == null && local['adminNotice'] != null)
          'adminNotice': local['adminNotice'],
      });
    }

    return merged;
  }

  Future<void> fetchMessages(String id, {bool direct = false}) async {
    if (id.isEmpty) return;
    _setActiveConversation(id, direct: direct);
    loadingMessages.value = true;
    isBlocked.value = false;
    try {
      Map<String, dynamic> res;
      if (direct) {
        res = await _repo.api.directMessages(id);
      } else {
        await _repo.api.openChat(id);
        res = await _repo.api.chatMessages(id);
      }
      final list = res['messages'] ?? res['data'] ?? [];
      if (list is List) {
        messages.assignAll(
          list
              .map<Map<String, dynamic>>(
                (e) => e is Map<String, dynamic> ? _normalizeMessage(e) : {},
              )
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      } else {
        messages.clear();
      }
      _resubscribeActive();
      _markUnreadAsRead(direct: direct);
    } finally {
      loadingMessages.value = false;
    }
  }

  Map<String, dynamic> _normalizeChatItem(dynamic raw, {required String type}) {
    if (raw is! Map<String, dynamic>) return {};
    final m = Map<String, dynamic>.from(raw);
    final last =
        (m['lastMessage'] ??
            m['lastMessageText'] ??
            (m['message'] is Map ? m['message'] : null)) ??
        {};
    final lastMap = last is Map<String, dynamic> ? last : <String, dynamic>{};
    final lastText = (lastMap['text'] ?? lastMap['message'] ?? '').toString();
    final isAdminLast = _isAdminMessage(lastMap);
    final adminName = _adminDisplayName(lastMap);
    final lastAt =
        (lastMap['createdAt'] ??
                lastMap['updatedAt'] ??
                m['updatedAt'] ??
                m['lastMessageAt'])
            ?.toString();
    final unread = m['unreadCount'] is num
        ? (m['unreadCount'] as num).toInt()
        : 0;
    final customer = (m['customer'] is Map<String, dynamic>)
        ? m['customer'] as Map<String, dynamic>
        : <String, dynamic>{};
    final artisan = (m['artisan'] is Map<String, dynamic>)
        ? m['artisan'] as Map<String, dynamic>
        : <String, dynamic>{};
    final peerName = isAdminLast
        ? adminName
        : type == 'direct'
            ? (artisan['name'] ?? m['artisanName'] ?? m['name'])
            : (m['artisanName'] ??
                artisan['name'] ??
                m['customerName'] ??
                customer['name']);
    return {
      ...m,
      'type': type,
      'customerId': m['customerId'] ?? customer['_id'],
      'artisanId': m['artisanId'] ?? artisan['_id'],
      'customerName': m['customerName'] ?? customer['name'],
      'peerName': peerName,
      'lastMessage': lastText,
      'lastMessageText': lastText,
      'lastMessageAt': lastAt,
      'unreadCount': unread,
      'adminNotice': isAdminLast,
      if (type == 'request')
        'requestId': m['requestId'] ?? m['request'] ?? m['_id'] ?? m['id'],
    };
  }

  String addPendingAttachment({
    required String type,
    required String placeholderAttachment,
    String? requestId,
    String? customerId,
    String text = '',
  }) {
    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final resolvedText = text.isEmpty ? _placeholderForType(type) : text;
    final msg = {
      'localId': localId,
      'message': resolvedText,
      'text': resolvedText,
      'type': type,
      'createdAt': DateTime.now().toIso8601String(),
      'state': 'sending',
      'isMine': true,
      'sender': 'customer',
      'role': 'customer',
      'attachments': [placeholderAttachment],
      if (_customerId != null) 'customerId': _customerId,
      if (requestId != null) 'requestId': requestId,
      if (customerId != null) 'artisanId': customerId,
      if (customerId != null) 'direct': true,
    };
    messages.add(msg);
    messages.refresh();
    return localId;
  }

  Future<void> sendTextMessage(
    String id,
    String text, {
    bool direct = false,
  }) async {
    await _sendMessage(
      conversationId: id,
      type: 'text',
      text: text.trim(),
      direct: direct,
    );
  }

  Future<void> sendRequestAttachment(
    String requestId, {
    required String dataUri,
    required String mime,
    String? localId,
  }) {
    return _uploadAndSendAttachment(
      conversationId: requestId,
      dataUri: dataUri,
      mime: mime,
      localId: localId,
      direct: false,
    );
  }

  Future<void> sendDirectAttachment(
    String otherId, {
    required String dataUri,
    required String mime,
    String? localId,
  }) {
    return _uploadAndSendAttachment(
      conversationId: otherId,
      dataUri: dataUri,
      mime: mime,
      localId: localId,
      direct: true,
    );
  }

  Future<void> editDirectMessage(String messageId, String text) async {
    final newText = text.trim();
    if (messageId.isEmpty || newText.isEmpty) return;
    try {
      final res = await _repo.api.updateDirectMessage(
        messageId: messageId,
        text: newText,
      );
      final serverMsg = res['message'] ?? res['data'] ?? res;
      if (serverMsg is Map<String, dynamic>) {
        _mergeEditedMessage(serverMsg);
      } else {
        _applyLocalEdit(messageId, newText);
      }
    } catch (_) {

    }
  }

  Future<void> deleteDirectMessage(String messageId) async {
    if (messageId.isEmpty) return;
    try {
      await _repo.api.deleteDirectMessage(messageId);
      messages.removeWhere(
        (m) =>
            _idOf(m) == messageId ||
            (m['localId'] ?? '').toString() == messageId,
      );
      messages.refresh();
      fetchChats();
    } catch (_) {
    }
  }

  Future<void> deleteDirectConversation(String otherId) async {
    if (otherId.isEmpty) return;
    try {
      await _repo.api.deleteDirectConversation(otherId);
      chats.removeWhere((c) =>
          (c['type']?.toString() == 'direct') &&
          (c['artisanId']?.toString() == otherId ||
              c['otherId']?.toString() == otherId));
      if (_activeArtisanId == otherId) {
        clearActive();
      }
      messages.removeWhere(
        (m) => (m['artisanId']?.toString() == otherId) && _isDirectMessage(m),
      );
      messages.refresh();
    } catch (_) {
    }
  }

  void clearActive() {
    _activeRequestId = null;
    _activeArtisanId = null;
    messages.clear();
  }

  void setActiveConversation(String id, {required bool direct}) {
    if (direct) {
      _activeArtisanId = id;
      _activeRequestId = null;
    } else {
      _activeRequestId = id;
      _activeArtisanId = null;
    }
  }

  void onSocketMessage(Map<String, dynamic> data) {
    final msg = _normalizeMessage(data);
    final requestId = msg['requestId']?.toString() ?? '';
    final isActive = _activeRequestId != null &&
        requestId.isNotEmpty &&
        _activeRequestId == requestId;
    _updateChatsFromMessage(msg, direct: false);
    if (!isActive) return;
    if (_isMine(msg)) return;
    _upsertMessage(msg);
    _maybeMarkAsRead(msg, direct: false);
  }

  void onSocketDirectMessage(Map<String, dynamic> data) {
    final msg = _normalizeMessage(data);
    _customerId ??= msg['customerId']?.toString();
    if (_customerId == null &&
        msg['sender']?.toString().toLowerCase() == 'customer') {
      _customerId = msg['senderId']?.toString();
    }
    final artisanId =
        msg['artisanId']?.toString() ??
        msg['otherId']?.toString() ??
        msg['senderId']?.toString() ??
        '';
    final mine = _isMine(msg);
    final isActive = _activeArtisanId != null &&
        _activeArtisanId!.isNotEmpty &&
        artisanId.isNotEmpty &&
        _activeArtisanId == artisanId;
    final selfId = _ensureCustomerId();
    if (selfId != null &&
        selfId.isNotEmpty &&
        artisanId.isNotEmpty &&
        _rtService.isStarted) {
      _rtService.subscribeToDirect(selfId, artisanId: artisanId);
    }

    _updateChatsFromMessage(msg, direct: true);

    if (mine) return;
    if (!isActive) return;
    _upsertMessage(msg);
    _maybeMarkAsRead(msg, direct: true);
  }

  void onSocketRead(String messageId) {
    if (messageId.isEmpty) return;
    _markLocalRead(messageId);
  }

  void onSocketBlock(dynamic data) {
    isBlocked.value = true;
  }

  void onSocketUnblock(dynamic data) {
    isBlocked.value = false;
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> raw) {
    final flat = Map<String, dynamic>.from(raw);
    if (flat['message'] is Map<String, dynamic>) {
      flat.addAll((flat['message'] as Map<String, dynamic>));
      flat.remove('message');
    }
    final msg = flat;
    final sender = (msg['sender'] ?? msg['role'] ?? '')
        .toString()
        .toLowerCase();
    final senderId = msg['senderId']?.toString() ?? msg['userId']?.toString();
    _customerId ??= msg['customerId']?.toString();
    if (_customerId == null && sender == 'customer' && senderId != null) {
      _customerId = senderId;
    }
    final mine =
        msg['isMine'] == true ||
        sender == 'customer' ||
        msg['fromCustomer'] == true ||
        (_customerId != null && senderId != null && senderId == _customerId);
    msg['isMine'] = mine;

    final isAdmin = _isAdminMessage(msg);
    if (isAdmin) {
      msg['isAdmin'] = true;
      msg['senderName'] ??= _adminDisplayName(msg);
      msg['peerName'] ??= _adminDisplayName(msg);
    }

    msg['createdAt'] ??= msg['updatedAt'];
    msg['type'] ??= _detectType(msg);
    msg['text'] ??= msg['message'];
    return msg;
  }

  String _detectType(Map<String, dynamic> msg) {
    final type = msg['type']?.toString();
    if (type != null && type.isNotEmpty) return type;
    if ((msg['video'] ?? '').toString().isNotEmpty) return 'video';
    if ((msg['audio'] ?? '').toString().isNotEmpty) return 'audio';
    if ((msg['image'] ?? '').toString().isNotEmpty) return 'image';
    if (msg['attachments'] is List && (msg['attachments'] as List).isNotEmpty) {
      return 'image';
    }
    return 'text';
  }

  Future<void> _sendAttachment({
    required String conversationId,
    required String dataUri,
    required String mime,
    String? localId,
    required bool direct,
  }) async {
    final type = mime.startsWith('video')
        ? 'video'
        : mime.startsWith('audio')
        ? 'audio'
        : 'image';
    final placeholder = _placeholderForType(type);
    await _sendMessage(
      conversationId: conversationId,
      type: type,
      text: placeholder,
      attachments: [dataUri],
      localId: localId,
      direct: direct,
    );
  }

  Future<void> _sendMessage({
    required String conversationId,
    required String type,
    required String text,
    List<dynamic>? attachments,
    String? localId,
    required bool direct,
  }) async {
    if (conversationId.isEmpty) return;
    final resolvedText = text.isEmpty ? _placeholderForType(type) : text;
    if (type == 'text' && resolvedText.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final outgoingLocalId = localId ?? _generateLocalId();

    final outgoing = {
      'localId': outgoingLocalId,
      'message': resolvedText,
      'text': resolvedText,
      'type': type,
      'createdAt': now,
      'state': 'sending',
      'isMine': true,
      'sender': 'customer',
      'role': 'customer',
      if (!direct) 'requestId': conversationId,
      if (direct) 'direct': true,
      if (direct) 'artisanId': conversationId,
      if (_customerId != null) 'customerId': _customerId,
      if (attachments != null) 'attachments': attachments,
    };
    if (direct && _customerId != null && _customerId!.isNotEmpty) {
      _rtService.subscribeToDirect(_customerId!, artisanId: conversationId);
    }
    if (localId != null) {
      final idx = messages.indexWhere(
        (m) => (m['localId'] ?? '').toString() == localId,
      );
      if (idx >= 0) {
        messages[idx] = {...messages[idx], ...outgoing};
      } else {
        messages.add(outgoing);
      }
      messages.refresh();
    } else {
      messages.add(outgoing);
      messages.refresh();
    }
    _updateChatsFromMessage(outgoing, direct: direct);

    _startSending();
    try {
      Map<String, dynamic> res;
      if (direct) {
        res = await _repo.api.sendDirectMessage(
          otherId: conversationId,
          message: resolvedText,
          type: type,
          attachments: attachments,
        );
      } else {
        res = await _repo.api.sendChatMessage(
          requestId: conversationId,
          type: type,
          message: resolvedText,
          attachments: attachments,
        );
      }
      final serverMsg = res['message'] ?? res['data'] ?? res;
      if (serverMsg is Map<String, dynamic>) {
        _mergeServerMessage(outgoingLocalId, serverMsg);
      } else {
        _updateMessageState(outgoingLocalId, state: 'sent');
      }
    } catch (_) {
      _updateMessageState(outgoingLocalId, state: 'failed');
    } finally {
      _endSending();
    }
  }

  void _mergeServerMessage(String localId, Map<String, dynamic> serverMsg) {
    final normalized = _normalizeMessage(serverMsg);
    final hasAttachment = (normalized['attachments'] is List &&
            (normalized['attachments'] as List).isNotEmpty) ||
        ((normalized['audio'] ?? normalized['video'] ?? normalized['image'] ?? '')
                .toString()
                .isNotEmpty);
    if (hasAttachment) {
      messages.removeWhere(
        (m) => (m['localId'] ?? '').toString() == localId,
      );
      messages.add({...normalized, 'localId': localId, 'state': 'sent'});
      messages.refresh();
      return;
    }
    final idx = messages.indexWhere(
      (m) => (m['localId'] ?? '').toString() == localId,
    );
    final merged = {...normalized, 'localId': localId, 'state': 'sent'};
    if (idx >= 0) {
      messages[idx] = merged;
    } else {
      messages.add(merged);
    }
    messages.refresh();
    _updateChatsFromMessage(
      normalized,
      direct: normalized['direct'] == true ||
          (normalized['requestId'] == null ||
              normalized['requestId'].toString().isEmpty),
    );
  }

  void _updateChatsFromMessage(Map<String, dynamic> msg,
      {required bool direct}) {
    final text = (msg['text'] ?? msg['message'] ?? '').toString();
    final createdAt =
        (msg['createdAt'] ?? msg['updatedAt'] ?? DateTime.now().toIso8601String())
            .toString();
    final mine = _isMine(msg);
    final requestId = msg['requestId']?.toString() ?? '';
    final artisanId = msg['artisanId']?.toString() ?? '';
    final cid = msg['customerId']?.toString() ?? _customerId ?? '';
    final isAdmin = _isAdminMessage(msg);
    final peerName = _peerNameForMessage(msg, direct: direct);

    final isActive = direct
        ? (_activeArtisanId != null &&
            _activeArtisanId!.isNotEmpty &&
            _activeArtisanId == artisanId)
        : (_activeRequestId != null &&
            _activeRequestId!.isNotEmpty &&
            _activeRequestId == requestId);

    int idx = -1;
    if (direct) {
      idx = chats.indexWhere(
        (c) =>
            (c['type']?.toString() == 'direct') &&
            (c['artisanId']?.toString() == artisanId) &&
            (c['customerId']?.toString() == cid),
      );
    } else {
      idx = chats.indexWhere(
        (c) =>
            (c['type']?.toString() == 'request') &&
            (c['requestId']?.toString() == requestId),
      );
    }

    if (idx >= 0) {
      final chat = Map<String, dynamic>.from(chats[idx]);
      final unread = (chat['unreadCount'] is num)
          ? (chat['unreadCount'] as num).toInt()
          : 0;
      final hasArtisan =
          (chat['artisanId'] ?? '').toString().isNotEmpty ||
          artisanId.isNotEmpty;
      chats[idx] = {
        ...chat,
        if (isAdmin && !hasArtisan) 'peerName': _adminDisplayName(msg),
        if (!isAdmin &&
            (chat['peerName'] ?? '').toString().isEmpty &&
            peerName.isNotEmpty)
          'peerName': peerName,
        if ((chat['artisanName'] ?? '').toString().isEmpty &&
            (msg['artisanName'] ?? '').toString().isNotEmpty)
          'artisanName': msg['artisanName'],
        if ((chat['customerName'] ?? '').toString().isEmpty &&
            (msg['customerName'] ?? '').toString().isNotEmpty)
          'customerName': msg['customerName'],
        'lastMessage': text,
        'lastMessageText': text,
        'lastMessageAt': createdAt,
        'unreadCount': mine || isActive ? 0 : (unread + 1),
        'adminNotice': isAdmin,
      };
    } else {
      final seed = {
        'type': direct ? 'direct' : 'request',
        'customerId': cid,
        'artisanId': artisanId,
        if (!direct) 'requestId': requestId,
        'peerName': isAdmin && artisanId.isEmpty
            ? _adminDisplayName(msg)
            : peerName,
        'customerName': msg['customerName'] ?? '',
        'artisanName': msg['artisanName'] ?? '',
        'lastMessage': text,
        'lastMessageText': text,
        'lastMessageAt': createdAt,
        'unreadCount': mine || isActive ? 0 : 1,
        'adminNotice': isAdmin,
      };
      final normalized = _normalizeChatItem(
        seed,
        type: (seed['type'] ?? '').toString(),
      );
      chats.insert(0, normalized);
      if ((normalized['peerName'] ?? '').toString().isEmpty ||
          (normalized['artisanId'] ?? '').toString().isEmpty ||
          (normalized['customerId'] ?? '').toString().isEmpty) {
        fetchChats();
      }
    }
    chats.refresh();
  }

  String _peerNameForMessage(Map<String, dynamic> msg, {required bool direct}) {
    if (_isAdminMessage(msg)) return _adminDisplayName(msg);
    final senderName = (msg['senderName'] ??
            msg['name'] ??
            msg['peerName'] ??
            msg['customerName'] ??
            msg['artisanName'] ??
            '')
        .toString();
    if (senderName.isNotEmpty) return senderName;
    if (direct) {
      return (msg['artisanId'] ?? '').toString().isNotEmpty
          ? 'Chat'
          : 'Chat';
    }
    return 'Chat';
  }

  bool _isAdminMessage(Map<String, dynamic> msg) {
    if (_truthy(msg['isAdmin']) ||
        _truthy(msg['fromAdmin']) ||
        _truthy(msg['admin']) ||
        _truthy(msg['system']) ||
        _truthy(msg['readOnly'])) {
      return true;
    }
    final candidates = [
      msg['senderType'],
      msg['from'],
      msg['sender'],
      msg['role'],
      msg['userType'],
      msg['source'],
      msg['actor'],
    ];
    for (final v in candidates) {
      final s = v?.toString().toLowerCase().trim();
      if (s == null || s.isEmpty) continue;
      if (s.contains('admin') ||
          s.contains('system') ||
          s.contains('support') ||
          s.contains('staff') ||
          s.contains('moderator')) {
        return true;
      }
    }
    final name =
        (msg['senderName'] ?? msg['name'] ?? msg['peerName'] ?? msg['title'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    if (name.contains('admin') ||
        name.contains('support') ||
        name.contains('system') ||
        name.contains('الدعم') ||
        name.contains('إدارة') ||
        name.contains('الادمن')) {
      return true;
    }
    return false;
  }

  String _adminDisplayName(Map<String, dynamic> msg) {
    final raw =
        (msg['senderName'] ?? msg['name'] ?? msg['title'] ?? '').toString();
    final lower = raw.toLowerCase();
    if (raw.isNotEmpty &&
        (lower.contains('admin') ||
            lower.contains('support') ||
            lower.contains('system') ||
            raw.contains('الدعم') ||
            raw.contains('الإدارة') ||
            raw.contains('ادمن'))) {
      return raw;
    }
    return 'الإدارة';
  }

  bool _truthy(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  Future<void> _uploadAndSendAttachment({
    required String conversationId,
    required String dataUri,
    required String mime,
    String? localId,
    required bool direct,
  }) async {
    final isVideo = mime.startsWith('video');
    final isAudio = mime.startsWith('audio');
    final typeForApi = isVideo
        ? 'video'
        : isAudio
            ? 'audio'
            : 'image';
    final placeholder = isVideo
        ? '[video]'
        : isAudio
            ? '[audio]'
            : '[image]';
    File file;
    try {
      file = await _resolveMediaFile(dataUri, mime);
    } catch (_) {
      _updateMessageState(localId ?? '', state: 'failed');
      return;
    }
    final pendingId = localId ??
        addPendingAttachment(
          type: typeForApi,
          placeholderAttachment: 'uploading://${file.path}',
          requestId: direct ? null : conversationId,
          customerId: direct ? conversationId : null,
          text: placeholder,
        );
    String uploadedUrl = '';
    try {
      final uploadFile =
          typeForApi == 'image' ? await ImageCompressor.compress(file) : file;
      final uploadEndpoint = ApiEndpoints.uploadChat;
      uploadedUrl = await _uploadService.uploadFile(
        file: uploadFile,
        endpoint: uploadEndpoint,
        onProgress: (p) => _updateUploadProgress(pendingId, p),
      );
      uploadedUrl = _sanitizeUploadUrl(uploadedUrl);
      _applyUploadedAttachment(
        localId: pendingId,
        url: uploadedUrl,
        type: typeForApi,
      );
      _updateUploadProgress(pendingId, 1.0);
      await _sendMessage(
        conversationId: conversationId,
        type: typeForApi,
        text: placeholder,
        attachments: [uploadedUrl],
        localId: pendingId,
        direct: direct,
      );
    } catch (_) {
      _updateMessageState(pendingId, state: 'failed');
      _clearUploadProgress(pendingId);
    }
  }

  void _updateUploadProgress(String localId, double progress) {
    final idx = messages.indexWhere(
      (m) => (m['localId'] ?? '').toString() == localId,
    );
    if (idx >= 0) {
      messages[idx] = {
        ...messages[idx],
        'uploadProgress': progress,
      };
      messages.refresh();
    }
  }

  void _clearUploadProgress(String localId) {
    final idx = messages.indexWhere(
      (m) => (m['localId'] ?? '').toString() == localId,
    );
    if (idx >= 0) {
      final map = Map<String, dynamic>.from(messages[idx]);
      map.remove('uploadProgress');
      messages[idx] = map;
      messages.refresh();
    }
  }

  void _applyUploadedAttachment({
    required String localId,
    required String url,
    required String type,
  }) {
    final idx = messages.indexWhere(
      (m) => (m['localId'] ?? '').toString() == localId,
    );
    if (idx >= 0) {
      final current = Map<String, dynamic>.from(messages[idx]);
      messages[idx] = {
        ...current,
        'attachments': [url],
        'type': type,
        'uploadProgress': 1.0,
      };
      messages.refresh();
    }
  }

  void _mergeEditedMessage(Map<String, dynamic> msg) {
    final normalized = _normalizeMessage(msg);
    final id = _idOf(normalized);
    final idx = messages.indexWhere(
      (m) =>
          _idOf(m) == id || (m['localId'] ?? '').toString() == id,
    );
    final merged = {
      if (idx >= 0) ...messages[idx],
      ...normalized,
      'state': 'sent',
    };
    if (idx >= 0) {
      messages[idx] = merged;
    } else {
      messages.add(merged);
    }
    messages.refresh();
    _updateChatsFromMessage(
      merged,
      direct: _isDirectMessage(merged),
    );
  }

  void _applyLocalEdit(String messageId, String text) {
    final idx = messages.indexWhere(
      (m) =>
          _idOf(m) == messageId ||
          (m['localId'] ?? '').toString() == messageId,
    );
    if (idx >= 0) {
      messages[idx] = {
        ...messages[idx],
        'text': text,
        'message': text,
        'state': 'sent',
      };
      messages.refresh();
      _updateChatsFromMessage(
        messages[idx],
        direct: _isDirectMessage(messages[idx]),
      );
    }
  }

  void _upsertMessage(Map<String, dynamic> msg) {
    final id = _idOf(msg);
    final localId = (msg['localId'] ?? '').toString();
    if (_hasAttachment(msg) && _isMine(msg)) {
      messages.removeWhere(
        (m) =>
            _hasAttachment(m) &&
            _isMine(m) &&
            ((m['state'] ?? '') == 'sending' || _idOf(m).isEmpty),
      );
    }
    int idx = -1;
    if (id.isNotEmpty) {
      idx = messages.indexWhere((m) => _idOf(m) == id);
    }
    if (idx == -1 && localId.isNotEmpty) {
      idx = messages.indexWhere(
        (m) => (m['localId'] ?? '').toString() == localId,
      );
    }

    if (idx >= 0) {
      messages[idx] = {...messages[idx], ...msg};
    } else {
      messages.add(msg);
    }
    messages.refresh();
    _updateChatsFromMessage(
      msg,
      direct: msg['direct'] == true ||
          (msg['requestId'] == null || msg['requestId'].toString().isEmpty),
    );
  }

  Future<void> _markUnreadAsRead({required bool direct}) async {
    for (final msg in messages) {
      final read =
          msg['read'] == true ||
          msg['state'] == 'read' ||
          msg['readBy']?['customer'] == true;
      if (!read && !_isMine(msg)) {
        final id = _idOf(msg);
        if (id.isEmpty) continue;
        if (_socketReady) {
          _rtService.markRead(id, direct: direct);
          _markLocalRead(id);
        } else {
          try {
            if (direct) {
              await _repo.api.markDirectRead(id);
            } else {
              await _repo.api.markChatRead(id);
            }
            _markLocalRead(id);
            _rtService.markRead(id, direct: direct);
          } catch (_) {
          }
        }
      }
    }
  }

  void _maybeMarkAsRead(Map<String, dynamic> msg, {required bool direct}) {
    if (_isMine(msg)) return;
    final read =
        msg['read'] == true ||
        msg['state'] == 'read' ||
        msg['readBy']?['customer'] == true;
    final id = _idOf(msg);
    if (!read && id.isNotEmpty) {
      if (_socketReady) {
        _rtService.markRead(id, direct: direct);
        _markLocalRead(id);
      } else {
        final future = direct
            ? _repo.api.markDirectRead(id)
            : _repo.api.markChatRead(id);
        future.catchError((_) {}).whenComplete(() {
          _markLocalRead(id);
          _rtService.markRead(id, direct: direct);
        });
      }
    }
  }

  bool _isMine(Map<String, dynamic> msg) => msg['isMine'] == true;
  bool _isDirectMessage(Map<String, dynamic> msg) =>
      msg['direct'] == true ||
      (msg['requestId'] == null || msg['requestId'].toString().isEmpty);

  String _idOf(Map<String, dynamic> msg) =>
      (msg['_id'] ?? msg['id'] ?? msg['messageId'] ?? '').toString();

  Future<File> _resolveMediaFile(String dataUriOrPath, String mime) async {
    if (dataUriOrPath.startsWith('data:')) {
      final parts = dataUriOrPath.split(',');
      if (parts.length < 2) {
        throw Exception('Invalid data URI');
      }
      final bytes = base64Decode(parts.sublist(1).join(','));
      final tmpDir = await getTemporaryDirectory();
      final ext = _extFromMime(mime);
      final file = File(
          '${tmpDir.path}/chat-${DateTime.now().microsecondsSinceEpoch}.$ext');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }

    final path = dataUriOrPath.startsWith('file://')
        ? Uri.parse(dataUriOrPath).path
        : dataUriOrPath;
    final file = File(path);
    if (await file.exists()) return file;
    throw Exception('File not found at $path');
  }

  String _extFromMime(String mime) {
    final lower = mime.toLowerCase();
    if (lower.contains('jpeg')) return 'jpg';
    if (lower.contains('png')) return 'png';
    if (lower.contains('webp')) return 'webp';
    if (lower.contains('mp4')) return 'mp4';
    if (lower.contains('mov')) return 'mov';
    if (lower.contains('aac')) return 'aac';
    if (lower.contains('m4a')) return 'm4a';
    if (lower.contains('mp3')) return 'mp3';
    if (lower.contains('ogg')) return 'ogg';
    return 'bin';
  }

  String _sanitizeUploadUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('/uploads/chat/')) return url;
    if (url.startsWith('uploads/chat/')) return '/$url';
    final parsed = Uri.tryParse(url);
    if (parsed != null && parsed.path.isNotEmpty) {
      if (parsed.path.startsWith('/uploads/chat/')) {
        return parsed.path;
      }
      if (parsed.path.startsWith('uploads/chat/')) {
        return '/${parsed.path}';
      }
    }
    return url;
  }

  String _placeholderForType(String type) {
    switch (type) {
      case 'audio':
        return '[audio]';
      case 'video':
        return '[video]';
      case 'image':
        return '[image]';
      default:
        return '';
    }
  }

  String _generateLocalId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final counter = _localCounter++ % 100000;
    return 'local-$ts-$counter';
  }

  bool _hasAttachment(Map<String, dynamic> msg) {
    final attachments =
        (msg['attachments'] is List) ? (msg['attachments'] as List) : const [];
    final mediaField = (msg['audio'] ?? msg['video'] ?? msg['image'] ?? '')
        .toString()
        .trim();
    return attachments.isNotEmpty || mediaField.isNotEmpty;
  }

  void _resubscribeActive() {
    if (_activeRequestId != null && _activeRequestId!.isNotEmpty) {
      _rtService.subscribeToRequest(_activeRequestId!);
      return;
    }
    final selfId = _ensureCustomerId();
    if ((selfId != null && selfId.isNotEmpty) &&
        (_activeArtisanId != null && _activeArtisanId!.isNotEmpty)) {
          _rtService.subscribeToDirect(selfId, artisanId: _activeArtisanId);
    }
  }

  void startDownload(String localId, String url) {
    _updateMessageState(localId, state: 'downloading', downloadProgress: 0.0);
  }

  void cancelMessage(String localId) {
    _updateMessageState(localId, state: 'cancelled', uploadProgress: null, downloadProgress: null);
  }

  void retryMessage(String localId) {
    _updateMessageState(localId, state: 'retrying', uploadProgress: 0.0);
  }

  void _updateMessageState(
    String localId, {
    String? state,
    double? uploadProgress,
    double? downloadProgress,
  }) {
    final idx = messages.indexWhere(
      (m) => (m['localId'] ?? '').toString() == localId,
    );
    if (idx == -1) return;
    final current = messages[idx];
    messages[idx] = {
      ...current,
      if (state != null) 'state': state,
      if (uploadProgress != null) 'uploadProgress': uploadProgress,
      if (downloadProgress != null) 'downloadProgress': downloadProgress,
    };
    messages.refresh();
  }

  Map<String, String> _authHeaders() {
    final token = _tokenStorage.accessToken ?? '';
    if (token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  void _setActiveConversation(String id, {required bool direct}) {
    if (direct) {
      _activeArtisanId = id;
      _activeRequestId = null;
      _ensureCustomerId();
    } else {
      _activeRequestId = id;
      _activeArtisanId = null;
    }
  }

  void _startSending() {
    _inFlightSends++;
    sending.value = true;
  }

  void _endSending() {
    _inFlightSends = _inFlightSends <= 0 ? 0 : _inFlightSends - 1;
    if (_inFlightSends == 0) {
      sending.value = false;
    }
  }

  void startChatsPolling({Duration interval = const Duration(seconds: 5)}) {
    _chatsPollTimer?.cancel();
    _chatsPollTimer = Timer.periodic(interval, (_) async {
      if (chats.isNotEmpty) {
        stopChatsPolling();
        return;
      }
      await fetchChats();
    });
  }

  void stopChatsPolling() {
    _chatsPollTimer?.cancel();
    _chatsPollTimer = null;
  }

  String? _ensureCustomerId() {
    if (_customerId != null && _customerId!.isNotEmpty) return _customerId;
    final profile = _auth?.profile.value;
    if (profile != null) {
      _customerId = profile.id;
      final raw = profile.raw ?? {};
      _customerId ??= (raw['_id'] ?? raw['id'] ?? raw['customerId'] ?? raw['userId'])
          ?.toString();
    }
    return _customerId;
  }

  void _markLocalRead(String messageId) {
    final idx = messages.indexWhere(
      (m) =>
          _idOf(m) == messageId || (m['localId'] ?? '').toString() == messageId,
    );
    if (idx >= 0) {
      messages[idx] = {
        ...messages[idx],
        'read': true,
        'state': 'read',
        'readBy': {
          ...((messages[idx]['readBy'] as Map<String, dynamic>?) ?? {}),
          'customer': true,
          'artisan': true,
        },
      };
      messages.refresh();
    }
  }

  String _chatKey(Map<String, dynamic> chat) {
    final type = chat['type']?.toString() ?? '';
    if (type == 'direct') {
      final artisanId = (chat['artisanId'] ?? chat['otherId'] ?? '').toString();
      final customerId = (chat['customerId'] ?? _customerId ?? '').toString();
      if (artisanId.isEmpty || customerId.isEmpty) return '';
      return 'direct:$customerId:$artisanId';
    }
    final requestId = (chat['requestId'] ?? chat['request'] ?? chat['_id'] ?? chat['id'] ?? '')
        .toString();
    if (requestId.isEmpty) return '';
    return 'request:$requestId';
  }

  bool _isActiveChat(Map<String, dynamic> chat) {
    final type = chat['type']?.toString();
    if (type == 'direct') {
      final artisanId = (chat['artisanId'] ?? chat['otherId'] ?? '').toString();
      return _activeArtisanId != null &&
          _activeArtisanId!.isNotEmpty &&
          artisanId.isNotEmpty &&
          _activeArtisanId == artisanId;
    }
    final requestId =
        (chat['requestId'] ?? chat['request'] ?? '').toString();
    return _activeRequestId != null &&
        _activeRequestId!.isNotEmpty &&
        requestId.isNotEmpty &&
        _activeRequestId == requestId;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}



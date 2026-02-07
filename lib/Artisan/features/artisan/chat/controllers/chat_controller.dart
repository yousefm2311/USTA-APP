import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:usta/Artisan/core/realtime/chat_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/network/auth_retry_interceptor.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';
import 'package:usta/Artisan/features/artisan/notifications/controllers/notifications_controller.dart';
import 'package:usta/Artisan/features/artisan/chat/services/media_upload_service.dart';

class ChatController extends GetxController {
  final ArtisanApi _api = ArtisanApi();
  final ChatRealtimeService _realtime = Get.find<ChatRealtimeService>(tag: 'artisan');

  RealtimeController? get _rt => Get.isRegistered<RealtimeController>(tag: 'artisan')
      ? Get.find<RealtimeController>(tag: 'artisan')
      : null;

  final AppPrefs _prefs = AppPrefs();
  final MediaUploadService _uploadService = MediaUploadService();
  late final Dio _downloadDio = _buildDownloadDio();

  final RxList<Map<String, dynamic>> chats = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> directInbox = <Map<String, dynamic>>[].obs;

  final RxBool loadingChats = false.obs;
  final RxBool loadingMessages = false.obs;
  final RxBool loadingDirect = false.obs;
  final RxBool sending = false.obs;
  final RxBool blocked = false.obs;

  final Map<String, CancelToken> _uploadTokens = {};
  final Map<String, CancelToken> _downloadTokens = {};
  final Random _rand = Random();

  // NOTE: We keep this flag because it is used elsewhere in your original logic,
  // but we removed all "microtask/timer retries" that caused spam.
  bool _retryChatsScheduled = false;

  final RxBool isChatScreenOpen = false.obs;
  void setChatScreenOpen(bool open) => isChatScreenOpen.value = open;

  String? activeRequestId;
  String? activeCustomerId;
  String artisanId = '';
  String artisanName = '';

  final Set<String> _localEchoIds = <String>{};
  StreamSubscription<bool>? _authSub;
  bool _bootstrapped = false;

  // ---- Chats fetch guard/throttle (NO timers) ----
  final bool _fetchingChats = false;
  DateTime? _lastChatsFetchAt;
  static const Duration _chatsFetchCooldown = Duration(seconds: 1);

  @override
  void onInit() {
    super.onInit();
    _setupAuthBootstrap();
    if (Get.isRegistered<RealtimeLifecycleService>()) {
      Get.find<RealtimeLifecycleService>().startAll();
    }
    _ensureRealtimeOnline();
  }

  String _messageId(Map<String, dynamic> message) =>
      (message['_id'] ?? message['id'] ?? message['messageId'] ?? '')
          .toString();

  String _chatKey(Map<String, dynamic> chat) {
    final type = chat['type']?.toString();
    if (type == 'direct') {
      final customerId = chat['customerId']?.toString() ??
          chat['otherId']?.toString() ??
          '';
      return 'direct:$customerId';
    }
    final requestId = (chat['requestId'] ?? chat['_id'] ?? chat['id'] ?? '')
        .toString();
    return 'request:$requestId';
  }

  String _firstNonEmpty(Iterable<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString();
      if (s.trim().isNotEmpty) return s.trim();
    }
    return '';
  }

  String _adminLabel() {
    final code = Get.locale?.languageCode;
    return code == 'ar' ? 'الإدارة' : 'Admin';
  }

  bool _sameText(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  List<Map<String, dynamic>> _mergeUnreadCounts(
    List<Map<String, dynamic>> incoming,
  ) {
    if (chats.isEmpty) return incoming;
    final existingByKey = <String, Map<String, dynamic>>{};
    for (final c in chats) {
      existingByKey[_chatKey(c)] = c;
    }
    return incoming.map((item) {
      final key = _chatKey(item);
      final prev = existingByKey[key];
      if (prev == null) return item;

      final incomingUnread = item['unreadCount'];
      if (incomingUnread is! num) {
        final prevUnread = prev['unreadCount'];
        if (prevUnread is num) {
          item = {...item, 'unreadCount': prevUnread};
        }
      }
      if (item['isAdmin'] == null && prev['isAdmin'] == true) {
        item = {
          ...item,
          'isAdmin': true,
          if (prev['lastSender'] != null) 'lastSender': prev['lastSender'],
        };
      }
      return item;
    }).toList();
  }

  String _stringifyId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      return _stringifyId(
        map['_id'] ?? map['id'] ?? map['requestId'] ?? map['request_id'],
      );
    }
    return '';
  }

  String _extractRequestId(
    Map<String, dynamic> payload,
    Map<String, dynamic> msg,
  ) {
    final id = _firstNonEmpty([
      _stringifyId(payload['requestId']),
      _stringifyId(payload['request_id']),
      _stringifyId(msg['requestId']),
      _stringifyId(msg['request_id']),
      _stringifyId(payload['request']),
      _stringifyId(msg['request']),
      _stringifyId(payload['_id']),
      _stringifyId(msg['_id']),
    ]);
    if (id.startsWith('Instance of')) return '';
    return id;
  }

  String _extractCustomerName(
    Map<String, dynamic> payload,
    Map<String, dynamic> msg,
  ) {
    return _firstNonEmpty([
      msg['customerName'],
      (msg['customer'] is Map) ? (msg['customer'] as Map)['name'] : null,
      payload['customerName'],
      (payload['customer'] is Map)
          ? (payload['customer'] as Map)['name']
          : null,
      (payload['request'] is Map &&
              (payload['request'] as Map)['customer'] is Map)
          ? ((payload['request'] as Map)['customer'] as Map)['name']
          : null,
      (payload['request'] is Map &&
              (payload['request'] as Map)['customerId'] is Map)
          ? ((payload['request'] as Map)['customerId'] as Map)['name']
          : null,
      (msg['request'] is Map && (msg['request'] as Map)['customer'] is Map)
          ? ((msg['request'] as Map)['customer'] as Map)['name']
          : null,
      (msg['request'] is Map && (msg['request'] as Map)['customerId'] is Map)
          ? ((msg['request'] as Map)['customerId'] as Map)['name']
          : null,
    ]);
  }

  bool _isSystemInboxPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> msg,
  ) {
    final sender = _firstNonEmpty([
      msg['sender'],
      msg['role'],
      msg['from'],
      payload['sender'],
      payload['role'],
      payload['from'],
      payload['source'],
    ]).toLowerCase();

    const systemRoles = {
      'admin',
      'system',
      'support',
      'operator',
      'moderator',
    };

    if (systemRoles.contains(sender)) return true;

    final kind = _firstNonEmpty([
      payload['kind'],
      payload['category'],
      msg['kind'],
      msg['category'],
    ]).toLowerCase();

    if (kind == 'notification' || kind == 'system') return true;

    final hasTitleBody =
        (_firstNonEmpty([payload['title'], msg['title']]).isNotEmpty) &&
        (_firstNonEmpty([payload['body'], msg['body']]).isNotEmpty);

    if (hasTitleBody) return true;

    return false;
  }

  String _localOrMessageId(Map<String, dynamic> message) {
    final local = message['localId']?.toString();
    if (local != null && local.isNotEmpty) return local;
    return _messageId(message);
  }

  String _generateLocalId() {
    return '${DateTime.now().microsecondsSinceEpoch}-${_rand.nextInt(1 << 32)}';
  }

  Future<File> _resolveMediaFile(String dataUriOrPath, String mime) async {
    final lower = dataUriOrPath.toLowerCase();
    if (lower.startsWith('data:')) {
      final parts = dataUriOrPath.split(',');
      if (parts.length < 2) {
        throw ApiException('Invalid data uri');
      }
      final base64Part = parts.sublist(1).join(',');
      final bytes = base64Decode(base64Part);
      final tempDir = await getTemporaryDirectory();
      final ext = _extensionForMime(mime);
      final file = File(
        '${tempDir.path}/chat_media_${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    }
    final path = lower.startsWith('file://')
        ? dataUriOrPath.substring(7)
        : dataUriOrPath;
    final file = File(path);
    if (await file.exists()) return file;
    throw ApiException('File not found for upload');
  }

  String _extensionForMime(String mime) {
    final lower = mime.toLowerCase();
    if (lower.contains('png')) return 'png';
    if (lower.contains('gif')) return 'gif';
    if (lower.contains('webp')) return 'webp';
    if (lower.contains('mp4')) return 'mp4';
    if (lower.contains('mov')) return 'mov';
    if (lower.contains('aac') || lower.contains('m4a')) return 'm4a';
    if (lower.contains('ogg')) return 'ogg';
    if (lower.contains('wav')) return 'wav';
    if (lower.contains('mp3')) return 'mp3';
    return 'jpg';
  }

  Future<File> _maybeCompressImage(File file, String mime) async {
    try {
      final format = mime.toLowerCase().contains('png')
          ? CompressFormat.png
          : CompressFormat.jpeg;
      final tempDir = await getTemporaryDirectory();
      final target =
          '${tempDir.path}/cmp_${DateTime.now().millisecondsSinceEpoch}.${_extensionForMime(mime)}';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: 76,
        format: format,
        keepExif: false,
      );
      if (compressed != null) {
        final outFile = File(compressed.path);
        if (await outFile.exists()) {
          return outFile;
        }
      }
    } catch (_) {}
    return file;
  }

  void _updateLocalMessage(String localId, Map<String, dynamic> data) {
    final idx = messages.indexWhere((m) {
      final lid = (m['localId']?.toString() ?? '');
      final mid = _messageId(m);
      return lid == localId || mid == localId;
    });
    if (idx >= 0) {
      messages[idx] = {...messages[idx], ...data};
      messages.refresh();
    }
  }

  void _cancelTokens(String localId) {
    _uploadTokens.remove(localId)?.cancel('cancelled');
    _downloadTokens.remove(localId)?.cancel('cancelled');
  }

  String _resolveRemoteUrl(String url) {
    if (url.startsWith('http')) return url;
    final base = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;
    final baseNoApi = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    if (url.startsWith('/uploads')) return '$baseNoApi$url';
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  void _ensureRealtimeOnline() {
    if (!_realtime.isStarted) {
      _realtime.start();
    }
    _rt?.connectIfNeeded();
  }

  Map<String, dynamic> _withMessageDefaults(Map<String, dynamic> map) {
    return {
      ...map,
      'state': map['state'] ?? 'sent',
      'uploadProgress': map['uploadProgress'] ?? 1.0,
      'downloadProgress': map['downloadProgress'] ?? 0.0,
    };
  }

  Dio _buildDownloadDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    if (Get.isRegistered<AuthService>()) {
      dio.interceptors.add(
        AuthRetryInterceptor(dio: dio, authService: Get.find<AuthService>()),
      );
    }
    return dio;
  }

  String addPendingAttachment({
    required String type,
    required String placeholderAttachment,
    String? requestId,
    String? customerId,
    String? text,
  }) {
    final localId = _generateLocalId();
    final isRemote = placeholderAttachment.startsWith('http');
    final map = {
      'localId': localId,
      if (requestId != null) 'requestId': requestId,
      if (customerId != null) 'customerId': customerId,
      'text': text ?? '[$type]',
      'type': type,
      'attachments': isRemote ? [placeholderAttachment] : <String>[],
      'localFilePath': isRemote ? null : placeholderAttachment,
      'uploadProgress': 0.0,
      'downloadProgress': 0.0,
      'sender': 'artisan',
      'isMine': true,
      'state': 'sending',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _addOrUpdateMessage(map);
    if (customerId != null) {
      _upsertChatPreview('', {...map, 'customerId': customerId});
    } else if (requestId != null) {
      _upsertChatPreview(requestId, map);
    }
    return localId;
  }

  bool _isMine(Map<String, dynamic> m) {
    final sender = (m['sender'] ?? m['role'])?.toString().toLowerCase();
    final isMineFlag = m['isMine'] == true;
    final explicitArtisan =
        sender == 'artisan' || sender == 'me' || sender == 'self';
    final idMatches =
        ((m['artisanId'] ?? m['senderId'] ?? '').toString() == artisanId) &&
        artisanId.isNotEmpty;
    final inferredMine =
        idMatches && (explicitArtisan || (sender == null || sender.isEmpty));
    return isMineFlag || explicitArtisan || inferredMine;
  }

  String _typeOf(Map<String, dynamic> m) =>
      (m['type'] ?? '').toString().toLowerCase();

  String _attachmentKey(String raw) {
    var val = raw;
    if (val.isEmpty) return '';
    if (val.startsWith('data:')) {
      return val.substring(0, val.length > 32 ? 32 : val.length);
    }
    final noQuery = val.split('?').first;
    final lastSlash = noQuery.split('/').where((p) => p.isNotEmpty).toList();
    final last = lastSlash.isNotEmpty ? lastSlash.last : noQuery;
    return last.isNotEmpty ? last : val;
  }

  Set<String> _collectAttachments(Map<String, dynamic> m) {
    final result = <String>{};
    if (m['attachments'] is List) {
      result.addAll(
        (m['attachments'] as List)
            .map((e) => _attachmentKey(e.toString()))
            .where((e) => e.isNotEmpty),
      );
    }
    if (m['image'] != null) result.add(_attachmentKey(m['image'].toString()));
    if (m['video'] != null) result.add(_attachmentKey(m['video'].toString()));
    return result;
  }

  void _registerLocalEcho(String localId) {
    if (localId.isEmpty) return;
    _localEchoIds.add(localId);
    Future.delayed(const Duration(seconds: 8), () {
      _localEchoIds.remove(localId);
    });
  }

  bool _consumeLocalEcho(String localId) {
    if (localId.isEmpty) return false;
    return _localEchoIds.remove(localId);
  }

  void _addOrUpdateMessage(Map<String, dynamic> incoming) {
    final normalized = {...incoming};
    normalized['state'] ??= 'sent';
    if (normalized['uploadProgress'] == null && normalized['state'] == 'sent') {
      normalized['uploadProgress'] = 1.0;
    }
    normalized['downloadProgress'] ??= 0.0;

    final localId = normalized['localId']?.toString();
    final serverId = _messageId(normalized);
    final incomingAttachments = _collectAttachments(normalized);

    final idx = messages.indexWhere((m) {
      final mid = _messageId(m);
      final lid = m['localId']?.toString();
      if (localId != null && localId.isNotEmpty && lid == localId) return true;
      if (serverId.isNotEmpty && mid == serverId) return true;
      return false;
    });

    if (idx >= 0) {
      messages[idx] = {...messages[idx], ...normalized};
      messages.refresh();
      return;
    }

    final isAttachment = incomingAttachments.isNotEmpty;
    if (isAttachment) {
      final reqId = normalized['requestId']?.toString();
      final custId = normalized['customerId']?.toString();
      final incomingType = _typeOf(normalized);
      final placeholder = (normalized['text'] ?? normalized['message'] ?? '')
          .toString();

      bool typeMatch(Map<String, dynamic> m) {
        final mt = _typeOf(m);
        if (incomingType.isEmpty) return mt.isEmpty;
        if (mt.isEmpty) return false;
        return mt == incomingType;
      }

      final overlapIdx = messages.lastIndexWhere((m) {
        final mine = _isMine(m);
        final sameReq = reqId != null
            ? (m['requestId']?.toString() == reqId)
            : true;
        final sameCust = custId != null
            ? (m['customerId']?.toString() == custId)
            : true;
        final sameType = typeMatch(m);
        if (!(mine && sameReq && sameCust && sameType)) return false;
        final existingAttachments = _collectAttachments(m);
        if (incomingAttachments.isEmpty || existingAttachments.isEmpty) {
          return false;
        }
        return incomingAttachments.any(existingAttachments.contains);
      });

      if (overlapIdx >= 0) {
        messages[overlapIdx] = {...messages[overlapIdx], ...normalized};
        messages.refresh();
        return;
      }

      final pendingIdx = messages.lastIndexWhere((m) {
        if (!_isMine(m)) return false;
        final sameReq = reqId != null
            ? (m['requestId']?.toString() == reqId)
            : true;
        final sameCust = custId != null
            ? (m['customerId']?.toString() == custId)
            : true;
        final sameType = typeMatch(m);
        final state = (m['state'] ?? '').toString();
        final pending = state == 'sending' || state == 'sent';
        if (!(sameReq && sameCust && pending)) return false;

        final existingAttachments = _collectAttachments(m);
        final overlap =
            incomingAttachments.isNotEmpty &&
            existingAttachments.isNotEmpty &&
            incomingAttachments.any(existingAttachments.contains);
        final textMatch =
            placeholder.isNotEmpty &&
            ((m['text'] ?? m['message'] ?? '').toString() == placeholder);

        return (sameType && (overlap || textMatch)) || (overlap || textMatch);
      });

      if (pendingIdx >= 0) {
        messages[pendingIdx] = {...messages[pendingIdx], ...normalized};
        messages.refresh();
        return;
      }
    }

    final sender = (normalized['sender'] ?? normalized['role'])?.toString();
    final text = normalized['text'] ?? normalized['message'];
    final incomingType = _typeOf(normalized);
    final reqId = normalized['requestId']?.toString();
    final custId = normalized['customerId']?.toString();

    final firstAttachment =
        (normalized['attachments'] is List &&
            (normalized['attachments'] as List).isNotEmpty)
        ? (normalized['attachments'] as List).first.toString()
        : null;

    final fallbackIdx = messages.lastIndexWhere((m) {
      final minePair = _isMine(m) || _isMine(normalized);
      final sameSender = minePair
          ? true
          : (m['sender'] ?? m['role'])?.toString() == sender;
      final sameText = (m['text'] ?? m['message']) == text;
      final sameReq = reqId != null
          ? (m['requestId']?.toString() == reqId)
          : true;
      final sameCust = custId != null
          ? (m['customerId']?.toString() == custId)
          : true;
      final sameType = incomingType.isEmpty ? true : _typeOf(m) == incomingType;

      final sameAttachment = firstAttachment == null
          ? true
          : ((m['attachments'] is List &&
                    (m['attachments'] as List).isNotEmpty &&
                    (m['attachments'] as List).first.toString() ==
                        firstAttachment) ||
                m['image'] == firstAttachment ||
                m['video'] == firstAttachment);

      return sameSender &&
          sameText &&
          sameReq &&
          sameCust &&
          sameType &&
          sameAttachment &&
          (m['state'] == 'sending');
    });

    if (fallbackIdx >= 0) {
      messages[fallbackIdx] = {...messages[fallbackIdx], ...normalized};
      messages.refresh();
      return;
    }

    final dupIdx = messages.lastIndexWhere((m) {
      final sameSender = (m['sender'] ?? m['role'])?.toString() == sender;
      final sameReq = reqId != null
          ? (m['requestId']?.toString() == reqId)
          : true;
      final sameCust = custId != null
          ? (m['customerId']?.toString() == custId)
          : true;
      if (!sameSender || !sameReq || !sameCust) return false;

      final existingAttachments = <String>{
        if (m['attachments'] is List)
          ...((m['attachments'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)),
        if (m['image'] != null) m['image'].toString(),
        if (m['video'] != null) m['video'].toString(),
      };

      return existingAttachments.isNotEmpty &&
          incomingAttachments.isNotEmpty &&
          incomingAttachments.any(existingAttachments.contains);
    });

    if (dupIdx >= 0) {
      messages[dupIdx] = {...messages[dupIdx], ...normalized};
      messages.refresh();
      return;
    }

    messages.add(normalized);
    messages.refresh();
  }

  void _removeMessageById(String id) {
    if (id.isEmpty) return;
    messages.removeWhere((m) {
      final mid = _messageId(m);
      final lid = m['localId']?.toString();
      return mid == id || lid == id;
    });
    messages.refresh();
  }

  void setActiveRequest(String requestId) {
    activeRequestId = requestId;
    _realtime.subscribeToRequest(requestId);
  }

  void clearActive() {
    activeRequestId = null;
    activeCustomerId = null;
    messages.clear();
  }

  Future<void> fetchChats({bool force = false}) async {
    _ensureRealtimeOnline();

    if (!_isAuthenticated) {
      loadingChats.value = false;
      _retryChatsScheduled = false;
      return;
    }

    if (loadingChats.value && !force) return;

    loadingChats.value = true;
    try {
      final response = await _api.chats();
      final data = ApiClient.instance.unwrapData(response);
      final list = _asList(data);

      list.sort((a, b) {
        final at =
            DateTime.tryParse(
              (a['updatedAt'] ?? a['lastMessageAt'] ?? '').toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bt =
            DateTime.tryParse(
              (b['updatedAt'] ?? b['lastMessageAt'] ?? '').toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

      final merged = _mergeUnreadCounts(list);
      chats.assignAll(merged);
      _subscribeForChats(chats);
    } catch (_) {
      _showSnack(AppStrings.chatLoadFailed.tr);
    } finally {
      loadingChats.value = false;
    }
  }

  Future<void> fetchDirectMessages(String customerId) async {
    _ensureRealtimeOnline();
    if (!_isAuthenticated) {
      loadingMessages.value = false;
      return;
    }
    activeRequestId = null;
    activeCustomerId = customerId;
    _realtime.subscribeToDirect(customerId, artisanId: artisanId);
    loadingMessages.value = true;
    try {
      final response = await _api.directMessages(customerId);
      final data = ApiClient.instance.unwrapData(response);
      messages.assignAll(
        _dedupeById(_asList(data)).map(_withMessageDefaults).toList(),
      );
      _markAllAsRead(messages);
    } catch (e) {
      _handleError(e, AppStrings.messagesLoadFailed.tr);
    } finally {
      loadingMessages.value = false;
    }
  }

  Future<void> fetchMessages(String requestId) async {
    _ensureRealtimeOnline();
    if (!_isAuthenticated) {
      loadingMessages.value = false;
      return;
    }
    activeRequestId = requestId;
    _realtime.subscribeToRequest(requestId);
    loadingMessages.value = true;
    try {
      await _api.openChat(requestId);
      final response = await _api.messages(requestId);
      final data = ApiClient.instance.unwrapData(response);
      messages.assignAll(
        _dedupeById(_asList(data)).map(_withMessageDefaults).toList(),
      );
      _markAllAsRead(messages);
    } catch (e) {
      _handleError(e, AppStrings.messagesLoadFailed.tr);
    } finally {
      loadingMessages.value = false;
    }
  }

  Future<void> fetchDirectInbox() async {
    _ensureRealtimeOnline();
    if (!_isAuthenticated) {
      loadingDirect.value = false;
      return;
    }
    loadingDirect.value = true;
    try {
      final response = await _api.directInbox();
      final data = ApiClient.instance.unwrapData(response);
      directInbox.assignAll(_asList(data));
    } catch (_) {
      _showSnack(AppStrings.inboxLoadFailed.tr);
    } finally {
      loadingDirect.value = false;
    }
  }

  Future<void> sendTextMessage(
    String requestId,
    String text, {
    String? localId,
  }) async {
    if (!_isAuthenticated) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty || blocked.value) return;
    sending.value = true;
    final id = localId ?? _generateLocalId();
    final placeholder = {
      'localId': id,
      'requestId': requestId,
      'text': trimmed,
      'type': 'text',
      'sender': 'artisan',
      'isMine': true,
      'state': 'sending',
      'uploadProgress': 1.0,
      'downloadProgress': 1.0,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _addOrUpdateMessage(placeholder);
    _upsertChatPreview(requestId, placeholder);
    try {
      final resp = await _api.sendMessage(
        requestId: requestId,
        type: 'text',
        text: trimmed,
      );
      final data = ApiClient.instance.unwrapData(resp);
      Map<String, dynamic> merged = {...placeholder};
      if (data is Map<String, dynamic>) {
        final serverMsg = data['message'] is Map<String, dynamic>
            ? (data['message'] as Map<String, dynamic>)
            : data;
        merged = {...merged, ...serverMsg};
      }
      merged['state'] = 'sent';
      merged['localId'] = id;
      _addOrUpdateMessage(merged);
      _registerLocalEcho(id);
    } catch (e) {
      final error = e is ApiException
          ? e.message
          : AppStrings.sendMessageFailed.tr;
      _addOrUpdateMessage({...placeholder, 'state': 'failed', 'error': error});
    } finally {
      sending.value = false;
    }
  }

  Future<void> editRequestMessage(String messageId, String text) async {
    if (messageId.isEmpty) return;
    try {
      final resp = await _api.editMessage(messageId, text);
      final data = ApiClient.instance.unwrapData(resp);
      if (data is Map<String, dynamic>) {
        final msg = data['message'] is Map<String, dynamic>
            ? (data['message'] as Map<String, dynamic>)
            : data;
        _addOrUpdateMessage(msg);
        _upsertChatPreview(activeRequestId ?? '', msg);
      }
    } catch (e) {
      _handleError(e, AppStrings.editMessageFailed.tr);
    }
  }

  Future<void> deleteRequestMessage(String messageId) async {
    if (messageId.isEmpty) return;
    try {
      await _api.deleteMessage(messageId);
      _removeMessageById(messageId);
      // If you really need a full sync after delete, keep it but throttled:
      fetchChats();
    } catch (e) {
      _handleError(e, AppStrings.deleteMessageFailed.tr);
    }
  }

  Future<void> clearRequestChat(String requestId) async {
    if (requestId.isEmpty) return;
    try {
      await _api.clearRequestChat(requestId);
      _removeRequestChatLocal(requestId);
    } catch (e) {
      if (e is ApiException && (e.statusCode == 404 || e.statusCode == 400)) {
        _removeRequestChatLocal(requestId);
        return;
      }
      _handleError(e, AppStrings.clearChatFailed.tr);
    }
  }

  void _removeRequestChatLocal(String requestId) {
    if (activeRequestId == requestId) {
      messages.clear();
      messages.refresh();
    }
    chats.removeWhere(
      (c) => c['type'] != 'direct' && c['requestId']?.toString() == requestId,
    );
    chats.refresh();
  }

  Future<void> sendRequestAttachment(
    String requestId, {
    required String dataUri,
    required String mime,
    String? localId,
  }) async {
    await _sendMedia(
      requestId: requestId,
      customerId: null,
      pathOrData: dataUri,
      mime: mime,
      localId: localId,
    );
  }

  Future<void> sendDirectText(
    String customerId,
    String text, {
    String? localId,
  }) async {
    if (!_isAuthenticated) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty || blocked.value) return;
    sending.value = true;
    final id = localId ?? _generateLocalId();
    final placeholder = {
      'localId': id,
      'customerId': customerId,
      'artisanId': artisanId,
      'text': trimmed,
      'type': 'text',
      'sender': 'artisan',
      'isMine': true,
      'state': 'sending',
      'uploadProgress': 1.0,
      'downloadProgress': 1.0,
      'createdAt': DateTime.now().toIso8601String(),
    };
    _addOrUpdateMessage(placeholder);
    _upsertChatPreview('', {...placeholder, 'customerId': customerId});
    try {
      final resp = await _api.sendDirectMessage(
        customerId: customerId,
        message: trimmed,
      );
      final data = ApiClient.instance.unwrapData(resp);
      Map<String, dynamic> merged = {...placeholder};
      if (data is Map<String, dynamic>) {
        final serverMsg = data['message'] is Map<String, dynamic>
            ? (data['message'] as Map<String, dynamic>)
            : data;
        merged = {...merged, ...serverMsg};
      }
      merged['state'] = 'sent';
      merged['localId'] = id;
      _addOrUpdateMessage(merged);
      _registerLocalEcho(id);
    } catch (e) {
      final error = e is ApiException
          ? e.message
          : AppStrings.sendMessageFailed.tr;
      _addOrUpdateMessage({...placeholder, 'state': 'failed', 'error': error});
    } finally {
      sending.value = false;
    }
  }

  Future<void> editDirectMessage(String messageId, String text) async {
    if (messageId.isEmpty) return;
    try {
      final resp = await _api.editDirectMessage(messageId, text);
      final data = ApiClient.instance.unwrapData(resp);
      if (data is Map<String, dynamic>) {
        final msg = data['message'] is Map<String, dynamic>
            ? (data['message'] as Map<String, dynamic>)
            : data;
        _addOrUpdateMessage(msg);
        _upsertChatPreview('', msg);
      }
    } catch (e) {
      _handleError(e, AppStrings.editMessageFailed.tr);
    }
  }

  Future<void> deleteDirectMessage(String messageId) async {
    if (messageId.isEmpty) return;
    try {
      await _api.deleteDirectMessage(messageId);
      _removeMessageById(messageId);
      fetchChats();
    } catch (e) {
      _handleError(e, AppStrings.deleteMessageFailed.tr);
    }
  }

  Future<void> clearDirectChat(String customerId) async {
    if (customerId.isEmpty) return;
    try {
      await _api.clearDirectChat(customerId);
      if (activeCustomerId == customerId) {
        messages.clear();
        messages.refresh();
      }
      chats.removeWhere(
        (c) =>
            c['type'] == 'direct' && c['customerId']?.toString() == customerId,
      );
      chats.refresh();
    } catch (e) {
      _handleError(e, AppStrings.clearChatFailed.tr);
    }
  }

  Future<void> sendDirectAttachment(
    String customerId, {
    required String dataUri,
    required String mime,
    String? localId,
  }) async {
    await _sendMedia(
      requestId: null,
      customerId: customerId,
      pathOrData: dataUri,
      mime: mime,
      localId: localId,
    );
  }

  Future<void> _sendMedia({
    required String? requestId,
    required String? customerId,
    required String pathOrData,
    required String mime,
    String? localId,
  }) async {
    if (!_isAuthenticated) return;
    if (blocked.value) return;
    sending.value = true;

    final lowerMime = mime.toLowerCase();
    final type = lowerMime.startsWith('audio/')
        ? 'audio'
        : lowerMime.startsWith('image/')
        ? 'image'
        : 'video';
    final placeholderText = '[$type]';
    final id = localId ?? _generateLocalId();

    final base = _buildMediaPlaceholder(
      localId: id,
      requestId: requestId,
      customerId: customerId,
      type: type,
      text: placeholderText,
      mime: mime,
      localFilePath: pathOrData,
    );

    _addOrUpdateMessage(base);
    if (customerId != null) {
      _upsertChatPreview('', {...base, 'customerId': customerId});
    } else if (requestId != null) {
      _upsertChatPreview(requestId, base);
    }

    try {
      File mediaFile = await _resolveMediaFile(pathOrData, mime);
      if (lowerMime.startsWith('image/')) {
        mediaFile = await _maybeCompressImage(mediaFile, mime);
      }
      _updateLocalMessage(id, {'localFilePath': mediaFile.path});

      final token = CancelToken();
      _uploadTokens[id] = token;
      final url = await _uploadService.uploadChatMedia(
        file: mediaFile,
        mime: mime,
        cancelToken: token,
        onSendProgress: (sent, total) {
          final progress = total > 0 ? sent / total : 0;
          _updateLocalMessage(id, {
            'uploadProgress': progress,
            'state': 'sending',
          });
        },
      );
      _uploadTokens.remove(id);

      final resp = customerId != null
          ? await _api.sendDirectMessage(
              customerId: customerId,
              message: placeholderText,
              attachments: [url],
            )
          : await _api.sendMessage(
              requestId: requestId!,
              type: type,
              text: placeholderText,
              attachments: [url],
            );

      final data = ApiClient.instance.unwrapData(resp);
      Map<String, dynamic> merged = {
        ...base,
        'attachments': [url],
        'localFilePath': mediaFile.path,
        'state': 'sent',
        'uploadProgress': 1.0,
        'downloadProgress': 1.0,
        'localId': id,
      };
      if (data is Map<String, dynamic>) {
        final serverMsg = data['message'] is Map<String, dynamic>
            ? (data['message'] as Map<String, dynamic>)
            : data;
        merged = {...merged, ...serverMsg};
      }
      _addOrUpdateMessage(merged);
      _registerLocalEcho(id);
    } on DioException catch (e) {
      final cancelled = CancelToken.isCancel(e);
      _uploadTokens.remove(id);
      _addOrUpdateMessage({
        ...base,
        'state': cancelled ? 'cancelled' : 'failed',
        'error': e.message,
      });
    } catch (e) {
      final error = e is ApiException
          ? e.message
          : AppStrings.sendMediaFailed.tr;
      _uploadTokens.remove(id);
      _addOrUpdateMessage({...base, 'state': 'failed', 'error': error});
    } finally {
      sending.value = false;
    }
  }

  Map<String, dynamic> _buildMediaPlaceholder({
    required String localId,
    required String? requestId,
    required String? customerId,
    required String type,
    required String text,
    required String mime,
    required String? localFilePath,
  }) {
    return {
      'localId': localId,
      if (requestId != null) 'requestId': requestId,
      if (customerId != null) 'customerId': customerId,
      'artisanId': artisanId,
      'text': text,
      'type': type,
      'mime': mime,
      'attachments': <String>[],
      'localFilePath': localFilePath,
      'uploadProgress': 0.0,
      'downloadProgress': 0.0,
      'sender': 'artisan',
      'isMine': true,
      'state': 'sending',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> startDownload(String localId, String url) async {
    if (url.isEmpty) return;
    final resolved = _resolveRemoteUrl(url);
    final token = CancelToken();
    _downloadTokens[localId] = token;
    _updateLocalMessage(localId, {
      'state': 'downloading',
      'downloadProgress': 0.0,
    });
    try {
      final dir = await getTemporaryDirectory();
      final ext = resolved.split('.').last.split('?').first;
      final path =
          '${dir.path}/chat_${localId}_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'bin' : ext}';
      if (Get.isRegistered<AuthService>()) {
        final access = Get.find<AuthService>().accessToken;
        if (access != null && access.isNotEmpty) {
          _downloadDio.options.headers['Authorization'] = 'Bearer $access';
        }
      }
      await _downloadDio.download(
        resolved,
        path,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0;
          _updateLocalMessage(localId, {
            'downloadProgress': progress,
            'state': 'downloading',
          });
        },
      );
      _downloadTokens.remove(localId);
      _updateLocalMessage(localId, {
        'localFilePath': path,
        'downloadProgress': 1.0,
        'state': 'downloaded',
      });
    } on DioException catch (e) {
      final cancelled = CancelToken.isCancel(e);
      _downloadTokens.remove(localId);
      _updateLocalMessage(localId, {
        'state': cancelled ? 'cancelled' : 'failed',
        'error': e.message,
      });
    } catch (e) {
      _downloadTokens.remove(localId);
      final error = e is ApiException
          ? e.message
          : AppStrings.downloadFailed.tr;
      _updateLocalMessage(localId, {'state': 'failed', 'error': error});
    }
  }

  void cancelMessage(String localId) {
    _cancelTokens(localId);
    _updateLocalMessage(localId, {'state': 'cancelled'});
  }

  Future<void> retryMessage(String localId) async {
    final idx = messages.indexWhere(
      (m) =>
          (m['localId']?.toString() ?? '') == localId ||
          _messageId(m) == localId,
    );
    if (idx < 0) return;
    final msg = messages[idx];
    final state = (msg['state'] ?? '').toString();
    final requestId = msg['requestId']?.toString();
    final customerId = msg['customerId']?.toString();
    final mime = (msg['mime'] ?? '').toString();
    final text = (msg['text'] ?? msg['message'] ?? '').toString();
    final attachments = _collectAttachments(msg).toList();
    final localPath = msg['localFilePath']?.toString() ?? '';
    final mine = _isMine(msg);
    if (state != 'failed' && state != 'cancelled') return;

    if (!mine && attachments.isNotEmpty && localPath.isEmpty) {
      await startDownload(localId, attachments.first);
      return;
    }

    if (_typeOf(msg) == 'text') {
      if (requestId != null && requestId.isNotEmpty) {
        _updateLocalMessage(localId, {'state': 'retrying', 'error': null});
        await sendTextMessage(requestId, text, localId: localId);
      } else if (customerId != null && customerId.isNotEmpty) {
        _updateLocalMessage(localId, {'state': 'retrying', 'error': null});
        await sendDirectText(customerId, text, localId: localId);
      }
      return;
    }

    if (localPath.isNotEmpty && mime.isNotEmpty) {
      if (mine) {
        _updateLocalMessage(localId, {'state': 'retrying', 'error': null});
      }
      await _sendMedia(
        requestId: requestId?.isEmpty ?? true ? null : requestId,
        customerId: customerId?.isEmpty ?? true ? null : customerId,
        pathOrData: localPath,
        mime: mime,
        localId: localId,
      );
    }
  }

  Map<String, dynamic> _normalizeSocketPayload(Map<String, dynamic> data) {
    if (data['message'] is Map) {
      final msg = (data['message'] as Map).cast<String, dynamic>();
      void setIfMissing(String key, dynamic value) {
        if (msg.containsKey(key) || value == null) return;
        if (value is String && value.isEmpty) return;
        msg[key] = value;
      }

      setIfMissing('localId', data['localId']?.toString());
      final reqId = _stringifyId(
        data['requestId'] ?? data['request'] ?? msg['requestId'] ?? msg['request'],
      );
      if (reqId.isNotEmpty) {
        setIfMissing('requestId', reqId);
      }
      setIfMissing('customerId', data['customerId']?.toString());
      setIfMissing('type', data['type']?.toString());
      if (data['attachments'] is List && msg['attachments'] == null) {
        msg['attachments'] = (data['attachments'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return msg;
    }
    return data;
  }

  // =========================
  // ✅ FIXED: no auto fetchChats from socket events
  // =========================
  void onSocketMessage(Map<String, dynamic> raw) {
    final data = _normalizeSocketPayload(raw);
    final reqId = _stringifyId(
      data['requestId'] ?? data['request'] ?? data['request_id'],
    );
    final localId = data['localId']?.toString() ?? '';
    final isMine = _isMine(data);
    final skipLocalEcho = isMine && _consumeLocalEcho(localId);

    developer.log(
      '[ChatController] chat:message req=$reqId active=$activeRequestId len=${messages.length} isMine=$isMine skip=$skipLocalEcho',
      error: data,
    );

    if (!skipLocalEcho && activeRequestId != null && reqId == activeRequestId) {
      final before = messages.length;
      _addOrUpdateMessage(data);
      developer.log(
        '[ChatController] chat:message appended ${messages.length - before}',
      );
      final sender = (data['sender'] ?? data['role'] ?? '')
          .toString()
          .toLowerCase();
      if (sender != 'artisan') {
        final id = _messageId(data);
        if (id.isNotEmpty) _realtime.markRead(id, direct: false);
      }
      _resetUnreadForActive();
    }

    _upsertChatPreview(reqId, data);
  }

  void onSocketEdited(Map<String, dynamic> raw) {
    final data = _normalizeSocketPayload(raw);
    final reqId = _stringifyId(
      data['requestId'] ?? data['request'] ?? data['request_id'],
    );
    if (activeRequestId != null && reqId == activeRequestId) {
      _addOrUpdateMessage(data);
    }
    _upsertChatPreview(reqId, data);
  }

  // ✅ still ok to fetchChats on delete if needed, but it will be throttled by guard/cooldown
  void onSocketDeleted(Map<String, dynamic> raw) {
    final reqId = _stringifyId(
      raw['requestId'] ?? raw['request'] ?? raw['request_id'],
    );
    final messageId =
        raw['messageId']?.toString() ?? raw['_id']?.toString() ?? '';
    if (activeRequestId != null && reqId == activeRequestId) {
      _removeMessageById(messageId);
    }

    // No forced REST spam; if you want a sync you can call fetchChats() and it will be throttled.
    fetchChats();
  }

  void onSocketCleared(Map<String, dynamic> raw) {
    final reqId = _stringifyId(
      raw['requestId'] ?? raw['request'] ?? raw['request_id'],
    );
    if (reqId.isEmpty) return;
    if (activeRequestId == reqId) {
      messages.clear();
      messages.refresh();
    }
    chats.removeWhere(
      (c) => c['type'] != 'direct' && c['requestId']?.toString() == reqId,
    );
    chats.refresh();
  }

  // =========================
  // ✅ FIXED: no auto fetchChats from socket direct events
  // =========================
  void onSocketDirectMessage(Map<String, dynamic> raw) {
    final data = _normalizeSocketPayload(raw);
    final customerId = data['customerId']?.toString();
    final localId = data['localId']?.toString() ?? '';
    final isMine = _isMine(data);
    final skipLocalEcho = isMine && _consumeLocalEcho(localId);

    developer.log(
      '[ChatController] direct:message cid=$customerId active=$activeCustomerId len=${messages.length} isMine=$isMine skip=$skipLocalEcho',
      error: data,
    );

    final isActiveChat =
        isChatScreenOpen.value &&
        customerId != null &&
        activeCustomerId == customerId;

    if (!skipLocalEcho && isActiveChat) {
      final before = messages.length;
      _addOrUpdateMessage(data);
      developer.log(
        '[ChatController] direct:message appended ${messages.length - before}',
      );

      final sender = (data['sender'] ?? data['role'] ?? '')
          .toString()
          .toLowerCase();
      if (sender != 'artisan') {
        final id = _messageId(data);
        if (id.isNotEmpty) _realtime.markRead(id, direct: true);
      }
      _resetUnreadForActive();
    }

    // دايمًا حدّث preview (هيزود unread لو مش Active)
    _upsertChatPreview('', data);

    final id = _localOrMessageId(data);
    if (id.isNotEmpty) {
      directInbox.removeWhere((element) => _localOrMessageId(element) == id);
    }
    directInbox.insert(0, data);
  }

  void onSocketDirectEdited(Map<String, dynamic> raw) {
    final data = _normalizeSocketPayload(raw);
    final customerId = data['customerId']?.toString();
    if (customerId != null && activeCustomerId == customerId) {
      _addOrUpdateMessage(data);
    }
    _upsertChatPreview('', data);
  }

  void onSocketDirectDeleted(Map<String, dynamic> raw) {
    final messageId =
        raw['messageId']?.toString() ?? raw['_id']?.toString() ?? '';
    final customerId = raw['customerId']?.toString();
    if (customerId != null && activeCustomerId == customerId) {
      _removeMessageById(messageId);
    }
    fetchChats();
  }

  void onSocketDirectCleared(Map<String, dynamic> raw) {
    final customerId = raw['customerId']?.toString();
    if (customerId == null || customerId.isEmpty) return;
    if (activeCustomerId == customerId) {
      messages.clear();
      messages.refresh();
    }
    chats.removeWhere(
      (c) => c['type'] == 'direct' && c['customerId']?.toString() == customerId,
    );
    chats.refresh();
  }

  DateTime? _lastHydrate;
  void _hydrateChatsOnceIfNeeded(String shownName) {
    final v = shownName.trim();
    if (v.isEmpty) return;
    final looksLikeId = v.length >= 20;
    if (!looksLikeId) return;
    final now = DateTime.now();
    if (_lastHydrate != null && now.difference(_lastHydrate!).inSeconds < 5) {
      return;
    }

    _lastHydrate = now;
    fetchChats(force: true);
  }

  // =========================
  // ✅ FIXED: removed ANY fetchChats() inside upsert (was the spam trigger)
  // =========================
  void _upsertChatPreview(String requestId, Map<String, dynamic> message) {
    if (requestId.isEmpty) {
      final customerId = message['customerId']?.toString();
      if (customerId == null || customerId.isEmpty) return;

      final idx = chats.indexWhere(
        (c) =>
            c['type'] == 'direct' && c['customerId']?.toString() == customerId,
      );

      final existing = idx >= 0 ? chats[idx] : const <String, dynamic>{};
      final existingUnread = existing['unreadCount'] is num
          ? (existing['unreadCount'] as num).toInt()
          : 0;

      final customerName =
          message['customerName'] ??
          message['customer']?['name'] ??
          existing['customerName']?.toString() ??
          existing['name']?.toString() ??
          customerId;
      _hydrateChatsOnceIfNeeded(customerName.toString());

      final updated = {
        'type': 'direct',
        'customerId': customerId,
        'customerName': customerName,
        'name': customerName,
        'lastMessage': message['message'] ?? message['text'] ?? '',
        'lastSender': (message['sender'] ?? message['role'] ?? message['from'])
            ?.toString(),
        'updatedAt': message['createdAt'] ?? DateTime.now().toIso8601String(),
        'unreadCount': existingUnread,
      };

      final isFromOther =
          (message['sender']?.toString().toLowerCase() ?? '') != 'artisan';
      final isActive =
          isChatScreenOpen.value &&
          activeCustomerId == customerId &&
          activeRequestId == null;

      if (!isActive && isFromOther) {
        updated['unreadCount'] = existingUnread + 1;
      } else {
        updated['unreadCount'] = 0;
      }

      if (idx >= 0) {
        chats.removeAt(idx);
        chats.insert(0, {...existing, ...updated});
        chats.refresh();
      } else {
        updated['unreadCount'] = isFromOther ? 1 : 0;
        chats.insert(0, updated);
        chats.refresh();
        if (artisanId.isNotEmpty) {
          _realtime.subscribeToDirect(customerId, artisanId: artisanId);
        }
      }
      return;
    }

    final idx = chats.indexWhere(
      (c) =>
          (c['requestId'] ?? c['_id'] ?? c['id'] ?? '').toString() == requestId,
    );

    final existing = idx >= 0 ? chats[idx] : const <String, dynamic>{};
    final existingUnread = existing['unreadCount'] is num
        ? (existing['unreadCount'] as num).toInt()
        : 0;

    final senderRole = (message['sender'] ??
            message['role'] ??
            message['from'] ??
            message['senderType'])
        ?.toString()
        .toLowerCase();
    final isAdmin =
        senderRole == 'admin' || message['isAdmin'] == true;

    var customerName =
        message['customerName'] ??
        message['customer']?['name'] ??
        existing['customerName']?.toString() ??
        existing['name']?.toString() ??
        requestId;
    if (isAdmin &&
        (customerName.isEmpty ||
            (artisanName.isNotEmpty &&
                _sameText(customerName, artisanName)))) {
      customerName = _adminLabel();
    }
    _hydrateChatsOnceIfNeeded(customerName.toString());

    final updated = {
      'type': 'request',
      'requestId': requestId,
      'customerName': customerName,
      'name': customerName,
      'lastMessage': message['message'] ?? message['text'] ?? '',
      'lastSender': senderRole,
      'isAdmin': isAdmin,
      'updatedAt': message['createdAt'] ?? DateTime.now().toIso8601String(),
      'unreadCount': existingUnread,
    };

    final isFromOther =
        (message['sender']?.toString().toLowerCase() ?? '') != 'artisan';
    final isActive = activeRequestId == requestId;

    if (!isActive && isFromOther) {
      updated['unreadCount'] = existingUnread + 1;
    } else {
      updated['unreadCount'] = 0;
    }

    if (idx >= 0) {
      chats.removeAt(idx);
      chats.insert(0, {...existing, ...updated});
      chats.refresh();
    } else {
      chats.insert(0, updated);
      _realtime.subscribeToRequest(requestId);
    }
  }

void onArtisanInbox(Map<String, dynamic> payload) {
    final type = (payload['type'] ?? '').toString();
    final msgRaw = payload['message'];
    if (type != 'direct' && type != 'request') return;
    if (msgRaw is! Map) return;

    final msg = msgRaw.cast<String, dynamic>();

    // ✅ مهم: تجاهل direct هنا لأن direct:message بيجي بالفعل
    if (type == 'direct') {
      return; // <--- دي اللي هتوقف الزيادة بـ 2
    }

    // request فقط
    final reqId = _extractRequestId(payload, msg);
    if (reqId.isEmpty) return;

    final isAdmin = _isSystemInboxPayload(payload, msg) ||
        (msg['sender']?.toString().toLowerCase() == 'admin');
    if (isAdmin) {
      msg['sender'] ??= 'admin';
      msg['isAdmin'] = true;
      msg['text'] ??= _firstNonEmpty([
        payload['body'],
        msg['body'],
        msg['message'],
        msg['text'],
      ]);
      _pushInboxNotification(payload, msg, reqId);
    }

    final customerName = _extractCustomerName(payload, msg);
    if (customerName.isNotEmpty) {
      msg['customerName'] ??= customerName;
    }
    msg['requestId'] ??= reqId;

    _upsertChatPreview(reqId, msg);
  }

  void _pushInboxNotification(
    Map<String, dynamic> payload,
    Map<String, dynamic> msg,
    String requestId,
  ) {
    final title = _firstNonEmpty([
      payload['title'],
      msg['title'],
      AppStrings.notifications.tr,
    ]);
    final body = _firstNonEmpty([
      payload['body'],
      msg['body'],
      msg['text'],
      msg['message'],
    ]);

    if (title.isEmpty && body.isEmpty) return;

    final notification = <String, dynamic>{
      'id': _firstNonEmpty([
        payload['id'],
        payload['_id'],
        payload['notificationId'],
        msg['id'],
        msg['_id'],
        'inbox-${DateTime.now().microsecondsSinceEpoch}',
      ]),
      'title': title,
      'body': body,
      'requestId': requestId,
      'read': false,
      'createdAt': _firstNonEmpty([
        payload['createdAt'],
        msg['createdAt'],
        DateTime.now().toIso8601String(),
      ]),
    };

    if (Get.isRegistered<NotificationsController>()) {
      final controller = Get.find<NotificationsController>();
      controller.notifications.insert(0, notification);
    }

    AppSnackBar.show(
      title.isEmpty ? AppStrings.notifications.tr : title,
      body,
      type: SnackBarType.info,
      duration: const Duration(seconds: 4),
    );
  }


  void _subscribeForChats(List<Map<String, dynamic>> items) {
    for (final chat in items) {
      final type = chat['type']?.toString();
      if (type == 'direct') {
        final customerId = chat['customerId']?.toString();
        if (customerId != null && customerId.isNotEmpty) {
          _realtime.subscribeToDirect(customerId, artisanId: artisanId);
        }
      } else {
        final requestId = (chat['requestId'] ?? chat['_id'] ?? chat['id'])
            ?.toString();
        if (requestId != null && requestId.isNotEmpty) {
          _realtime.subscribeToRequest(requestId);
        }
      }
    }
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    final List<Map<String, dynamic>> result = [];
    if (data is Map<String, dynamic>) {
      if (data['requestChats'] is List) {
        for (final item in (data['requestChats'] as List)) {
          final map =
              (item as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
          final lastMessage = map['lastMessage'];
          final lastSender = lastMessage is Map
              ? (lastMessage['sender'] ?? lastMessage['role'])?.toString()
              : null;
          final isAdmin =
              (lastSender ?? '').toLowerCase() == 'admin' ||
              map['isAdmin'] == true;
          var customerName =
              map['customerName'] ?? map['customer']?['name'];
          if (isAdmin &&
              (customerName == null ||
                  customerName.toString().trim().isEmpty ||
                  (artisanName.isNotEmpty &&
                      _sameText(customerName.toString(), artisanName)))) {
            customerName = _adminLabel();
          }
          result.add({
            ...map,
            'type': 'request',
            'requestId': map['requestId'] ?? map['_id'] ?? map['id'],
            'customerName': customerName,
            'lastMessage': map['lastMessage'] is Map
                ? (map['lastMessage']['text'] ?? map['lastMessage']['message'])
                : map['lastMessage'],
            'lastSender': lastSender,
            'isAdmin': isAdmin,
            'updatedAt': map['lastMessage'] is Map
                ? map['lastMessage']['createdAt']
                : map['updatedAt'],
          });
        }
      }
      if (data['directChats'] is List) {
        for (final item in (data['directChats'] as List)) {
          final map =
              (item as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
          final lastMessage = map['lastMessage'];
          final lastSender = lastMessage is Map
              ? (lastMessage['sender'] ?? lastMessage['role'])?.toString()
              : null;
          result.add({
            ...map,
            'type': 'direct',
            'customerId': map['customerId'],
            'customerName':
                map['customerName'] ??
                map['customer']?['name'] ??
                map['customerId'],
            'lastMessage': map['lastMessage'] is Map
                ? (map['lastMessage']['text'] ?? map['lastMessage']['message'])
                : map['lastMessage'],
            'lastSender': lastSender,
            'updatedAt': map['lastMessage'] is Map
                ? map['lastMessage']['createdAt']
                : map['updatedAt'],
          });
        }
      }
      if (result.isNotEmpty) return result;
      if (data['messages'] is List) {
        return (data['messages'] as List)
            .map(
              (e) =>
                  (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
            )
            .toList();
      }
      if (data['items'] is List) {
        return (data['items'] as List)
            .map(
              (e) =>
                  (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
            )
            .toList();
      }
    }
    if (data is List) {
      return data
          .map(
            (e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
          )
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _dedupeById(List<Map<String, dynamic>> items) {
    final ids = <String>{};
    final localIds = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final item in items) {
      final id = _messageId(item);
      final local = item['localId']?.toString() ?? '';
      final isNewId = id.isNotEmpty ? ids.add(id) : true;
      final isNewLocal = local.isNotEmpty ? localIds.add(local) : true;
      if (isNewId && isNewLocal) deduped.add(item);
    }
    return deduped;
  }

  void _markAllAsRead(List<Map<String, dynamic>> list) {
    final isDirect = activeCustomerId != null;
    for (final m in list) {
      final id = _messageId(m);
      if (id.isEmpty) continue;
      _realtime.markRead(id, direct: isDirect);
    }
    _resetUnreadForActive();
  }

  void onSocketRead(String messageId) {
    final idx = messages.indexWhere((m) => _messageId(m) == messageId);
    if (idx >= 0) {
      messages[idx] = {...messages[idx], 'read': true, 'state': 'read'};
      messages.refresh();
    }
  }

  void onSocketBlock(Map data) {
    blocked.value = true;
  }

  void onSocketUnblock(Map data) {
    blocked.value = false;
  }

  void _resetUnreadForActive() {
    if (activeCustomerId != null) {
      final idx = chats.indexWhere(
        (c) =>
            c['type'] == 'direct' &&
            (c['customerId']?.toString() ?? '') == activeCustomerId,
      );
      if (idx >= 0) {
        chats[idx] = {...chats[idx], 'unreadCount': 0};
        chats.refresh();
      }
      return;
    }
    if (activeRequestId != null) {
      final idx = chats.indexWhere(
        (c) =>
            c['type'] != 'direct' &&
            (c['requestId'] ?? c['_id'] ?? c['id'] ?? '').toString() ==
                activeRequestId,
      );
      if (idx >= 0) {
        chats[idx] = {...chats[idx], 'unreadCount': 0};
        chats.refresh();
      }
    }
  }

  void _showSnack(String message) {
    AppSnackBar.show(
      AppStrings.error.tr,
      message,
      type: SnackBarType.error,
    );
  }

  void _handleError(Object error, String fallback) {
    if (error is ApiException && error.message.isNotEmpty) {
      _showSnack(error.message);
      return;
    }
    _showSnack(fallback);
  }

  Future<void> _loadIdentity() async {
    if (!_isAuthenticated) return;
    await _prefs.init();

    try {
      final cached = _prefs.getString(kCachedProfileKey);
      if (cached != null && cached.isNotEmpty) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        artisanId = map['_id']?.toString() ?? artisanId;
        artisanName = map['name']?.toString() ?? artisanName;

        if (artisanId.isNotEmpty) {
          _realtime.subscribeToArtisanInbox(artisanId); // ✅ هنا
        }

        if (artisanId.isNotEmpty && chats.isNotEmpty) {
          _subscribeForChats(chats);
        }

        return;
      }
    } catch (_) {}

    try {
      final resp = await _api.me();
      final data = ApiClient.instance.unwrapData(resp);

      if (data is Map<String, dynamic>) {
        artisanId =
            (data['artisan']?['_id'] ?? data['_id'])?.toString() ?? artisanId;
        artisanName =
            (data['artisan']?['name'] ?? data['name'])?.toString() ??
            artisanName;

        if (artisanId.isNotEmpty) {
          _realtime.subscribeToArtisanInbox(artisanId); // ✅ وهنا كمان (المهم)
        }

        if (artisanId.isNotEmpty && chats.isNotEmpty) {
          _subscribeForChats(chats);
        }
      }
    } catch (_) {}
  }

  bool get _isAuthenticated =>
      Get.isRegistered<AuthService>() &&
      Get.find<AuthService>().isAuthenticated;

  void _setupAuthBootstrap() {
    if (_isAuthenticated) {
      _bootstrapRealtime();
    }
    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      _authSub = auth.authenticatedStream.listen((authed) {
        if (authed) {
          _bootstrapRealtime();
        } else {
          _bootstrapped = false;
          artisanId = '';
          chats.clear();
          messages.clear();
          directInbox.clear();
          for (final t in _uploadTokens.values) {
            t.cancel('auth_changed');
          }
          for (final t in _downloadTokens.values) {
            t.cancel('auth_changed');
          }
          _uploadTokens.clear();
          _downloadTokens.clear();
          _realtime.clearSubscriptions();
        }
      });
    } else {
      _bootstrapRealtime();
    }
  }

  void _bootstrapRealtime() {
    if (_bootstrapped) return;
    _bootstrapped = true;
    if (!_realtime.isStarted) {
      _realtime.start();
    }
    if (Get.isRegistered<RealtimeController>(tag: 'artisan')) {
      Get.find<RealtimeController>(tag: 'artisan').connectIfNeeded();
    }
    _loadIdentity();
  }

  @override
  void onClose() {
    for (final token in _uploadTokens.values) {
      token.cancel('disposed');
    }
    for (final token in _downloadTokens.values) {
      token.cancel('disposed');
    }
    _uploadTokens.clear();
    _downloadTokens.clear();
    _authSub?.cancel();
    super.onClose();
  }
}


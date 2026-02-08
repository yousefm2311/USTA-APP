import 'dart:async';

import 'package:get/get.dart';
import 'package:usta/Customer/core/realtime/events.dart';
import 'package:usta/Customer/core/realtime/realtime_controller.dart';
import 'package:usta/Customer/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Customer/core/realtime/socket_manager.dart';
import 'package:usta/Customer/features/customer/chat/controller/chat_controller.dart';

class ChatRealtimeService extends GetxService implements RealtimeAwareService {
  final RealtimeController _rt = Get.find<RealtimeController>(tag: 'customer');
  ChatController? _chatController;

  final List<_QueuedMessage> _outbox = [];
  final List<_PendingRead> _pendingReads = [];
  final List<_PendingSubscription> _pendingSubs = [];
  StreamSubscription<SocketStatus>? _statusSub;
  bool _started = false;
  String? _lastRequestSub;
  String? _lastDirectCustomer;
  String? _lastDirectArtisan;

  @override
  bool get isStarted => _started;

  bool get isConnected => _rt.status.value == SocketStatus.connected;

  @override
  void onInit() {
    super.onInit();
    start();
  }

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _listenConnection();
    if (_rt.status.value == SocketStatus.connected) {
      _registerEvents();
      _flushSubscriptions();
      _resubscribeActive();
      _flushOutbox();
      _flushReads();
    }
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _statusSub?.cancel();
    _statusSub = null;
    _outbox.clear();
    _pendingReads.clear();
    _pendingSubs.clear();
    _lastRequestSub = null;
    _lastDirectCustomer = null;
    _lastDirectArtisan = null;
  }

  void _listenConnection() {
    _statusSub?.cancel();
    _statusSub = _rt.status.stream.listen((status) {
      if (status == SocketStatus.connected) {
        _registerEvents();
        _flushSubscriptions();
        _resubscribeActive();
        _flushOutbox();
        _flushReads();
        _ensureChatController();
        if (_chatController != null && _chatController!.chats.isEmpty) {
          _chatController!.fetchChats();
        }
      }
    });
  }

  void _registerEvents() {
    _rt.offEvent(RealtimeEvents.chatMessage);
    _rt.offEvent(RealtimeEvents.chatRead);
    _rt.offEvent(RealtimeEvents.directMessage);
    _rt.offEvent(RealtimeEvents.directRead);
    _rt.offEvent(RealtimeEvents.directBlock);
    _rt.offEvent(RealtimeEvents.directUnblock);
    _rt.offEvent(RealtimeEvents.directBlocked);
    _rt.offEvent(RealtimeEvents.directUnblocked);

    _rt.onEvent(RealtimeEvents.chatMessage, (data) {
      _ensureChatController();
      if (!_started ||
          data is! Map<String, dynamic> ||
          _chatController == null) {
        return;
      }
      _chatController!.onSocketMessage(_normalizeSocketPayload(data));
    });

    _rt.onEvent(RealtimeEvents.chatRead, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketRead(
        (data['messageId'] ?? data['_id'] ?? data['id'] ?? '').toString(),
      );
    });

    _rt.onEvent(RealtimeEvents.directMessage, (data) {
      _ensureChatController();
      if (!_started ||
          data is! Map<String, dynamic> ||
          _chatController == null) {
        return;
      }
      _chatController!.onSocketDirectMessage(_normalizeSocketPayload(data));
    });

    _rt.onEvent(RealtimeEvents.directRead, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketRead(
        (data['messageId'] ?? data['_id'] ?? data['id'] ?? '').toString(),
      );
    });

    _rt.onEvent(RealtimeEvents.directBlock, (data) {
      if (!_started) return;
      _ensureChatController();
      _chatController?.onSocketBlock(data);
    });

    _rt.onEvent(RealtimeEvents.directUnblock, (data) {
      if (!_started) return;
      _ensureChatController();
      _chatController?.onSocketUnblock(data);
    });

    _rt.onEvent(RealtimeEvents.directBlocked, (data) {
      if (!_started) return;
      _ensureChatController();
      _chatController?.onSocketBlock(data);
    });

    _rt.onEvent(RealtimeEvents.directUnblocked, (data) {
      if (!_started) return;
      _ensureChatController();
      _chatController?.onSocketUnblock(data);
    });
  }

  void subscribeToRequest(String requestId) {
    if (requestId.isEmpty) return;
    if (_lastRequestSub == requestId) return;
    _lastRequestSub = requestId;
    if (_rt.status.value != SocketStatus.connected) {
      _queueSub(_PendingSubscription(requestId: requestId));
      _rt.reconnect();
      return;
    }
    _rt.emit(RealtimeEvents.chatSubscribe, {'requestId': requestId});
  }

  void subscribeToDirect(String customerId, {String? artisanId}) {
    if (customerId.isEmpty && (artisanId == null || artisanId.isEmpty)) return;
    if (_lastDirectCustomer == customerId &&
        (_lastDirectArtisan ?? '') == (artisanId ?? '')) {
      return;
    }
    _lastDirectCustomer = customerId;
    _lastDirectArtisan = artisanId;
    if (_rt.status.value != SocketStatus.connected) {
      _queueSub(_PendingSubscription(
        customerId: customerId,
        artisanId: artisanId,
      ));
      _rt.reconnect();
      return;
    }
    _rt.emit(RealtimeEvents.directSubscribe, {
      if (customerId.isNotEmpty) 'customerId': customerId,
      if (artisanId != null && artisanId.isNotEmpty) 'artisanId': artisanId,
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    _ensureChatController();
    if (_rt.status.value != SocketStatus.connected) {
      _outbox.add(_QueuedMessage(message));
      return;
    }
    final isDirect = message['direct'] == true;
    final event = isDirect
        ? RealtimeEvents.directMessage
        : RealtimeEvents.chatMessage;
    final localId = (message['localId'] ?? '').toString();
    void markSentFallback() {
      if (localId.isNotEmpty) {
        _markState({'localId': localId}, 'sent');
      }
    }

    bool acked = false;
    _rt.emit(
      event,
      message,
      ack: (resp) {
        acked = true;
        if (resp is Map && message['localId'] != null) {
          final local = message['localId'];
          resp['localId'] ??= local;
          if (resp['message'] is Map) {
            (resp['message'] as Map)['localId'] ??= local;
          }
        }
        _markState(resp, 'sent');
        if (resp is Map && _chatController != null) {
          final map = resp.cast<String, dynamic>();
          if (isDirect) {
            _chatController!.onSocketDirectMessage(map);
          } else {
            _chatController!.onSocketMessage(map);
          }
        }
      },
    );
    if (localId.isNotEmpty) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!acked) markSentFallback();
      });
    }
  }

  void markRead(String messageId, {required bool direct}) {
    if (messageId.isEmpty) return;
    final event = direct ? RealtimeEvents.directRead : RealtimeEvents.chatRead;
    if (_rt.status.value != SocketStatus.connected) {
      _pendingReads.add(_PendingRead(messageId, direct: direct));
      return;
    }
    _rt.emit(event, {'messageId': messageId});
  }

  void _markState(dynamic data, String state) {
    _ensureChatController();
    if (data is! Map || _chatController == null) return;
    String id =
        (data['localId'] ??
                data['messageId'] ??
                data['_id'] ??
                data['id'] ??
                '')
            .toString();
    if (id.isEmpty && data['message'] is Map) {
      final msg = data['message'] as Map;
      id = (msg['localId'] ?? msg['messageId'] ?? msg['_id'] ?? msg['id'] ?? '')
          .toString();
    }
    if (id.isEmpty) return;

    final index = _chatController!.messages.indexWhere(
      (m) =>
          (m['localId'] ?? '').toString() == id ||
          (m['_id'] ?? m['id'] ?? m['messageId'] ?? '').toString() == id,
    );
    if (index >= 0) {
      _chatController!.messages[index] = {
        ..._chatController!.messages[index],
        'state': state,
      };
      _chatController!.messages.refresh();
    }
  }

  void _flushOutbox() {
    if (_outbox.isEmpty) return;
    final pending = List<_QueuedMessage>.from(_outbox);
    _outbox.clear();
    for (final item in pending) {
      sendMessage(item.payload);
    }
  }

  void _flushSubscriptions() {
    if (_pendingSubs.isEmpty) return;
    final pending = List<_PendingSubscription>.from(_pendingSubs);
    _pendingSubs.clear();
    for (final sub in pending) {
      if (sub.requestId != null) {
        subscribeToRequest(sub.requestId!);
      } else if (sub.customerId != null) {
        subscribeToDirect(sub.customerId!, artisanId: sub.artisanId);
      }
    }
  }

  void _queueSub(_PendingSubscription sub) {
    final exists = _pendingSubs.any((s) =>
        s.requestId == sub.requestId &&
        s.customerId == sub.customerId &&
        s.artisanId == sub.artisanId);
    if (!exists) _pendingSubs.add(sub);
  }

  void _flushReads() {
    if (_pendingReads.isEmpty) return;
    final pending = List<_PendingRead>.from(_pendingReads);
    _pendingReads.clear();
    for (final read in pending) {
      markRead(read.id, direct: read.direct);
    }
  }

  void _resubscribeActive() {
    _ensureChatController();
    if (_chatController == null) return;
    final activeReq = _chatController!.activeRequestId;
    final activeArtisan = _chatController!.activeArtisanId;
    final customerId = _chatController!.customerId;
    if (activeReq != null && activeReq.isNotEmpty) {
      subscribeToRequest(activeReq);
    }
    if ((customerId != null && customerId.isNotEmpty) &&
        (activeArtisan != null && activeArtisan.isNotEmpty)) {
      subscribeToDirect(customerId, artisanId: activeArtisan);
    }
  }

  void _ensureChatController() {
    if (_chatController == null && Get.isRegistered<ChatController>(tag: 'customer')) {
      _chatController = Get.find<ChatController>(tag: 'customer');
    }
  }

  @override
  void onClose() {
    _statusSub?.cancel();
    super.onClose();
  }
}

class _QueuedMessage {
  final Map<String, dynamic> payload;
  _QueuedMessage(this.payload);
}

class _PendingRead {
  final String id;
  final bool direct;
  _PendingRead(this.id, {required this.direct});
}

class _PendingSubscription {
  final String? requestId;
  final String? customerId;
  final String? artisanId;

  _PendingSubscription({this.requestId, this.customerId, this.artisanId});
}

Map<String, dynamic> _normalizeSocketPayload(Map<String, dynamic> data) {
  if (data['message'] is Map<String, dynamic>) {
    final msg = Map<String, dynamic>.from(data['message'] as Map<String, dynamic>);

    void setIfMissing(String key, dynamic value) {
      if (msg.containsKey(key) || value == null) return;
      if (value is String && value.isEmpty) return;
      msg[key] = value;
    }

    setIfMissing('localId', data['localId']?.toString());
    final reqId = _stringifyId(
      data['requestId'] ??
          data['request'] ??
          data['request_id'] ??
          msg['requestId'] ??
          msg['request'] ??
          msg['request_id'],
    );
    if (reqId.isNotEmpty) {
      setIfMissing('requestId', reqId);
    }
    setIfMissing('customerId', data['customerId']?.toString());
    setIfMissing('artisanId', data['artisanId']?.toString());
    setIfMissing('otherId', data['otherId']?.toString());
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

String _stringifyId(dynamic raw) {
  if (raw == null) return '';
  if (raw is Map) {
    final id = raw['_id'] ?? raw['id'];
    return id?.toString() ?? '';
  }
  return raw.toString();
}


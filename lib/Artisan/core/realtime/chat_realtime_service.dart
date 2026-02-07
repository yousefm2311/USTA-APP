// import 'dart:async';
// import 'dart:developer' as developer;

// import 'package:get/get.dart';
// import 'package:usta/Artisan/core/realtime/events.dart';
// import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
// import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
// import 'package:usta/Artisan/core/realtime/socket_service.dart';
// import 'package:usta/Artisan/features/artisan/chat/controllers/chat_controller.dart';

// class ChatRealtimeService extends GetxService implements RealtimeAwareService {
//   final RealtimeController _rt = Get.find<RealtimeController>(tag: 'artisan');
//   ChatController? _chatController;

//   final List<_QueuedMessage> _outbox = [];
//   final List<_PendingRead> _pendingReads = [];
//   StreamSubscription<SocketStatus>? _statusSub;
//   final Set<String> _requestSubscriptions = <String>{};
//   final Map<String, String?> _directSubscriptions = <String, String?>{};
//   bool _started = false;
//   bool _eventsRegistered = false;

//   @override
//   bool get isStarted => _started;
//   bool get isConnected => _rt.status.value == SocketStatus.connected;

//   @override
//   Future<void> start() async {
//     if (_started) return;
//     _started = true;
//     _rt.connectIfNeeded();
//     developer.log('[ChatRT] start() — status=${_rt.status.value}');
//     _listenConnection();
//     if (_rt.status.value == SocketStatus.connected) {
//       _registerEvents();
//       _resubscribeTracked();
//       _flushOutbox();
//       _flushReads();
//     }
//   }

//   @override
//   Future<void> stop() async {
//     if (!_started) return;
//     _started = false;
//     developer.log('[ChatRT] stop()');
//     await _statusSub?.cancel();
//     _statusSub = null;
//     _outbox.clear();
//     _pendingReads.clear();
//     _unregisterEvents();
//   }

//   void _listenConnection() {
//     _statusSub?.cancel();
//     _statusSub = _rt.status.stream.listen((status) {
//       developer.log('[ChatRT] status -> $status');
//       if (status == SocketStatus.connected) {
//         _registerEvents(); // Register AFTER socket connects
//         _resubscribeTracked();
//         _flushOutbox();
//         _flushReads();
//       } else {
//         _unregisterEvents();
//         _rt.connectIfNeeded();
//       }
//     });
//   }

//   void _registerEvents() {
//     if (_eventsRegistered) return;
//     developer.log('[ChatRT] register events');
//     _eventsRegistered = true;
//     _rt.onEvent(RealtimeEvents.chatMessage, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map<String, dynamic> || _chatController == null) {
//         return;
//       }
//       developer.log('[ChatRT] incoming chat:message => $data');
//       _chatController!.onSocketMessage(data);
//       });

//     _rt.onEvent(RealtimeEvents.chatRead, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketRead(
//         (data['messageId'] ?? data['_id'] ?? data['id'] ?? '').toString(),
//       );
//     });

//     _rt.onEvent(RealtimeEvents.chatEdited, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketEdited(data.cast<String, dynamic>());
//     });

//     _rt.onEvent(RealtimeEvents.chatDeleted, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketDeleted(data.cast<String, dynamic>());
//     });

//     _rt.onEvent(RealtimeEvents.chatCleared, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketCleared(data.cast<String, dynamic>());
//     });

//     _rt.onEvent(RealtimeEvents.directMessage, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map<String, dynamic> || _chatController == null) {
//         return;
//       }
//       developer.log('[ChatRT] incoming direct:message => $data');
//       _chatController!.onSocketDirectMessage(data);
//     });

//     _rt.onEvent(RealtimeEvents.directRead, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketRead(
//         (data['messageId'] ?? data['_id'] ?? data['id'] ?? '').toString(),
//       );
//     });

//     _rt.onEvent(RealtimeEvents.directEdited, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketDirectEdited(data.cast<String, dynamic>());
//     });

//     _rt.onEvent(RealtimeEvents.directDeleted, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketDirectDeleted(data.cast<String, dynamic>());
//     });

//     _rt.onEvent(RealtimeEvents.directCleared, (data) {
//       _ensureChatController();
//       if (!_started || data is! Map || _chatController == null) return;
//       _chatController!.onSocketDirectCleared(data.cast<String, dynamic>());
//     });

//     _rt.onEvent(RealtimeEvents.directBlock, (data) {
//       if (!_started) return;
//       _ensureChatController();
//       _chatController?.onSocketBlock(data);
//     });

//     _rt.onEvent(RealtimeEvents.directUnblock, (data) {
//       if (!_started) return;
//       _ensureChatController();
//       _chatController?.onSocketUnblock(data);
//     });

//     // Aliases emitted by backend
//     _rt.onEvent(RealtimeEvents.directBlocked, (data) {
//       if (!_started) return;
//       _ensureChatController();
//       _chatController?.onSocketBlock(data);
//     });

//     _rt.onEvent(RealtimeEvents.directUnblocked, (data) {
//       if (!_started) return;
//       _ensureChatController();
//       _chatController?.onSocketUnblock(data);
//     });
//   }

//   void _unregisterEvents() {
//     if (!_eventsRegistered) return;
//     _rt.offEvent(RealtimeEvents.chatMessage);
//     _rt.offEvent(RealtimeEvents.chatRead);
//     _rt.offEvent(RealtimeEvents.chatEdited);
//     _rt.offEvent(RealtimeEvents.chatDeleted);
//     _rt.offEvent(RealtimeEvents.chatCleared);
//     _rt.offEvent(RealtimeEvents.directMessage);
//     _rt.offEvent(RealtimeEvents.directRead);
//     _rt.offEvent(RealtimeEvents.directEdited);
//     _rt.offEvent(RealtimeEvents.directDeleted);
//     _rt.offEvent(RealtimeEvents.directCleared);
//     _rt.offEvent(RealtimeEvents.directBlock);
//     _rt.offEvent(RealtimeEvents.directUnblock);
//     _rt.offEvent(RealtimeEvents.directBlocked);
//     _rt.offEvent(RealtimeEvents.directUnblocked);
//     _eventsRegistered = false;
//   }


//   void subscribeToRequest(String requestId) {
//     if (requestId.isEmpty) return;
//     _requestSubscriptions.add(requestId);
//     developer.log('[ChatRT] subscribeToRequest $requestId (connected=${_rt.status.value == SocketStatus.connected})');
//     _rt.emit(RealtimeEvents.chatSubscribe, {'requestId': requestId});
//   }

//   void _resubscribeTracked() {
//     if (_rt.status.value != SocketStatus.connected) return;
//     developer.log('[ChatRT] resubscribe tracked: requests=${_requestSubscriptions.length} directs=${_directSubscriptions.length}');
//     for (final id in _requestSubscriptions) {
//       _rt.emit(RealtimeEvents.chatSubscribe, {'requestId': id});
//     }
//     _directSubscriptions.forEach((customerId, artisanId) {
//       final payload = {
//         'customerId': customerId,
//         if (artisanId != null && artisanId.isNotEmpty) 'artisanId': artisanId,
//       };
//       _rt.emit(RealtimeEvents.directSubscribe, payload);
//     });
//   }

//   void subscribeToDirect(String customerId, {String? artisanId}) {
//     if (customerId.isEmpty) return;
//     final existing = _directSubscriptions[customerId];
//     _directSubscriptions[customerId] = artisanId ?? existing;
//     final payload = {
//       'customerId': customerId,
//       if ((artisanId ?? existing ?? '').isNotEmpty) 'artisanId': artisanId ?? existing,
//     };
//     developer.log('[ChatRT] subscribeToDirect $customerId artisan=${payload['artisanId']} (connected=${_rt.status.value == SocketStatus.connected})');
//     _rt.emit(RealtimeEvents.directSubscribe, payload);
//   }

//   void clearSubscriptions() {
//     _requestSubscriptions.clear();
//     _directSubscriptions.clear();
//   }

//   void sendMessage(Map<String, dynamic> message) {
//     _ensureChatController();
//     if (_rt.status.value != SocketStatus.connected) {
//       _outbox.add(_QueuedMessage(message));
//       return;
//     }
//     final isDirect = message['direct'] == true;
//     final event =
//         isDirect ? RealtimeEvents.directMessage : RealtimeEvents.chatMessage;
//     // Fallback: mark as sent after a short delay even if ack is missing to avoid stuck "sending".
//     final localId = (message['localId'] ?? '').toString();
//     void markSentFallback() {
//       if (localId.isNotEmpty) {
//         _markState({'localId': localId}, 'sent');
//       }
//     }
//     bool acked = false;
//     _rt.emit(
//       event,
//       message,
//       ack: (resp) {
//         acked = true;
//         // Preserve localId so the UI can merge local -> server copy even if backend omits it.
//         if (resp is Map && message['localId'] != null) {
//           final localId = message['localId'];
//           resp['localId'] ??= localId;
//           // Also copy to nested message payloads to help merge media echoes.
//           if (resp['message'] is Map) {
//             (resp['message'] as Map)['localId'] ??= localId;
//           }
//         }
//         _markState(resp, 'sent');
//         if (resp is Map && _chatController != null) {
//           // Update with server copy (id/read/etc)
//           _chatController!.onSocketMessage(resp.cast<String, dynamic>());
//         }
//       },
//     );
//     // If backend never acks, still move the pending message out of "sending".
//     if (localId.isNotEmpty) {
//       Future.delayed(const Duration(seconds: 3), () {
//         if (!acked) markSentFallback();
//       });
//     }
//   }

//   void markRead(String messageId, {required bool direct}) {
//     if (messageId.isEmpty) return;
//     final event = direct ? RealtimeEvents.directRead : RealtimeEvents.chatRead;
//     if (_rt.status.value != SocketStatus.connected) {
//       _pendingReads.add(_PendingRead(messageId, direct: direct));
//       return;
//     }
//     _rt.emit(event, {'messageId': messageId});
//   }

//   void _markState(dynamic data, String state) {
//     _ensureChatController();
//     if (data is! Map || _chatController == null) return;
//     String id =
//         (data['localId'] ??
//                 data['messageId'] ??
//                 data['_id'] ??
//                 data['id'] ??
//                 '')
//             .toString();
//     // Fall back to nested message payloads (common when backend wraps ack in {message: {...}}).
//     if (id.isEmpty && data['message'] is Map) {
//       final msg = data['message'] as Map;
//       id = (msg['localId'] ??
//               msg['messageId'] ??
//               msg['_id'] ??
//               msg['id'] ??
//               '')
//           .toString();
//     }
//     if (id.isEmpty) return;
//     final index = _chatController!.messages.indexWhere(
//       (m) =>
//           (m['localId'] ?? '').toString() == id ||
//           (m['_id'] ?? m['id'] ?? m['messageId'] ?? '').toString() == id,
//     );
//     if (index >= 0) {
//       _chatController!.messages[index] = {
//         ..._chatController!.messages[index],
//         'state': state,
//       };
//       _chatController!.messages.refresh();
//     }
//   }

//   void _flushOutbox() {
//     if (_outbox.isEmpty) return;
//     final pending = List<_QueuedMessage>.from(_outbox);
//     _outbox.clear();
//     for (final item in pending) {
//       sendMessage(item.payload);
//     }
//   }

//   void _flushReads() {
//     if (_pendingReads.isEmpty) return;
//     final pending = List<_PendingRead>.from(_pendingReads);
//     _pendingReads.clear();
//     for (final read in pending) {
//       markRead(read.id, direct: read.direct);
//     }
//   }

//   void _ensureChatController() {
//     if (_chatController == null && Get.isRegistered<ChatController>(tag: 'artisan')) {
//       _chatController = Get.find<ChatController>(tag: 'artisan');
//     }
//   }

//   @override
//   void onClose() {
//     _statusSub?.cancel();
//     super.onClose();
//   }
// }

// class _QueuedMessage {
//   final Map<String, dynamic> payload;
//   _QueuedMessage(this.payload);
// }

// class _PendingRead {
//   final String id;
//   final bool direct;
//   _PendingRead(this.id, {required this.direct});
// }




import 'dart:async';
import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/events.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/features/artisan/chat/controllers/chat_controller.dart';

class ChatRealtimeService extends GetxService implements RealtimeAwareService {
  final RealtimeController _rt = Get.find<RealtimeController>(tag: 'artisan');
  ChatController? _chatController;

  final List<_QueuedMessage> _outbox = [];
  final List<_PendingRead> _pendingReads = [];
  StreamSubscription<SocketStatus>? _statusSub;

  final Set<String> _requestSubscriptions = <String>{};
  final Map<String, String?> _directSubscriptions = <String, String?>{};

  // ✅ NEW: Artisan inbox subscription (always on)
  String? _artisanInboxId;

  bool _started = false;
  bool _eventsRegistered = false;

  @override
  bool get isStarted => _started;
  bool get isConnected => _rt.status.value == SocketStatus.connected;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _rt.connectIfNeeded();
    developer.log('[ChatRT] start() — status=${_rt.status.value}');

    _listenConnection();

    if (_rt.status.value == SocketStatus.connected) {
      _registerEvents();
      _resubscribeTracked();
      _flushOutbox();
      _flushReads();
    }
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    developer.log('[ChatRT] stop()');

    await _statusSub?.cancel();
    _statusSub = null;

    _outbox.clear();
    _pendingReads.clear();

    _unregisterEvents();
  }

  void _listenConnection() {
    _statusSub?.cancel();
    _statusSub = _rt.status.stream.listen((status) {
      developer.log('[ChatRT] status -> $status');

      if (status == SocketStatus.connected) {
        _registerEvents(); // Register AFTER socket connects
        _resubscribeTracked();
        _flushOutbox();
        _flushReads();
      } else {
        _unregisterEvents();
        _rt.connectIfNeeded();
      }
    });
  }

  void _registerEvents() {
    if (_eventsRegistered) return;
    developer.log('[ChatRT] register events');
    _eventsRegistered = true;

    _rt.onEvent(RealtimeEvents.chatMessage, (data) {
      _ensureChatController();
      if (!_started ||
          data is! Map<String, dynamic> ||
          _chatController == null) {
        return;
      }
      developer.log('[ChatRT] incoming chat:message => $data');
      _chatController!.onSocketMessage(data);
    });

    _rt.onEvent(RealtimeEvents.chatRead, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketRead(
        (data['messageId'] ?? data['_id'] ?? data['id'] ?? '').toString(),
      );
    });

    _rt.onEvent(RealtimeEvents.chatEdited, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketEdited(data.cast<String, dynamic>());
    });

    _rt.onEvent(RealtimeEvents.chatDeleted, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketDeleted(data.cast<String, dynamic>());
    });

    _rt.onEvent(RealtimeEvents.chatCleared, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketCleared(data.cast<String, dynamic>());
    });

    _rt.onEvent(RealtimeEvents.directMessage, (data) {
      _ensureChatController();
      if (!_started ||
          data is! Map<String, dynamic> ||
          _chatController == null) {
        return;
      }
      developer.log('[ChatRT] incoming direct:message => $data');
      _chatController!.onSocketDirectMessage(data);
    });

    _rt.onEvent(RealtimeEvents.directRead, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketRead(
        (data['messageId'] ?? data['_id'] ?? data['id'] ?? '').toString(),
      );
    });

    _rt.onEvent(RealtimeEvents.directEdited, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketDirectEdited(data.cast<String, dynamic>());
    });

    _rt.onEvent(RealtimeEvents.directDeleted, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketDirectDeleted(data.cast<String, dynamic>());
    });

    _rt.onEvent(RealtimeEvents.directCleared, (data) {
      _ensureChatController();
      if (!_started || data is! Map || _chatController == null) return;
      _chatController!.onSocketDirectCleared(data.cast<String, dynamic>());
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

    // Aliases emitted by backend
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

    // ✅ NEW: artisan inbox event (this is what fixes your issue)
    _rt.onEvent(RealtimeEvents.artisanInbox, (data) {
      _ensureChatController();
      if (!_started || _chatController == null || data is! Map) return;

      final map = data.cast<String, dynamic>();
      developer.log('[ChatRT] incoming artisan:inbox => $map');

      _chatController!.onArtisanInbox(data.cast<String, dynamic>());
    });
  }

  void _unregisterEvents() {
    if (!_eventsRegistered) return;

    _rt.offEvent(RealtimeEvents.chatMessage);
    _rt.offEvent(RealtimeEvents.chatRead);
    _rt.offEvent(RealtimeEvents.chatEdited);
    _rt.offEvent(RealtimeEvents.chatDeleted);
    _rt.offEvent(RealtimeEvents.chatCleared);

    _rt.offEvent(RealtimeEvents.directMessage);
    _rt.offEvent(RealtimeEvents.directRead);
    _rt.offEvent(RealtimeEvents.directEdited);
    _rt.offEvent(RealtimeEvents.directDeleted);
    _rt.offEvent(RealtimeEvents.directCleared);

    _rt.offEvent(RealtimeEvents.directBlock);
    _rt.offEvent(RealtimeEvents.directUnblock);
    _rt.offEvent(RealtimeEvents.directBlocked);
    _rt.offEvent(RealtimeEvents.directUnblocked);

    // ✅ NEW
    _rt.offEvent(RealtimeEvents.artisanInbox);

    _eventsRegistered = false;
  }

  // ✅ NEW: call this once when artisanId is known
  void subscribeToArtisanInbox(String artisanId) {
    if (artisanId.isEmpty) return;

    _artisanInboxId = artisanId;
    developer.log(
      '[ChatRT] subscribeToArtisanInbox $artisanId (connected=${_rt.status.value == SocketStatus.connected})',
    );

    _rt.emit(RealtimeEvents.artisanSubscribe, {'artisanId': artisanId});
  }

  void subscribeToRequest(String requestId) {
    if (requestId.isEmpty) return;
    _requestSubscriptions.add(requestId);
    developer.log(
      '[ChatRT] subscribeToRequest $requestId (connected=${_rt.status.value == SocketStatus.connected})',
    );
    _rt.emit(RealtimeEvents.chatSubscribe, {'requestId': requestId});
  }

  void subscribeToDirect(String customerId, {String? artisanId}) {
    if (customerId.isEmpty) return;

    final existing = _directSubscriptions[customerId];
    _directSubscriptions[customerId] = artisanId ?? existing;

    final payload = {
      'customerId': customerId,
      if ((artisanId ?? existing ?? '').isNotEmpty)
        'artisanId': artisanId ?? existing,
    };

    developer.log(
      '[ChatRT] subscribeToDirect $customerId artisan=${payload['artisanId']} (connected=${_rt.status.value == SocketStatus.connected})',
    );
    _rt.emit(RealtimeEvents.directSubscribe, payload);
  }

  void _resubscribeTracked() {
    if (_rt.status.value != SocketStatus.connected) return;

    developer.log(
      '[ChatRT] resubscribe tracked: inbox=${_artisanInboxId ?? "-"} requests=${_requestSubscriptions.length} directs=${_directSubscriptions.length}',
    );

    // ✅ NEW: always resubscribe inbox after reconnect
    final inboxId = _artisanInboxId;
    if (inboxId != null && inboxId.isNotEmpty) {
      _rt.emit(RealtimeEvents.artisanSubscribe, {'artisanId': inboxId});
    }

    for (final id in _requestSubscriptions) {
      _rt.emit(RealtimeEvents.chatSubscribe, {'requestId': id});
    }

    _directSubscriptions.forEach((customerId, artisanId) {
      final payload = {
        'customerId': customerId,
        if (artisanId != null && artisanId.isNotEmpty) 'artisanId': artisanId,
      };
      _rt.emit(RealtimeEvents.directSubscribe, payload);
    });
  }

  void clearSubscriptions() {
    _requestSubscriptions.clear();
    _directSubscriptions.clear();
    // we keep inbox id, because it's required even when chats are empty
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

    _rt.emit(
      event,
      message,
      ack: (resp) {
        // Preserve localId so the UI can merge local -> server copy even if backend omits it.
        if (resp is Map && message['localId'] != null) {
          final localId = message['localId'];
          resp['localId'] ??= localId;
          if (resp['message'] is Map) {
            (resp['message'] as Map)['localId'] ??= localId;
          }
        }

        _markState(resp, 'sent');

        if (resp is Map && _chatController != null) {
          _chatController!.onSocketMessage(resp.cast<String, dynamic>());
        }
      },
    );
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

  void _flushReads() {
    if (_pendingReads.isEmpty) return;
    final pending = List<_PendingRead>.from(_pendingReads);
    _pendingReads.clear();
    for (final read in pending) {
      markRead(read.id, direct: read.direct);
    }
  }

  void _ensureChatController() {
    if (_chatController == null && Get.isRegistered<ChatController>(tag: 'artisan')) {
      _chatController = Get.find<ChatController>(tag: 'artisan');
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


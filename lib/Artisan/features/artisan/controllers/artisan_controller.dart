import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/request_queue.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanController extends GetxController
    implements RealtimeAwareService {
  final SocketService _socketService = Get.find<SocketService>();
  final AuthService _auth = Get.find<AuthService>();
  final RequestQueue _requestQueue = RequestQueue();
  final AppPrefs _prefs = AppPrefs();

  StreamSubscription<SocketStatus>? _statusSub;
  bool _started = false;
  bool _listenersRegistered = false;
  String? _artisanId;
  bool _joinedRooms = false;
  DateTime? _lastRefreshAt;
  bool _refreshing = false;

  @override
  bool get isStarted => _started;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _socketService.connectIfNeeded();
    _statusSub?.cancel();
    _statusSub = _socketService.statusStream.listen((status) {
      if (status == SocketStatus.connected) {
        _setupListeners();
      } else {
        _joinedRooms = false;
        _listenersRegistered = false;
        _cleanupListeners();
      }
    });
    if (_socketService.isConnected) {
      _setupListeners();
    }
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _statusSub?.cancel();
    _statusSub = null;
    _listenersRegistered = false;
    _cleanupListeners();
    _requestQueue.clear();
    _joinedRooms = false;
    _artisanId = null;
  }

  void _setupListeners() {
    if (!_started || !_socketService.isConnected) return;
    if (_listenersRegistered) return;
    _cleanupListeners();
    _joinArtisanRoom();

    _socketService.on('request:new', (data) {
      if (!_started) return;
      developer.log('[ArtisanController] Received request:new => $data');
      final normalized = _normalizePayload(data);
      if (normalized != null) {
        _requestQueue.add(normalized);
      }
    });

    _socketService.on('request:accepted', (data) {
      if (!_started) return;
      developer.log('[ArtisanController] Received request:accepted => $data');
      _refreshRequestsList();
    });

    _socketService.on('request:rejected', (data) {
      if (!_started) return;
      developer.log('[ArtisanController] Received request:rejected => $data');
      _refreshRequestsList();
    });

    _socketService.on('request:canceled', (data) {
      if (!_started) return;
      developer.log('[ArtisanController] Received request:canceled => $data');
      final normalized = _normalizePayload(data);
      final requestId =
          normalized?['requestId'] ?? normalized?['_id'] ?? normalized?['id'];
      if (requestId != null) {
        _requestQueue.remove(requestId.toString());
      }
      _refreshRequestsList();
    });

    _socketService.on('request:in_progress', (data) {});
    _socketService.on('request:awaiting_confirmation', (data) {
      if (!_started) return;
      developer.log('[ArtisanController] Received request:awaiting_confirmation => $data');
      _refreshRequestsList();
    });
    _socketService.on('request:completed', (data) {
      if (!_started) return;
      developer.log('[ArtisanController] Received request:completed => $data');
      _refreshRequestsList();
    });
    _listenersRegistered = true;
  }

  void _cleanupListeners() {
    _socketService.off('request:new');
    _socketService.off('request:accepted');
    _socketService.off('request:rejected');
    _socketService.off('request:canceled');
    _socketService.off('request:in_progress');
    _socketService.off('request:awaiting_confirmation');
    _socketService.off('request:completed');
    _listenersRegistered = false;
  }

  void _joinArtisanRoom() {
    if (_joinedRooms) return;
    try {
      final cached = _prefs.getString(kCachedProfileKey);
      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          final id = decoded['_id'] ?? decoded['id'] ?? decoded['artisanId'];
          if (id != null) {
            _artisanId = id.toString();
          }
        }
      }
      final joinId = _artisanId;
      if (joinId != null && joinId.isNotEmpty) {
        developer.log('[ArtisanController] Joining rooms for $joinId');
        _socketService.emit('join', {
          'room': 'artisan:$joinId',
          'userId': joinId,
        });
        _socketService.emit('join', {
          'room': 'user:$joinId',
          'userId': joinId,
        });
      } else {
        _socketService.emit('join', {});
      }
      _joinedRooms = true;
    } catch (e) {
      developer.log('[ArtisanController] Error joining room: $e');
    }
  }

  Map<String, dynamic>? _normalizePayload(dynamic payload) {
    if (payload is Map) {
      final data = Map<String, dynamic>.from(payload);
      if (data.containsKey('request') && data['request'] is Map) {
        return Map<String, dynamic>.from(data['request'] as Map);
      }
      if (data.containsKey('data') && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    return null;
  }

  void _refreshRequestsList() {
    if (!_auth.isAuthenticated) return;
    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!).inSeconds < 10) {
      return;
    }
    if (_refreshing) return;
    _refreshing = true;
    _lastRefreshAt = now;
    if (Get.isRegistered<ArtisanRequestsController>()) {
      final ctrl = Get.find<ArtisanRequestsController>();
      Future.wait([
        ctrl.fetchNewRequests(),
        ctrl.fetchActiveRequests(),
        ctrl.fetchHistoryRequests(),
      ]).whenComplete(() {
        _refreshing = false;
      });
    } else {
      _refreshing = false;
    }
  }

  void stopRealtimeService() {
    stop();
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}



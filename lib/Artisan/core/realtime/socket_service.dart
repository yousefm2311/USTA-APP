import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/connectivity/connectivity_service.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

enum SocketStatus { disconnected, connecting, connected }

class SocketService extends GetxService {
  final AuthService _authService = Get.find<AuthService>();
  final ConnectivityService _connectivity = Get.find<ConnectivityService>(tag: 'artisan');

  final Rx<SocketStatus> _status = SocketStatus.disconnected.obs;
  SocketStatus get status => _status.value;
  bool get isConnected => _socket?.connected == true;
  Stream<SocketStatus> get statusStream => _status.stream;

  io.Socket? _socket;
  Timer? _reconnectTimer;
  int _reconnectDelay = 1;
  bool _isConnecting = false;
  bool _handlingUnauthorized = false;
  final List<_QueuedEmit> _pending = [];
  final Map<String, List<Function(dynamic)>> _handlers = {};
  String? _currentToken;
  String? _manualTokenOverride;

  @override
  void onInit() {
    super.onInit();
    _authService.registerAccessTokenListener(_handleAccessTokenChanged);
    _authService.authenticatedStream.listen((isAuth) {
      if (isAuth) {
        connectIfNeeded();
      } else {
        _resetState();
        disconnect();
      }
    });
    if (_authService.isAuthenticated) {
      Future.microtask(connectIfNeeded);
    }
  }

  void updateAuthToken(String? token) {
    _manualTokenOverride = token;
    if (token == null || token.isEmpty) {
      _resetState();
      disconnect();
      return;
    }
    final alreadyUsingToken =
        _currentToken != null && _currentToken == token && isConnected;
    if (alreadyUsingToken) return;
    reconnect();
  }

  void _handleAccessTokenChanged(String? token) {
    if (token == null || token.isEmpty) {
      _resetState();
      disconnect();
      return;
    }
    reconnect();
  }

  String? _tokenToUse() {
    if (_manualTokenOverride != null && _manualTokenOverride!.isNotEmpty) {
      return _manualTokenOverride;
    }
    return _authService.accessToken;
  }

  void _bindHandlersForEvent(String event) {
    final socket = _socket;
    if (socket == null) return;
    final handlers = _handlers[event];
    socket.off(event);
    if (handlers == null || handlers.isEmpty) return;
    for (final handler in handlers) {
      socket.on(event, (data) {
        try {
          handler(data);
        } catch (e, stack) {
          log('[SocketService] Handler error for $event: $e', stackTrace: stack);
        }
      });
    }
  }

  void _bindAllHandlers() {
    final socket = _socket;
    if (socket == null) return;
    for (final event in _handlers.keys) {
      _bindHandlersForEvent(event);
    }
  }

  Future<void> connectIfNeeded() async {
    final token = _tokenToUse();
    if (!_authService.isAuthenticated || token == null || token.isEmpty) {
      return;
    }
    if (isConnected || _isConnecting) return;
    await connect();
  }

  Future<void> connect() async {
    final token = _tokenToUse();
    if (!_authService.isAuthenticated || token == null || token.isEmpty) {
      _status.value = SocketStatus.disconnected;
      log('[SocketService] Skip connect: no token/auth');
      return;
    }
    if (_isConnecting) return;

    final reachable = await _connectivity.verifyServerReachable(token: token);
    if (!reachable) {
      log('[SocketService] Server did not respond to reachability probe, continuing connect');
    }

    _isConnecting = true;
    _status.value = SocketStatus.connecting;

    _reconnectTimer?.cancel();
    _socket?.dispose();

    final authPayload = {'token': token};
    final uri = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    _currentToken = token;
    final builder = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .enableReconnection()
        .enableForceNew()
        .setAuth(authPayload)
        .setQuery({
          ...authPayload,
          'EIO': '4',
          'transport': 'websocket',
        })
        .setExtraHeaders({'Authorization': 'Bearer $token'});

    try {
      log('[SocketService] Connecting to $uri with token len=${token.length}');
      _socket = io.io(uri, builder.build());
      _bindAllHandlers();
      _registerListeners();
      _socket?.connect();
    } finally {
      _isConnecting = false;
    }
  }

  void _registerListeners() {
    final socket = _socket;
    socket?.off('connect');
    socket?.off('disconnect');
    socket?.off('connect_error');
    socket?.off('error');
    socket?.off('reconnect_attempt');
    try {
      // Not available in some versions; best-effort to avoid duplicate handlers.
      // ignore: avoid_dynamic_calls
      socket?.offAny();
    } catch (_) {}

    socket?.onConnect((_) {
      log('[SocketService] Connected');
      _status.value = SocketStatus.connected;
      _reconnectDelay = 1;
      _flushQueue();
    });

    socket?.onDisconnect((_) {
      log('[SocketService] Disconnected');
      _status.value = SocketStatus.disconnected;
      _scheduleReconnect();
    });

    socket?.onConnectError((data) {
      log('[SocketService] Connect error $data');
      _status.value = SocketStatus.disconnected;
      _handleSocketError(data);
      _scheduleReconnect();
    });

    socket?.onError((data) {
      log('[SocketService] Error $data');
      _handleSocketError(data, shouldReconnect: false);
    });

    socket?.on('error', (data) {
      log('[SocketService] "error" event $data');
      _handleSocketError(data, shouldReconnect: false);
    });

    socket?.on('connect_error', (data) {
      log('[SocketService] "connect_error" event $data');
      _status.value = SocketStatus.disconnected;
      _handleSocketError(data);
      _scheduleReconnect();
    });

    socket?.on('reconnect_attempt', (attempt) {
      log('[SocketService] Reconnect attempt #$attempt');
      _status.value = SocketStatus.connecting;
    });

    // Catch-all to inspect any event names the backend emits (helps align handlers).
    try {
      socket?.onAny((event, data) {
        log('[SocketService] onAny $event => $data');
      });
    } catch (_) {
      // onAny not supported; no-op.
    }
  }

  Future<void> _handleSocketError(
    dynamic data, {
    bool shouldReconnect = true,
  }) async {
    final payload = data?.toString().toLowerCase() ?? '';
    final unauthorized = payload.contains('jwt') || payload.contains('unauthorized');
    final expired = payload.contains('expired');

    if ((unauthorized || expired) && !_handlingUnauthorized) {
      _handlingUnauthorized = true;
      final refreshed = await _authService.refreshTokens();
      if (refreshed) {
        await reconnect();
      } else {
        await _authService.handleUnauthorized(skipRefresh: true, fromSocket: true);
      }
      _handlingUnauthorized = false;
      return;
    }
    if (!shouldReconnect) return;
    _status.value = SocketStatus.disconnected;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    if (!_authService.isAuthenticated) return;
    final delay = Duration(seconds: _reconnectDelay.clamp(1, 30));
    _reconnectTimer = Timer(delay, () {
      _reconnectDelay = (_reconnectDelay * 2).clamp(1, 30);
      connectIfNeeded();
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _status.value = SocketStatus.disconnected;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
    _reconnectDelay = 1;
    _currentToken = null;
  }

  Future<void> reconnect() async {
    await disconnect();
    await connectIfNeeded();
  }

  void emit(String event, dynamic data, {Function(dynamic response)? ack}) {
    if (!isConnected) {
      connectIfNeeded();
      _pending.add(_QueuedEmit(event, data, ack));
      log('[SocketService] Queued emit: $event');
      return;
    }
    if (ack != null) {
      _socket?.emitWithAck(event, data, ack: ack);
    } else {
      _socket?.emit(event, data);
    }
  }

  void on(String event, Function(dynamic) handler) {
    final list = _handlers.putIfAbsent(event, () => <Function(dynamic)>[]);
    if (!list.contains(handler)) {
      list.add(handler);
    }
    _bindHandlersForEvent(event);
  }

  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      final list = _handlers[event];
      list?.removeWhere((h) => h == handler);
      if (list != null && list.isEmpty) {
        _handlers.remove(event);
      }
    } else {
      _handlers.remove(event);
    }
    _socket?.off(event);
    if (_handlers.containsKey(event)) {
      _bindHandlersForEvent(event);
    }
  }

  void _flushQueue() {
    if (!isConnected) return;
    for (final item in _pending) {
      if (item.ack != null) {
        _socket?.emitWithAck(item.event, item.data, ack: item.ack);
      } else {
        _socket?.emit(item.event, item.data);
      }
    }
    _pending.clear();
  }

  void _resetState() {
    _pending.clear();
    _reconnectDelay = 1;
    _currentToken = null;
    _manualTokenOverride = null;
  }
}

class _QueuedEmit {
  final String event;
  final dynamic data;
  final Function(dynamic response)? ack;

  _QueuedEmit(this.event, this.data, this.ack);
}


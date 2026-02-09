import 'dart:developer';

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:usta/Customer/core/utils/constants/api_endpoints.dart';

enum SocketStatus { disconnected, connecting, connected }

class SocketManager {
  SocketManager._internal();

  static final SocketManager instance = SocketManager._internal();

  final status = SocketStatus.disconnected.obs;
  io.Socket? _socket;
  String? _authToken;
  bool _isConnecting = false;
  final List<_QueuedEmit> _pending = [];

  bool get isConnected => _socket?.connected ?? false;

  void connect({String? token}) {
    _authToken = token ?? _authToken;
    if (_isConnecting || isConnected) return;
    status.value = SocketStatus.connecting;
    _isConnecting = true;

    _socket?.dispose();
    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setReconnectionAttempts(0)
          .setTimeout(20000)
          .enableForceNew()
          .setPath('/socket.io/')
          .setExtraHeaders(_buildHeaders())
          .setAuth(_buildAuth())
          .setQuery(_buildAuthQuery())
          .build(),
    );

    _socket?.onConnecting((_) {
      status.value = SocketStatus.connecting;
      log('[SocketManager] Connecting...');
    });

    _socket?.onConnect((_) {
      status.value = SocketStatus.connected;
      _isConnecting = false;
      log('[SocketManager] Connected');
      _flushPending();
    });

    _socket?.onDisconnect((reason) {
      status.value = SocketStatus.disconnected;
      _isConnecting = false;
      log('[SocketManager] Disconnected: $reason');
    });

    _socket?.onError((error) {
      status.value = SocketStatus.disconnected;
      _isConnecting = false;
      log('[SocketManager] Error: $error');
    });

    _socket?.onConnectError((error) {
      status.value = SocketStatus.disconnected;
      _isConnecting = false;
      log('[SocketManager] Connect error: $error');
    });

    _socket?.on('reconnect_attempt', (attempt) {
      status.value = SocketStatus.connecting;
      log('[SocketManager] Reconnect attempt #$attempt');
    });

    _socket?.on('reconnect', (_) {
      status.value = SocketStatus.connected;
      log('[SocketManager] Reconnected');
    });

    _socket?.connect();
  }

  void updateAuthToken(String? token) {
    final changed = token != null && token.isNotEmpty && token != _authToken;
    _authToken = token;
    final opts = _socket?.io.options;
    if (opts != null) {
      opts['extraHeaders'] = _buildHeaders();
      opts['auth'] = _buildAuth();
      opts['query'] = _buildAuthQuery();
    }
    if (changed && isConnected) {
      reconnect();
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    status.value = SocketStatus.disconnected;
    _isConnecting = false;
  }

  void reconnect() {
    if (_authToken == null || _authToken!.isEmpty) return;
    disconnect();
    connect(token: _authToken);
  }

  void emit(String event, dynamic data, {Function(dynamic)? ack}) {
    if (!isConnected) {
      log('[SocketManager] Queueing emit while disconnected: $event');
      _pending.add(_QueuedEmit(event, data, ack));
      _connectIfNeeded();
      return;
    }
    log('[SocketManager] Emit $event -> $data');
    if (ack != null) {
      _socket?.emitWithAck(event, data, ack: ack);
    } else {
      _socket?.emit(event, data);
    }
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  Map<String, dynamic> _buildHeaders() {
    final raw = _rawToken();
    if (raw == null || raw.isEmpty) return {};
    return {'Authorization': 'Bearer $raw'};
  }

  Map<String, dynamic> _buildAuth() {
    final raw = _rawToken();
    if (raw == null || raw.isEmpty) return {};
    return {'token': raw};
  }

  Map<String, dynamic> _buildAuthQuery() {
    final raw = _rawToken();
    if (raw == null || raw.isEmpty) return {};
    return {'token': raw};
  }

  String? _rawToken() {
    if (_authToken == null || _authToken!.isEmpty) return null;
    final parts = _authToken!.trim().split(RegExp(r'\\s+'));
    if (parts.length == 2 && parts.first.toLowerCase() == 'bearer') {
      return parts[1];
    }
    return _authToken;
  }

  void _connectIfNeeded() {
    if (isConnected || _isConnecting) return;
    if (_authToken == null || _authToken!.isEmpty) return;
    connect(token: _authToken);
  }

  void _flushPending() {
    if (!isConnected || _pending.isEmpty) return;
    final items = List<_QueuedEmit>.from(_pending);
    _pending.clear();
    for (final item in items) {
      if (item.ack != null) {
        _socket?.emitWithAck(item.event, item.data, ack: item.ack);
      } else {
        _socket?.emit(item.event, item.data);
      }
    }
  }
}

class _QueuedEmit {
  final String event;
  final dynamic data;
  final Function(dynamic)? ack;

  _QueuedEmit(this.event, this.data, this.ack);
}

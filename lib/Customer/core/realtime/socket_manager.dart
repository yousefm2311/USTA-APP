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

  bool get isConnected => _socket?.connected ?? false;

  void connect({String? token}) {
    _authToken = token ?? _authToken;
    status.value = SocketStatus.connecting;

    _socket?.dispose();
    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(5)
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
      log('[SocketManager] Connected');
    });

    _socket?.onDisconnect((reason) {
      status.value = SocketStatus.disconnected;
      log('[SocketManager] Disconnected: $reason');
    });

    _socket?.onError((error) {
      status.value = SocketStatus.disconnected;
      log('[SocketManager] Error: $error');
    });

    _socket?.onConnectError((error) {
      status.value = SocketStatus.disconnected;
      log('[SocketManager] Connect error: $error');
    });
  }

  void updateAuthToken(String? token) {
    _authToken = token;
    final opts = _socket?.io.options;
    if (opts != null) {
      opts['extraHeaders'] = _buildHeaders();
      opts['auth'] = _buildAuth();
      opts['query'] = _buildAuthQuery();
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    status.value = SocketStatus.disconnected;
  }

  void emit(String event, dynamic data, {Function(dynamic)? ack}) {
    if (!isConnected) {
      log('[SocketManager] Queueing emit while disconnected: $event');
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
}


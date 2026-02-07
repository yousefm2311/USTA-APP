import 'dart:async';
import 'dart:developer' as developer;

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';

enum SocketStatus { disconnected, connecting, connected }

class SocketManager {
  SocketManager._internal();
  static final SocketManager instance = SocketManager._internal();

  final AppPrefs _prefs = AppPrefs();
  io.Socket? _socket;
  SocketStatus _status = SocketStatus.disconnected;
  final _statusController = StreamController<SocketStatus>.broadcast();
  final List<_QueuedEmit> _pending = [];
  String? _token;

  Stream<SocketStatus> get statusStream => _statusController.stream;
  SocketStatus get status => _status;
  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (_status == SocketStatus.connecting || isConnected) return;
    _token ??= _prefs.getString(kAuthTokenKey);
    if (_token == null || _token!.isEmpty) {
      // لا تحاول الاتصال بدون توكن (مستخدم غير مسجل دخول)
      developer.log('⚠️ Skip socket connect: no auth token');
      _setStatus(SocketStatus.disconnected);
      return;
    }
    _setStatus(SocketStatus.connecting);
    final uri = _buildSocketUrl();

    final builder = io.OptionBuilder()
        // Allow both websocket and polling so we stay connected in restrictive networks.
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .enableReconnection();

    if (_token != null && _token!.isNotEmpty) {
      builder.setQuery({'token': _token}).setExtraHeaders({
        'Authorization': 'Bearer $_token',
      });
    }

    _socket = io.io(uri, builder.build());
    _registerCoreListeners();
    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setStatus(SocketStatus.disconnected);
  }

  void reconnect() {
    disconnect();
    connect();
  }

  void updateAuthToken(String? token) {
    _token = token;
    // Always reconnect (or connect) with the new token to join proper rooms.
    reconnect();
  }

  void on(String event, Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [Function(dynamic data)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  void emit(String event, dynamic data, {Function(dynamic response)? ack}) {
    if (!isConnected) {
      // Auto reconnect when emit is requested and socket is down.
      connect();
      developer.log('📤 Queued: $event (not connected yet)');
      _pending.add(_QueuedEmit(event, data, ack));
      return;
    }
    developer.log('📤 Emitting: $event with data: $data');
    if (ack != null) {
      _socket?.emitWithAck(event, data, ack: ack);
    } else {
      _socket?.emit(event, data);
    }
  }

  void _registerCoreListeners() {
    _socket?.onConnect((_) {
      developer.log('✅ Socket connected');
      _setStatus(SocketStatus.connected);
      _flushQueue();
    });

    _socket?.onDisconnect((_) {
      developer.log('❌ Socket disconnected');
      _setStatus(SocketStatus.disconnected);
    });

    _socket?.onError((data) {
      developer.log('⚠️ Socket error: $data');
      _setStatus(SocketStatus.disconnected);
    });

    _socket?.onConnectError((data) {
      developer.log('⚠️ Socket connect error: $data');
      _setStatus(SocketStatus.disconnected);
    });
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

  void _setStatus(SocketStatus value) {
    _status = value;
    _statusController.add(value);
  }

  String _buildSocketUrl() {
    // استخدام نفس الدومين الخاص بالـ REST لكن بدون لاحقة /api
    final base = ApiEndpoints.baseUrl;
    final withoutApi = base.replaceFirst(RegExp(r'/api/?$'), '');
    return withoutApi.isNotEmpty && withoutApi.endsWith('/')
        ? withoutApi.substring(0, withoutApi.length - 1)
        : withoutApi;
  }
}

class _QueuedEmit {
  final String event;
  final dynamic data;
  final Function(dynamic response)? ack;

  _QueuedEmit(this.event, this.data, this.ack);
}


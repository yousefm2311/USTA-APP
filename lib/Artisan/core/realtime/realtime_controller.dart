import 'dart:async';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';

class RealtimeController extends GetxController {
  final SocketService _socket = Get.find<SocketService>();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<SocketStatus> status = SocketStatus.disconnected.obs;
  final RxBool waitingForConnection = false.obs;
  bool _connectInFlight = false;
  StreamSubscription<SocketStatus>? _statusSub;
  StreamSubscription<bool>? _authSub;

  @override
  void onInit() {
    super.onInit();
    status.value = _socket.status;
    waitingForConnection.value = status.value != SocketStatus.connected;
    _statusSub = _socket.statusStream.listen((value) {
      status.value = value;
      waitingForConnection.value = value != SocketStatus.connected;
    });
    _authSub = _authService.authenticatedStream.listen((isAuth) {
      if (isAuth) {
        Future.microtask(() => connectIfNeeded());
      } else {
        disconnect();
      }
    });
    _secureInit();
  }

  Future<void> _secureInit() async {
    await _authService.waitForAuthentication();
    if (!_authService.isAuthenticated) {
      return;
    }
    await connectIfNeeded();
  }

  Future<void> connectIfNeeded() async {
    if (_connectInFlight) return;
    _connectInFlight = true;
    try {
      /// Don't connect unless JWT is valid
      if (!_authService.isAuthenticated) {
        _connectInFlight = false;
        return;
      }
      final token = _authService.accessToken;
      if (token == null || token.isEmpty) {
        _connectInFlight = false;
        return;
      }
      _socket.updateAuthToken(token);
      await _socket.connectIfNeeded();
    } finally {
      _connectInFlight = false;
    }
  }

  void setAuthToken(String? token) {
    _socket.updateAuthToken(token);
  }

  void emit(String event, dynamic data, {Function(dynamic response)? ack}) {
    _socket.emit(event, data, ack: ack);
  }

  void onEvent(String event, Function(dynamic data) handler) {
    _socket.on(event, handler);
  }

  void offEvent(String event, [Function(dynamic data)? handler]) {
    _socket.off(event, handler);
  }


  Future<void> reconnect() async {
    await disconnect();
    await connectIfNeeded();
  }

  Future<void> disconnect() async {
    await _socket.disconnect();
  }
  @override
  void onClose() {
    _statusSub?.cancel();
    _authSub?.cancel();
    super.onClose();
  }
}


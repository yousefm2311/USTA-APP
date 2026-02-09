import 'package:get/get.dart';
import 'package:usta/Customer/core/realtime/events.dart';
import 'package:usta/Customer/core/realtime/socket_manager.dart';
import 'package:usta/Customer/core/services/token_storage.dart';

class RealtimeController extends GetxService {
  final SocketManager _socket = SocketManager.instance;
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  Rx<SocketStatus> get status => _socket.status;

  @override
  void onInit() {
    super.onInit();
    _connect();
  }

  void _connect() {
    final token = _storage.accessToken;
    if (token == null || token.isEmpty) {
      _socket.disconnect();
      return;
    }
    _socket.connect(token: token);
  }

  void connectIfNeeded() {
    final token = _storage.accessToken;
    if (token == null || token.isEmpty) {
      _socket.disconnect();
      return;
    }
    _socket.updateAuthToken(token);
    if (status.value == SocketStatus.connected ||
        status.value == SocketStatus.connecting) {
      return;
    }
    _socket.connect(token: token);
  }

  void reconnect() {
    final token = _storage.accessToken;
    if (token == null || token.isEmpty) {
      _socket.disconnect();
      return;
    }
    _socket.updateAuthToken(token);
    _socket.reconnect();
  }

  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _socket.disconnect();
      return;
    }
    _socket.updateAuthToken(token);
    if (!_socket.isConnected) _socket.connect(token: token);
  }

  void disconnect() => SocketManager.instance.disconnect();

  void joinCustomerRoom(String customerId) {
    if (customerId.isEmpty) return;
    emit('join', {
      'room': 'customer:$customerId',
      'userId': customerId,
    });
  }


  void subscribeChat(String requestId) {
    emit(RealtimeEvents.chatSubscribe, {'requestId': requestId});
  }

  void sendChatMessage(Map<String, dynamic> payload) {
    emit(RealtimeEvents.chatMessage, payload);
  }

  void markChatRead(String messageId) {
    emit(RealtimeEvents.chatRead, {'messageId': messageId});
  }

  void subscribeDirect(String customerId) {
    emit(RealtimeEvents.directSubscribe, {'customerId': customerId});
  }

  void markDirectRead(String messageId) {
    emit(RealtimeEvents.directRead, {'messageId': messageId});
  }

  void emit(String event, dynamic data, {Function(dynamic)? ack}) {
    _socket.emit(event, data, ack: ack);
  }

  void onEvent(String event, Function(dynamic) handler) {
    _socket.on(event, handler);
  }

  void offEvent(String event, [Function(dynamic)? handler]) {
    _socket.off(event, handler);
  }

  void listenRequestEvents({
    Function(dynamic)? onNew,
    Function(dynamic)? onAccepted,
    Function(dynamic)? onRejected,
    Function(dynamic)? onCancelled,
    Function(dynamic)? onUpdated,
  }) {
    if (onNew != null) onEvent(RealtimeEvents.requestNew, onNew);
    if (onAccepted != null) {
      onEvent(RealtimeEvents.requestAccepted, onAccepted);
    }
    if (onRejected != null) {
      onEvent(RealtimeEvents.requestRejected, onRejected);
    }
    if (onCancelled != null) {
      onEvent(RealtimeEvents.requestCancelled, onCancelled);
    }
    if (onUpdated != null) {
      onEvent(RealtimeEvents.requestUpdated, onUpdated);
    }
  }
}

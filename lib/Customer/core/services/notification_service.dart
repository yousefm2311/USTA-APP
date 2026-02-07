import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';


class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';
  static const _channelDescription = 'Used for important notifications.';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _initLocal();
    await _createAndroidChannel();
    await _setupInterceptors();
    await _handleInitialMessage();
    await _logFcmToken();
  }

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) =>
          _onLocalSelect(details.payload),
    );
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('custom_sound'),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _setupInterceptors() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    _fcm.onTokenRefresh.listen(_handleTokenRefresh);
  }

  Future<void> _handleInitialMessage() async {
    final msg = await _fcm.getInitialMessage();
    if (msg != null) _handleMessage(msg);
  }

  Future<void> _handleTokenRefresh(String token) async {
    await sendTokenToBackend(token);
  }

  Future<void> sendTokenToBackend(String token) async {
    if (Get.isRegistered<CustomerNotificationsController>()) {
      await Get.find<CustomerNotificationsController>()
          .ensureRegisteredFcm(token);
      return;
    }
    if (kDebugMode) debugPrint('FCM token (not sent, controller missing): $token');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notif = message.notification;
    final title = notif?.title ?? message.data['title'] ?? 'إشعار جديد'.tr;
    final body = notif?.body ?? message.data['body'] ?? '';
    final safeData =
        message.data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final payload = jsonEncode(safeData);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('custom_sound'),
    );
    const iosDetails = DarwinNotificationDetails(sound: 'custom_sound.caf');
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    _navigateFromData(data);
  }

  void _onLocalSelect(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final map = (jsonDecode(payload) as Map).map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      _navigateFromData(map);
    } catch (e) {
      debugPrint('Failed to parse notification payload: $e');
    }
  }

  void _navigateFromData(Map<String, String> data) {
    final route = data['route'] ?? '';
    final id =
        data['id']?.toString() ?? data['chatId']?.toString() ?? '';

    if (route.isEmpty) {
      debugPrint('Notification route missing; ignoring.');
      return;
    }

    if (route == '/product_details' && id.isNotEmpty) {
      // Get.to(() => ProductDetailsPage(id: id));
      return;
    }

    if (route == '/chat' && id.isNotEmpty) {
      // Get.to(() => ChatPage(chatId: id));
      return;
    }

    debugPrint('Notification route not recognized: $route');
    Get.toNamed(route, arguments: {'id': id});
  }

  Future<void> _logFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('FCM token unavailable yet.');
        return;
      }
      if (kDebugMode) debugPrint('FCM token: $token');
      await sendTokenToBackend(token);
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get FCM token: ${e.code} ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to get FCM token: $e');
    }
  }
}


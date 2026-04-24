import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/notification_navigation.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';
import 'package:usta/Customer/firebase_options.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_list_view.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_room_view.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';
import 'package:usta/Customer/features/customer/payments/views/customer_payment_receipt_view.dart';
import 'package:usta/Customer/features/customer/payments/views/customer_payments_history_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_active_requests_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_request_details_view.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_wallet_view.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';
  static const _channelDescription = 'Used for important notifications.';
  static const _tokenTimeout = Duration(seconds: 8);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService Firebase init failed: $e');
        }
        return;
      }
    }
    try {
      final supported = await _fcm.isSupported();
      if (!supported) {
        _initialized = true;
        return;
      }
    } catch (_) {}

    await _requestPermission();
    await _initLocal();
    await _createAndroidChannel();
    await _setupInterceptors();
    await _handleInitialMessage();
    await _logFcmToken();

    _initialized = true;
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
          AndroidFlutterLocalNotificationsPlugin
        >()
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
          AndroidFlutterLocalNotificationsPlugin
        >()
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
      await Get.find<CustomerNotificationsController>().ensureRegisteredFcm(
        token,
      );
      return;
    }
    if (kDebugMode)
      debugPrint('FCM token (not sent, controller missing): $token');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notif = message.notification;
    final title = notif?.title ?? message.data['title'] ?? 'إشعار جديد'.tr;
    final body = notif?.body ?? message.data['body'] ?? '';
    final safeData = message.data.map(
      (k, v) => MapEntry(k, v?.toString() ?? ''),
    );
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
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
    final destination = resolveCustomerNotificationDestination(data);

    switch (destination.kind) {
      case CustomerNotificationDestinationKind.chat:
        final chatTitle = destination.title.isNotEmpty
            ? destination.title
            : 'محادثة'.tr;
        if (destination.isDirect && destination.artisanId.isNotEmpty) {
          Get.to(
            () => CustomerChatRoomView(
              requestId: '',
              customerId: destination.artisanId,
              customerName: chatTitle,
              isDirect: true,
            ),
          );
          return;
        }
        if (destination.requestId.isNotEmpty) {
          Get.to(
            () => CustomerChatRoomView(
              requestId: destination.requestId,
              customerName: chatTitle,
            ),
          );
          return;
        }
        Get.to(() => const CustomerChatListView());
        return;
      case CustomerNotificationDestinationKind.request:
        if (destination.requestId.isNotEmpty) {
          Get.to(
            () => CustomerRequestDetailsView(requestId: destination.requestId),
          );
          return;
        }
        Get.to(() => const CustomerActiveRequestsView());
        return;
      case CustomerNotificationDestinationKind.payment:
        if (destination.paymentId.isNotEmpty) {
          Get.to(
            () => CustomerPaymentReceiptView(paymentId: destination.paymentId),
          );
          return;
        }
        Get.to(() => CustomerPaymentsHistoryView());
        return;
      case CustomerNotificationDestinationKind.wallet:
        Get.to(() => CustomerWalletView());
        return;
      case CustomerNotificationDestinationKind.namedRoute:
        Get.toNamed(
          destination.route,
          arguments: {'id': destination.id, 'data': data},
        );
        return;
      case CustomerNotificationDestinationKind.unknown:
        final rawRoute =
            data['route'] ??
            data['screen'] ??
            data['path'] ??
            data['deepLink'] ??
            '';
        if (rawRoute == AppRoutes.customerBottomNaviBar ||
            rawRoute == AppRoutes.customerHomeView) {
          Get.toNamed(
            rawRoute,
            arguments: {'id': destination.id, 'data': data},
          );
          return;
        }
        debugPrint('Notification route not recognized: $rawRoute');
        return;
    }
  }

  Future<void> _logFcmToken() async {
    try {
      final cached = _readCachedToken();
      if (cached != null && cached.isNotEmpty) {
        await sendTokenToBackend(cached);
        return;
      }
      final supported = await _fcm.isSupported();
      if (!supported) return;
      final token = await _fcm.getToken().timeout(_tokenTimeout);
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
    } on TimeoutException {
      if (kDebugMode) debugPrint('FCM getToken timed out.');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to get FCM token: $e');
    }
  }

  String? _readCachedToken() {
    if (!Get.isRegistered<TokenStorage>(tag: 'customer')) return null;
    return Get.find<TokenStorage>(tag: 'customer').fcmToken;
  }
}

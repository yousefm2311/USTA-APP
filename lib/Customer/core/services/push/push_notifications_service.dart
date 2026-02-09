import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/firebase_options.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/data/providers/customer_api.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';

class PushNotificationsService extends GetxService {
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');
  CustomerNotificationsController get _notifications =>
      Get.isRegistered<CustomerNotificationsController>()
          ? Get.find<CustomerNotificationsController>()
          : _ensureNotificationController();

  bool _initialized = false;
  static const Duration _tokenTimeout = Duration(seconds: 8);

  Future<PushNotificationsService> init() async {
    if (_initialized) return this;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Firebase init failed (is google-services.json/plist added?): $e');
      return this;
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    try {
      final supported = await messaging.isSupported();
      if (!supported) {
        _initialized = true;
        return this;
      }
    } catch (_) {}
    try {
      await messaging.requestPermission();
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }
    String? token;
    try {
      token = await messaging.getToken().timeout(_tokenTimeout);
    } on TimeoutException {
      debugPrint('FCM getToken timed out; will retry on refresh.');
    } catch (e) {
      debugPrint('FCM getToken failed (non-fatal): $e');
    }
    if (token != null && token.isNotEmpty) {
      await _persistAndRegister(token);
    }
    messaging.onTokenRefresh.listen((newToken) {
      _persistAndRegister(newToken);
    });
    _initialized = true;
    return this;
  }

  Future<void> refreshTokenRegistration() async {
    final messaging = FirebaseMessaging.instance;
    String? token;
    try {
      token = await messaging.getToken().timeout(_tokenTimeout);
    } on TimeoutException {
      debugPrint('FCM getToken timed out while refreshing token.');
    } catch (e) {
      debugPrint('FCM getToken failed (non-fatal): $e');
    }
    if (token != null && token.isNotEmpty) {
      await _persistAndRegister(token);
    }
  }

  Future<void> _persistAndRegister(String token) async {
    await _storage.saveFcmToken(token);
    await _notifications.ensureRegisteredFcm(token);
  }

  CustomerNotificationsController _ensureNotificationController() {
    if (!Get.isRegistered<CustomerApi>()) {
      Get.put(CustomerApi(), permanent: true);
    }
    if (!Get.isRegistered<CustomerRepository>()) {
      Get.put(CustomerRepository(), permanent: true);
    }
    return Get.put(CustomerNotificationsController(), permanent: true);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
  }
}

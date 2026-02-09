import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/device_id_service.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerNotificationsController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');
  final DeviceIdService _deviceIdService = Get.find<DeviceIdService>();

  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxBool loading = false.obs;
  final RxBool registeringToken = false.obs;
  String? fcmToken;

  int get unreadCount =>
      notifications.where((n) => !_isRead(n)).length;

  @override
  void onInit() {
    super.onInit();
    fcmToken = _storage.fcmToken;
    final access = _storage.accessToken;
    if (access != null && access.isNotEmpty) {
      fetchNotifications();
      ensureRegisteredFcm();
    } else {
      ensureRegisteredFcm();
    }
  }

  Future<void> fetchNotifications({bool force = false}) async {
    final access = _storage.accessToken;
    if (access == null || access.isEmpty) {
      loading.value = false;
      return;
    }
    if (force) notifications.clear();
    loading.value = true;
    try {
      final response = await _repo.api.notifications();
      List<dynamic> list = [];
      if (response['notifications'] is List) {
        list = response['notifications'] as List<dynamic>;
      } else if (response['data'] is List) {
        list = response['data'] as List<dynamic>;
      } else if (response['data'] is Map &&
          (response['data'] as Map)['notifications'] is List) {
        list = (response['data'] as Map)['notifications'] as List<dynamic>;
      } else if (response['items'] is List) {
        list = response['items'] as List<dynamic>;
      }
      notifications.assignAll(list
          .map<Map<String, dynamic>>((e) => e is Map<String, dynamic> ? e : {})
          .toList());
    } on ApiException catch (e) {
      if (e.statusCode == 401 &&
          Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      _notify(e.message, isError: true);
    } catch (_) {
      _notify('فشل تحميل الإشعارات'.tr, isError: true);
    } finally {
      loading.value = false;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repo.api.markNotificationRead(id);
      final idx = notifications.indexWhere(
          (n) => (n['_id'] ?? n['id']).toString() == id.toString());
      if (idx >= 0) {
        notifications[idx] = {...notifications[idx], 'read': true};
        notifications.refresh();
      }
    } on ApiException catch (e) {
      _notify(e.message, isError: true);
    } catch (_) {
      _notify('فشل قراءة الإشعار'.tr, isError: true);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _repo.api.deleteNotification(id);
      notifications.removeWhere(
          (n) => (n['_id'] ?? n['id']).toString() == id.toString());
    } on ApiException catch (e) {
      _notify(e.message, isError: true);
    } catch (_) {
      _notify('فشل حذف الإشعار'.tr, isError: true);
    }
  }

  Future<void> registerFcmToken(String token, {bool silent = false}) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty || trimmed.length < 10) {
      if (!silent) _notify('رمز FCM غير صالح'.tr, isError: true);
      return;
    }
    fcmToken = trimmed;
    registeringToken.value = true;
    try {
      final deviceId = await _deviceIdService.getOrCreateDeviceId();
      await _repo.api.saveFcmToken(token: trimmed, deviceId: deviceId);
      await _subscribeCoreTopics(deviceId);
      await _storage.saveFcmToken(trimmed);
      if (!silent) _notify('تم حفظ رمز التنبيهات بنجاح'.tr);
    } on ApiException catch (e) {
      if (!silent) _notify(e.message, isError: true);
    } catch (_) {
      if (!silent) _notify('فشل حفظ رمز التنبيهات'.tr, isError: true);
    } finally {
      registeringToken.value = false;
    }
  }

  Future<void> ensureRegisteredFcm([String? token]) async {
    final toUse = token ?? fcmToken ?? _storage.fcmToken;
    if (toUse == null || toUse.isEmpty) return;
    final access = _storage.accessToken;
    if (access == null || access.isEmpty) {
      await _storage.saveFcmToken(toUse);
      fcmToken = toUse;
      return;
    }
    await registerFcmToken(toUse, silent: true);
  }

  Future<bool> subscribeTopic(String topic, {bool silent = false}) async {
    final normalized = _normalizeTopic(topic);
    if (normalized == null) {
      if (!silent) {
        _notify(
          'Topic must be lowercase letters, numbers, and underscore only.',
          isError: true,
        );
      }
      return false;
    }
    try {
      final deviceId = await _deviceIdService.getOrCreateDeviceId();
      await _repo.api.subscribeTopic(topic: normalized, deviceId: deviceId);
      if (!silent) _notify('Subscribed to $normalized');
      return true;
    } on ApiException catch (e) {
      if (!silent) _notify(e.message, isError: true);
    } catch (_) {
      if (!silent) _notify('Failed to subscribe to topic.', isError: true);
    }
    return false;
  }

  Future<bool> unsubscribeTopic(String topic, {bool silent = false}) async {
    final normalized = _normalizeTopic(topic);
    if (normalized == null) {
      if (!silent) {
        _notify(
          'Topic must be lowercase letters, numbers, and underscore only.',
          isError: true,
        );
      }
      return false;
    }
    try {
      final deviceId = await _deviceIdService.getOrCreateDeviceId();
      await _repo.api.unsubscribeTopic(topic: normalized, deviceId: deviceId);
      if (!silent) _notify('Unsubscribed from $normalized');
      return true;
    } on ApiException catch (e) {
      if (!silent) _notify(e.message, isError: true);
    } catch (_) {
      if (!silent) _notify('Failed to unsubscribe from topic.', isError: true);
    }
    return false;
  }

  String? _normalizeTopic(String topic) {
    final normalized = topic.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final valid = RegExp(r'^[a-z0-9_]+$');
    if (!valid.hasMatch(normalized)) return null;
    return normalized;
  }

  Future<void> _subscribeCoreTopics(String deviceId) async {
    const coreTopics = ['all', 'role_customers'];
    for (final topic in coreTopics) {
      try {
        await _repo.api.subscribeTopic(topic: topic, deviceId: deviceId);
      } catch (_) {
      }
    }
  }

  void setLocalFcmToken(String token) {
    fcmToken = token;
    _storage.saveFcmToken(token);
  }

  void _notify(String message, {bool isError = false}) {
    if (Get.context == null) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  bool _isRead(Map<String, dynamic> n) {
    final v = n['read'] ?? n['isRead'] ?? n['seen'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 'read';
    }
    return false;
  }
}


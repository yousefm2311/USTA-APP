import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class NotificationsController extends GetxController {
  final ArtisanApi _api = ArtisanApi();
  final AppPrefs _prefs = AppPrefs();

  final RxBool loading = false.obs;
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> settings = <String, dynamic>{}.obs;
  final Set<String> _dismissedIds = {};
  bool _dismissedLoaded = false;
  static const String _dismissedKey = 'dismissed_notifications';

  Future<void> _ensureDismissedLoaded() async {
    if (_dismissedLoaded) return;
    await _prefs.init();
    final stored = _prefs.getStringList(_dismissedKey);
    if (stored != null) _dismissedIds.addAll(stored);
    _dismissedLoaded = true;
  }

  Future<void> _persistDismissed() async {
    if (!_dismissedLoaded) return;
    await _prefs.setStringList(_dismissedKey, _dismissedIds.toList());
  }

  Future<void> fetchNotifications() async {
    loading.value = true;
    try {
      await _ensureDismissedLoaded();
      final response = await _api.notifications();
      final data = ApiClient.instance.unwrapData(response);
      final list = _extractList(data);
      notifications.assignAll(
        list
            .map((e) => (e as Map?)?.cast<String, dynamic>() ?? {})
            .where((item) {
              final id =
                  (item['id'] ?? item['_id'] ?? item['notificationId'] ?? '')
                      .toString();
              return !_dismissedIds.contains(id);
            })
            .toList(),
      );
    } catch (_) {
      _showSnack(AppStrings.notificationsLoadFailed.tr, isError: true);
    } finally {
      loading.value = false;
    }
  }

  Future<void> markAsRead(String id, {bool addToDismissed = false}) async {
    try {
      await _api.markNotificationRead(id);
      final idx =
          notifications.indexWhere((element) => (element['id'] ?? element['_id']).toString() == id);
      if (idx != -1) {
        notifications[idx] = {...notifications[idx], 'read': true, 'isRead': true};
      }
      if (addToDismissed && id.isNotEmpty) {
        _dismissedIds.add(id);
        await _persistDismissed();
      }
    } catch (_) {
      _showSnack(AppStrings.notificationMarkReadFailed.tr, isError: true);
    }
  }

  /// Removes locally and marks as read server-side so it won't come back.
  Future<void> dismissNotification(Map<String, dynamic> notification) async {
    final id = (notification['id'] ?? notification['_id'] ?? notification['notificationId'])?.toString() ?? '';
    notifications.remove(notification);
    if (id.isNotEmpty) {
      _dismissedIds.add(id);
      await _persistDismissed();
      await markAsRead(id);
    }
  }

  Future<void> updateSettings(Map<String, dynamic> payload) async {
    try {
      await _api.updateNotificationSettings(payload);
      settings.assignAll({...settings, ...payload});
      _showSnack(AppStrings.notificationSettingsUpdated.tr, isError: false);
    } catch (_) {
      _showSnack(AppStrings.notificationSettingsFailed.tr, isError: true);
    }
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    try {
      final response = await _api.notificationsSettings();
      final data = ApiClient.instance.unwrapData(response);
      Map<String, dynamic> parsed = {};
      if (data is Map<String, dynamic>) {
        if (data['notifications'] is Map<String, dynamic>) {
          parsed = data['notifications'] as Map<String, dynamic>;
        } else if (data['settings'] is Map<String, dynamic>) {
          parsed = data['settings'] as Map<String, dynamic>;
        } else {
          parsed = data;
        }
      }
      if (parsed.isEmpty && settings.isNotEmpty) return settings;
      settings.assignAll(parsed);
      return parsed;
    } catch (_) {
      _showSnack(
        AppStrings.notificationSettingsLoadFailed.tr,
        isError: true,
      );
      return settings;
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['notifications'] is List) return data['notifications'] as List;
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  void _showSnack(String message, {bool isError = false}) {
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      message,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }
}


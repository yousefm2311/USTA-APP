import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';
import 'package:usta/Artisan/features/artisan/profile/controllers/profile_controller.dart';

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
      final normalized = _normalizeSettings(payload);
      await _api.updateNotificationSettings(normalized);
      settings.assignAll({...settings, ...normalized});
      _syncProfileSettings(normalized);
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
      parsed = _extractSettings(response);
      if (parsed.isEmpty) parsed = _extractSettings(data);
      if (parsed.isEmpty && response is Map<String, dynamic>) {
        parsed = _extractSettings(response['data']);
      }
      if (parsed.isEmpty) {
        parsed = _extractSettingsFromProfile();
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

  Map<String, dynamic> _extractSettings(dynamic source) {
    if (source == null) return {};
    if (source is Map<String, dynamic>) {
      if (source['notifications'] is Map) {
        return _mapFrom(source['notifications']);
      }
      if (source['notificationSettings'] is Map) {
        return _mapFrom(source['notificationSettings']);
      }
      if (source['settings'] is Map) {
        return _mapFrom(source['settings']);
      }
      if (source['preferences'] is Map) {
        return _mapFrom(source['preferences']);
      }
      if (source['prefs'] is Map) {
        return _mapFrom(source['prefs']);
      }
      if (_looksLikeSettings(source)) {
        return _mapFrom(source);
      }
    }
    if (source is Map) {
      return _extractSettings(source.cast<String, dynamic>());
    }
    return {};
  }

  Map<String, dynamic> _extractSettingsFromProfile() {
    if (!Get.isRegistered<ProfileController>()) return {};
    final profile = Get.find<ProfileController>().profile;
    if (profile.isEmpty) return {};
    final fromProfile = _extractSettings(profile);
    if (fromProfile.isNotEmpty) return fromProfile;
    if (profile['notifications'] is Map) {
      return _mapFrom(profile['notifications']);
    }
    if (profile['notificationSettings'] is Map) {
      return _mapFrom(profile['notificationSettings']);
    }
    return {};
  }

  Map<String, dynamic> _mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  bool _looksLikeSettings(Map<String, dynamic> map) {
    if (map.containsKey('marketing') ||
        map.containsKey('requests') ||
        map.containsKey('chat')) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> _normalizeSettings(Map<String, dynamic> payload) {
    final out = <String, dynamic>{};
    for (final entry in payload.entries) {
      out[entry.key] = _toBool(entry.value);
    }
    return out;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return false;
  }

  void _syncProfileSettings(Map<String, dynamic> next) {
    if (!Get.isRegistered<ProfileController>()) return;
    final controller = Get.find<ProfileController>();
    final profile = controller.profile;
    if (profile.isEmpty) return;
    final notif = _mapFrom(profile['notifications']);
    notif.addAll(next);
    profile['notifications'] = notif;
    controller.profile.refresh();
  }

  void _showSnack(String message, {bool isError = false}) {
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      message,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }
}

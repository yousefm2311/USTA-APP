import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/settings/local_controller.dart';
import 'package:usta/Customer/core/services/settings/theme_controller.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/app/app_mode_controller.dart';

class CustomerProfileController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');
  final LocaleController _localeController = Get.find<LocaleController>(tag: 'customer');
  final ThemeController _themeController = Get.find<ThemeController>(tag: 'customer');

  final CustomerNotificationsController _notificationsController =
      Get.isRegistered<CustomerNotificationsController>()
      ? Get.find<CustomerNotificationsController>()
      : Get.put(CustomerNotificationsController(), permanent: true);

  final Rxn<Map<String, dynamic>> profile = Rxn<Map<String, dynamic>>();
  final RxBool online = false.obs;
  final Rxn<DateTime> unavailableUntil = Rxn<DateTime>();
  final RxList<Map<String, dynamic>> availabilitySlots =
      <Map<String, dynamic>>[].obs;

  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxBool updatingSettings = false.obs;
  final RxBool refreshing = false.obs;

  bool _profileLoaded = false;
  bool _settingsLoaded = false;

  bool _isCustomerModeActive() {
    if (!Get.isRegistered<AppModeController>()) return true;
    final controller = AppModeController.to;
    if (controller.isBootstrapping.value) return false;
    return controller.mode.value == AppUserType.customer;
  }

  @override
  void onInit() {
    super.onInit();

    if (!_settingsLoaded) {
      _loadRemoteSettings();
    }

    if (!_profileLoaded) {
      refreshProfile();
    }
  }

  Future<void> refreshProfile({
    bool showLoader = true,
    bool force = false,
  }) async {
    if (refreshing.value) return;
    if (_profileLoaded && !force) return;

    refreshing.value = true;
    if (showLoader) loading.value = true;

    try {
      final results = await Future.wait([
        _repo.api.me(),
        _repo.api.getProfile(),
      ]);

      final me = _extractProfile(results[0]);
      final prof = _extractProfile(results[1]);

      final merged = <String, dynamic>{};
      if (prof != null) merged.addAll(prof);
      if (me != null) merged.addAll(me);

      if (merged.isNotEmpty) {
        profile.value = merged;
        _profileLoaded = true;
      }

      Map<String, dynamic>? onlineRes;
      try {
        onlineRes = await _repo.api.getOnlineStatus();
      } catch (_) {}

      _syncOnline(onlineRes);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      } else {
        _showSnack(e.message, Colors.redAccent);
      }
    } finally {
      refreshing.value = false;
      if (showLoader) loading.value = false;
    }
  }

  Map<String, dynamic>? _extractProfile(Map<String, dynamic> res) {
    final direct = res['profile'] ?? res['customer'];
    if (direct is Map<String, dynamic>) return direct;

    final data = res['data'];
    if (data is Map<String, dynamic>) {
      if (data['profile'] is Map<String, dynamic>) {
        return data['profile'];
      }
      if (data['customer'] is Map<String, dynamic>) {
        return data['customer'];
      }
      return data;
    }
    return res;
  }
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? address,
  }) async {
    String? _normalize(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    }

    final normalizedName = _normalize(name);
    final normalizedPhone = _normalize(phone);
    final normalizedEmail = _normalize(email);
    final normalizedAddress = _normalize(address);

    if (address != null && normalizedAddress == null) {
      _showSnack('الرجاء إدخال العنوان'.tr, Colors.redAccent);
      return false;
    }

    saving.value = true;
    try {
      await _repo.api.updateProfile(
        name: normalizedName,
        phone: normalizedPhone,
        email: normalizedEmail,
        address: normalizedAddress,
      );

      await _repo.api.updateMe(
        name: normalizedName,
        phone: normalizedPhone,
        email: normalizedEmail,
        address: normalizedAddress,
      );

      final merged = Map<String, dynamic>.from(profile.value ?? {});
      if (normalizedName != null) merged['name'] = normalizedName;
      if (normalizedPhone != null) merged['phone'] = normalizedPhone;
      if (normalizedEmail != null) merged['email'] = normalizedEmail;
      if (normalizedAddress != null) merged['address'] = normalizedAddress;
      profile.value = merged;

      await refreshProfile(showLoader: false, force: true);

      if (_notificationsController.fcmToken?.isNotEmpty == true) {
        await _notificationsController.registerFcmToken(
          _notificationsController.fcmToken!,
        );
      }

      _showSnack('تم تحديث بياناتك بنجاح'.tr);
      return true;
    } on ApiException catch (e) {
      _handleApiError(e);
      return false;
    } finally {
      saving.value = false;
    }
  }
  Future<bool> changePassword({
    required String current,
    required String next,
  }) async {
    updatingSettings.value = true;
    try {
      await _repo.api.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      _showSnack('تم تغيير كلمة المرور بنجاح'.tr);
      return true;
    } on ApiException catch (e) {
      _showSnack(e.message, Colors.redAccent);
      return false;
    } finally {
      updatingSettings.value = false;
    }
  }
  Future<void> setLanguage(String lang) async {
    updatingSettings.value = true;
    try {
      await _repo.api.setLanguage(lang);
      await _localeController.changeLocale(Locale(lang));

      final data = Map<String, dynamic>.from(profile.value ?? {});
      data['language'] = lang;
      profile.value = data;
    } finally {
      updatingSettings.value = false;
    }
  }

  Future<void> setTheme(String theme) async {
    updatingSettings.value = true;
    try {
      await _repo.api.setTheme(theme);
      await _themeController.setThemeMode(theme);

      final data = Map<String, dynamic>.from(profile.value ?? {});
      data['theme'] = theme;
      profile.value = data;
    } finally {
      updatingSettings.value = false;
    }
  }

  Future<void> updateNotificationSettings({
    bool? marketing,
    bool? requests,
    bool? chat,
  }) async {
    updatingSettings.value = true;
    try {
      await _repo.api.updateNotificationSettings(
        marketing: marketing,
        requests: requests,
        chat: chat,
      );

      final data = Map<String, dynamic>.from(profile.value ?? {});
      final notif = Map<String, dynamic>.from(data['notifications'] ?? {});
      if (marketing != null) notif['marketing'] = marketing;
      if (requests != null) notif['requests'] = requests;
      if (chat != null) notif['chat'] = chat;
      data['notifications'] = notif;
      profile.value = data;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
      _showSnack(e.message, Colors.redAccent);
    } finally {
      updatingSettings.value = false;
    }
  }
  Future<bool> uploadPhoto(String photoBase64) async {
    saving.value = true;
    try {
      final res = await _repo.api.uploadPhoto(photoBase64);
      final data = _extractProfile(res);
      if (data != null) profile.value = data;

      await refreshProfile(showLoader: false, force: true);
      return true;
    } on ApiException catch (e) {
      _showSnack(e.message, Colors.redAccent);
      return false;
    } finally {
      saving.value = false;
    }
  }
  Future<void> setOnlineStatus({bool? onlineStatus, DateTime? until}) async {
    updatingSettings.value = true;

    if (onlineStatus != null) online.value = onlineStatus;
    unavailableUntil.value = until;

    try {
      final res = await _repo.api.setOnline(
        online: onlineStatus,
        unavailableUntil: until?.toUtc().toIso8601String(),
      );
      _syncOnline(res);
    } on ApiException catch (e) {
      await refreshProfile(showLoader: false, force: true);
      _showSnack(e.message, Colors.redAccent);
    } finally {
      updatingSettings.value = false;
    }
  }

  Future<void> setAvailability(List<Map<String, dynamic>> slots) async {
    updatingSettings.value = true;
    availabilitySlots.assignAll(slots);

    try {
      await _repo.api.setAvailability(slots);
      _showSnack('تم تحديث المواعيد المتاحة'.tr);
    } on ApiException catch (e) {
      await refreshProfile(showLoader: false, force: true);
      _showSnack(e.message, Colors.redAccent);
    } finally {
      updatingSettings.value = false;
    }
  }

  void _syncOnline(Map<String, dynamic>? res) {
    if (res == null) return;
    final data = res['data'] is Map ? res['data'] : res;
    if (data is! Map<String, dynamic>) return;

    if (data['online'] is bool) online.value = data['online'];
    if (data['unavailableUntil'] is String) {
      unavailableUntil.value = DateTime.tryParse(data['unavailableUntil']);
    }
    if (data['slots'] is List) {
      availabilitySlots.assignAll(
        (data['slots'] as List).whereType<Map>().cast<Map<String, dynamic>>(),
      );
    }
  }
  Future<void> _loadRemoteSettings() async {
    try {
      final res = await _repo.api.getSettings();
      final data =
          res['settings'] ??
          (res['data'] is Map ? res['data']['settings'] : null) ??
          res['data'] ??
          res;

      if (data is! Map<String, dynamic>) return;

      final lang = data['language']?.toString();
      if (lang != null) await _localeController.changeLocale(Locale(lang));

      final theme = data['theme']?.toString();
      if (theme != null) await _themeController.setThemeMode(theme);

      _syncOnline(data);
      _settingsLoaded = true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
    }
  }
  Future<void> deleteAccount() async {
    try {
      await _repo.api.deleteAccount();
      await logout();
    } on ApiException catch (e) {
      _showSnack(e.message, Colors.redAccent);
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    _profileLoaded = false;
    _settingsLoaded = false;

    if (!_isCustomerModeActive()) return;
    if (Get.isRegistered<AuthController>(tag: 'customer')) {
      await Get.find<AuthController>(tag: 'customer').logout(remote: false);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _handleApiError(ApiException error) {
    if (error.statusCode == 409) {
      _showSnack('البيانات المدخلة موجودة بالفعل'.tr, Colors.redAccent);
      return;
    }
    _showSnack(error.message, Colors.redAccent);
  }

  void _showSnack(String message, [Color color = Colors.green]) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: color,
      ),
    );
  }
}



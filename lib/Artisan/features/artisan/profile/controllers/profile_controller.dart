import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class ProfileController extends GetxController {
  final ArtisanApi _api = ArtisanApi();
  final AppPrefs prefs = AppPrefs();

  final RxMap<String, dynamic> profile = <String, dynamic>{}.obs;
  final RxBool loading = false.obs;
  final RxBool updating = false.obs;
  final RxBool togglingStatus = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initController();
  }

  Future<void> _initController() async {
    await prefs.init();
    await _loadCachedProfile();
    final auth = Get.find<AuthService>();
    await auth.waitForAuthentication();
    if (auth.isAuthenticated) {
      await fetchProfile();
    }
  }

  bool get isOnline {
    final onlineVal = profile['online'];
    final statusVal = (profile['status'] ?? '').toString().toLowerCase();
    if (onlineVal != null) return onlineVal == true;
    if (statusVal == 'offline') return false;
    return true;
  }

  Future<void> fetchProfile() async {
    loading.value = true;
    try {
      final response = await _api.profile();
      final data = ApiClient.instance.unwrapData(response);

      Map<String, dynamic> profileData = {};
      Map<String, dynamic> stats = {};

      if (data is Map<String, dynamic>) {
        // نحاول نطلع الـ profile من أكتر من مكان
        profileData = (data['profile'] ?? data['artisan'] ?? data)
            .cast<String, dynamic>();

        if (data['stats'] is Map<String, dynamic>) {
          stats = (data['stats'] as Map<String, dynamic>)
              .cast<String, dynamic>();
        }

        if (data.containsKey('profileCompletion')) {
          profileData['profileCompletion'] = data['profileCompletion'];
        }
        if (data.containsKey('missingFields')) {
          profileData['missingFields'] = data['missingFields'];
        }
        if (data.containsKey('isProfileCompleted')) {
          profileData['isProfileCompleted'] = data['isProfileCompleted'];
        }
      }

      try {
        final completionResponse = await _api.profileCompletion();
        final completionData = ApiClient.instance.unwrapData(
          completionResponse,
        );
        if (completionData is Map<String, dynamic>) {
          if (completionData.containsKey('profileCompletion')) {
            profileData['profileCompletion'] =
                completionData['profileCompletion'];
          }
          if (completionData.containsKey('missingFields')) {
            profileData['missingFields'] = completionData['missingFields'];
          }
          if (completionData.containsKey('isCompleted')) {
            profileData['isProfileCompleted'] = completionData['isCompleted'];
          }
        }
      } catch (_) {
        // keep existing completion values if the endpoint fails
      }

      // حافظ على قيمة online/status لو كانت متخزنة قبل كده
      final cachedOnline = profile['online'];
      final cachedStatus = profile['status'];

      profileData['online'] ??= cachedOnline;
      profileData['status'] ??= cachedStatus;

      profile.assignAll(profileData);
      profile['stats'] = stats;
      await prefs.setString(kCachedProfileKey, jsonEncode(profile));
    } catch (e) {
      _handleError(e, silent: true);
    } finally {
      loading.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    updating.value = true;
    try {
      final data = Map<String, dynamic>.from(payload);
      data.removeWhere(
        (_, value) =>
            value == null || (value is String && value.trim().isEmpty),
      );
      final avatar = data.remove('avatar');

      if (avatar is String && avatar.isNotEmpty) {
        try {
          await _api.uploadProfilePhoto(avatar);
        } on ApiException catch (e) {
          if (e.statusCode == 404) {
            data['avatar'] = avatar;
          } else {
            rethrow;
          }
        }
      }

      if (data.isNotEmpty) {
        await _api.updateProfile(data);
      }
      await fetchProfile();
      _showSnack(AppStrings.profileUpdated.tr, Colors.green);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      updating.value = false;
    }
  }

  Future<void> updateStatus(String status) async {
    togglingStatus.value = true;
    try {
      await _api.updateStatus(status);
      profile['status'] = status;
      profile.refresh();
      await prefs.setString(kCachedProfileKey, jsonEncode(profile));
      _showSnack(AppStrings.statusUpdated.tr, Colors.green);
    } catch (e) {
      _handleError(e);
    } finally {
      togglingStatus.value = false;
    }
  }

  Future<void> toggleOnline(bool online, {DateTime? unavailableUntil}) async {
    if (togglingStatus.value) return;

    togglingStatus.value = true;

    // ✅ احفظ القديم عشان نرجّعه لو حصل خطأ
    final prevOnline = profile['online'];
    final prevStatus = profile['status'];

    // ✅ تحديث فوري للـ UI
    profile['online'] = online;
    profile['status'] = online ? 'available' : 'offline';
    profile.refresh();

    // ✅ خزّن فورًا (اختياري بس مفيد لو قفلت الشاشة)
    await prefs.setString(kCachedProfileKey, jsonEncode(profile));

    try {
      await _api.toggleOnline(
        online: online,
        unavailableUntil: unavailableUntil,
      );
    } catch (e) {
      // ✅ رجّع القديم لو فشل
      profile['online'] = prevOnline;
      profile['status'] = prevStatus;
      profile.refresh();

      await prefs.setString(kCachedProfileKey, jsonEncode(profile));
      _handleError(e);
    } finally {
      togglingStatus.value = false;
    }
  }

  Future<void> setLocation(double lat, double lng) async {
    updating.value = true;
    try {
      await _api.setLocation(lat: lat, lng: lng);

      // نخلي شكل الـ location زي الـ backend بالظبط
      profile['location'] = {
        'type': 'Point',
        'coordinates': [lng, lat],
      };
      profile.refresh();

      await prefs.setString(kCachedProfileKey, jsonEncode(profile));

      _showSnack(AppStrings.locationUpdated.tr, Colors.green);
    } catch (e) {
      _handleError(e);
    } finally {
      updating.value = false;
    }
  }

  Future<void> setAvailability(List<Map<String, dynamic>> slots) async {
    updating.value = true;
    try {
      await _api.setAvailability(slots);
      _showSnack(AppStrings.availabilityUpdated.tr, Colors.green);
    } catch (e) {
      _handleError(e);
    } finally {
      updating.value = false;
    }
  }

  Future<void> _loadCachedProfile() async {
    final cached = prefs.getString(kCachedProfileKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        profile.assignAll(data);
      } catch (_) {
        // ignore parse error
      }
    }
  }

  void _handleError(Object error, {bool silent = false}) {
    if (silent) return;
    if (error is ApiException) {
      _showSnack(error.message, Colors.redAccent);
    } else {
      _showSnack(AppStrings.profileUpdateFailed.tr, Colors.redAccent);
    }
  }

  void _showSnack(String message, Color color) {
    final type = color == Colors.redAccent
        ? SnackBarType.error
        : SnackBarType.info;
    AppSnackBar.show(
      type == SnackBarType.error ? AppStrings.error.tr : AppStrings.info.tr,
      message,
      type: type,
    );
  }
}

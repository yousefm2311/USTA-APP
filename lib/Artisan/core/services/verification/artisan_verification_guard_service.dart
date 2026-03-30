import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/kyc/artisan_verification_route.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class ArtisanVerificationGuardService extends GetxService
    with WidgetsBindingObserver {
  ArtisanVerificationGuardService({
    ArtisanApi? api,
    AppPrefs? prefs,
  })  : _api = api ?? ArtisanApi(),
        _prefs = prefs ?? AppPrefs();

  final ArtisanApi _api;
  final AppPrefs _prefs;

  bool _isChecking = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.microtask(() => syncAndEnforce(refreshFromServer: true));
    }
  }

  Future<void> syncAndEnforce({
    bool refreshFromServer = false,
    String? currentRoute,
  }) async {
    if (_isChecking) return;
    if (!Get.isRegistered<AuthService>() ||
        !Get.find<AuthService>().isAuthenticated) {
      return;
    }

    _isChecking = true;
    try {
      await _prefs.init();
      var profile = decodeCachedArtisanProfile(_prefs.getString(kCachedProfileKey));

      if (refreshFromServer) {
        try {
          final response = await _api.me();
          if (response is Map<String, dynamic>) {
            final remoteProfile = response['artisan'] is Map<String, dynamic>
                ? response['artisan'] as Map<String, dynamic>
                : response;
            profile = remoteProfile;
            await _prefs.setString(kCachedProfileKey, jsonEncode(remoteProfile));
          }
        } catch (_) {
          // Keep the latest cached profile when the network is unavailable.
        }
      }

      final route = currentRoute ?? Get.currentRoute;
      if (isArtisanRouteAllowedForVerificationStatus(route, profile)) {
        return;
      }

      final target = resolveArtisanVerificationRoute(profile);
      if (route != target && target.isNotEmpty) {
        Get.offAllNamed(target);
      }
    } finally {
      _isChecking = false;
    }
  }
}

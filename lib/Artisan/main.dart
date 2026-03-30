import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:usta/app/app_mode_controller.dart';
import 'package:usta/app/app_switcher.dart';
import 'package:usta/Artisan/core/services/fcm_service.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/verification/artisan_verification_guard_service.dart';
import 'package:usta/Artisan/core/services/settings/settings_services.dart';
import 'package:usta/Artisan/core/services/theme/themes.dart';
import 'package:usta/Artisan/core/services/token_storage.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/bindings/binding.dart';
import 'package:usta/Artisan/core/utils/bindings/customer_binding_v2.dart';
import 'package:usta/Artisan/core/utils/constants/app_translations.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/kyc/artisan_verification_route.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/repositories/fcm_repository.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/locale_controller.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/theme_controller.dart';
import 'package:usta/Artisan/firebase_options.dart';

bool _artisanInitialized = false;

T _findOrPut<T>(
  T Function() creator, {
  required String tag,
  bool permanent = false,
}) {
  try {
    return Get.find<T>(tag: tag);
  } catch (_) {
    return Get.put<T>(creator(), permanent: permanent, tag: tag);
  }
}

void _ensureArtisanUiControllers() {
  _findOrPut<ThemeController>(
    () => ThemeController(),
    tag: 'artisan',
    permanent: true,
  );
  _findOrPut<LocaleController>(
    () => LocaleController(),
    tag: 'artisan',
    permanent: true,
  );
}

Future<void> ensureArtisanInitialized() async {
  if (!_artisanInitialized) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await initService();
    await GetStorage.init();
    Get.put(TokenStorage(), permanent: true, tag: 'artisan');
    if (!Get.isRegistered<FcmRepository>()) {
      Get.put(FcmRepository(), permanent: true);
    }
    final fcmService = FcmService();
    try {
      await fcmService.init();
    } catch (error, stack) {
      log('[main] FcmService init failed: $error', stackTrace: stack);
    }
    if (!Get.isRegistered<FcmService>()) {
      Get.put(fcmService, permanent: true);
    }
    await CustomerBindingV2.ensureInitialized();
    CustomerBindingV2().dependencies();
    _artisanInitialized = true;
  }
  _ensureArtisanUiControllers();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureArtisanInitialized();
  final controller = Get.put(AppModeController(), permanent: true);
  await controller.selectArtisan(force: true);
  runApp(const AppSwitcher());
}

Future initService() async {
  if (!Get.isRegistered<RealtimeLifecycleService>()) {
    Get.put(RealtimeLifecycleService(), permanent: true);
  }
  if (!Get.isRegistered<AuthService>()) {
    Get.put(AuthService(), permanent: true);
  }
  if (!Get.isRegistered<ApiClient>(tag: 'artisan')) {
    Get.put(ApiClient(), permanent: true, tag: 'artisan');
  }
  if (!Get.isRegistered<ArtisanVerificationGuardService>()) {
    Get.put(ArtisanVerificationGuardService(), permanent: true);
  }
  await Get.putAsync<SettingsServices>(
    () => SettingsServices().init(),
    tag: 'artisan',
  );
}

Future<String> resolveArtisanInitialRoute() async {
  final storage = Get.find<TokenStorage>(tag: 'artisan');
  final token = storage.accessToken;
  if (token != null && token.isNotEmpty && !storage.loggedOut) {
    final prefs = AppPrefs();
    Map<String, dynamic>? cachedProfile;
    try {
      await prefs.init();
      cachedProfile = decodeCachedArtisanProfile(
        prefs.getString(kCachedProfileKey),
      );
    } catch (_) {
      cachedProfile = null;
    }

    if (Get.isRegistered<ApiClient>(tag: 'artisan')) {
      try {
        final response = await ArtisanApi().me();
        if (response is Map<String, dynamic>) {
          final profile = (response['artisan'] is Map<String, dynamic>)
              ? response['artisan'] as Map<String, dynamic>
              : response;
          await prefs.setString(kCachedProfileKey, jsonEncode(profile));
          return resolveArtisanVerificationRoute(profile);
        }
      } catch (_) {
        // Fall back to the latest cached profile when the network is offline.
      }
    }

    return resolveArtisanVerificationRoute(cachedProfile);
  }
  return AppRoutes.login;
}

class ArtisanApp extends StatelessWidget {
  ArtisanApp({super.key, String? initialRoute})
      : initialRoute = initialRoute ?? AppRoutes.login,
        themeController = _findOrPut<ThemeController>(
          () => ThemeController(),
          tag: 'artisan',
          permanent: true,
        ),
        localeController = _findOrPut<LocaleController>(
          () => LocaleController(),
          tag: 'artisan',
          permanent: true,
        );

  final String initialRoute;

  final ThemeController themeController;
  final LocaleController localeController;
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        scaffoldMessengerKey: AppSnackBar.messengerKey,
        initialRoute: initialRoute,
        initialBinding: Binding(),
        getPages: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode:
            themeController.isDark.value ? ThemeMode.dark : ThemeMode.light,
        locale: localeController.locale.value,
        fallbackLocale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
        routingCallback: (routing) {
          if (Get.isRegistered<ArtisanVerificationGuardService>()) {
            Get.find<ArtisanVerificationGuardService>().syncAndEnforce(
              currentRoute: routing?.current,
            );
          }
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}

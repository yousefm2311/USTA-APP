import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:usta/Customer/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:usta/app/app_mode_controller.dart';
import 'package:usta/app/services/backend_status_service.dart';
import 'package:usta/app/app_switcher.dart';
import 'package:usta/app/widgets/server_unavailable_overlay.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/core/services/connectivity/connectivity_service.dart';
import 'package:usta/Customer/core/services/device_id_service.dart';
import 'package:usta/Customer/core/services/network/api_client.dart';
import 'package:usta/Customer/core/services/notification_service.dart';
import 'package:usta/Customer/core/services/push/push_notifications_service.dart';
import 'package:usta/Customer/core/services/settings/local_controller.dart';
import 'package:usta/Customer/core/services/settings/settings_services.dart';
import 'package:usta/Customer/core/services/settings/theme_controller.dart';
import 'package:usta/Customer/core/services/theme/themes.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/Customer/core/utils/bindings/binding.dart';
import 'package:usta/Customer/core/utils/constants/app_translations.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';
import 'package:usta/Customer/core/widgets/no_internet_overlay.dart';
import 'package:usta/Customer/data/providers/customer_api.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';

bool _customerInitialized = false;

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

void _ensureCustomerUiControllers() {
  _findOrPut<LocaleController>(
    () => LocaleController(),
    tag: 'customer',
    permanent: true,
  );
  _findOrPut<ThemeController>(
    () => ThemeController(),
    tag: 'customer',
    permanent: true,
  );
}

Future<void> ensureCustomerInitialized() async {
  if (!_customerInitialized) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await AppConfig.load();
    await initService();
    await GetStorage.init();
    Get.put(TokenStorage(), permanent: true, tag: 'customer');
    await Get.find<TokenStorage>(tag: 'customer').init();
    Get.put(DeviceIdService(), permanent: true);
    await Get.find<DeviceIdService>().init();
    if (!Get.isRegistered<ConnectivityService>(tag: 'customer')) {
      Get.put(ConnectivityService(), permanent: true, tag: 'customer');
    }
    if (!Get.isRegistered<BackendStatusService>()) {
      Get.put(BackendStatusService(), permanent: true);
    }
    Get.put(ApiClient(), permanent: true, tag: 'customer');

    if (!Get.isRegistered<CustomerApi>()) {
      Get.put(CustomerApi(), permanent: true);
    }
    if (!Get.isRegistered<CustomerRepository>()) {
      Get.put(CustomerRepository(), permanent: true);
    }
    await Get.putAsync(() => PushNotificationsService().init());
    await NotificationService.instance.init();
    _customerInitialized = true;
  }
  _ensureCustomerUiControllers();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureCustomerInitialized();
  final controller = Get.put(AppModeController(), permanent: true);
  await controller.selectCustomer(force: true);
  runApp(const AppSwitcher());
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future initService() async {
  await Get.putAsync<SettingsServices>(
    () => SettingsServices().init(),
    tag: 'customer',
  );
}

Future<String> resolveCustomerInitialRoute() async {
  final storage = Get.find<TokenStorage>(tag: 'customer');
  final token = storage.accessToken;
  if (token != null && token.isNotEmpty && !storage.loggedOut) {
    return AppRoutes.customerBottomNaviBar;
  }
  return AppRoutes.login;
}

class CustomerApp extends StatelessWidget {
  CustomerApp({super.key, String? initialRoute})
    : initialRoute = initialRoute ?? AppRoutes.login,
      themeController = _findOrPut<ThemeController>(
        () => ThemeController(),
        tag: 'customer',
        permanent: true,
      ),
      localeController = _findOrPut<LocaleController>(
        () => LocaleController(),
        tag: 'customer',
        permanent: true,
      );

  final String initialRoute;

  final ThemeController themeController;
  final LocaleController localeController;
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        initialRoute: initialRoute,
        initialBinding: Binding(),
        getPages: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: AppSnackBar.messengerKey,
        translations: AppTranslations(),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.isDark.value
            ? ThemeMode.dark
            : ThemeMode.light,
        locale: localeController.locale.value,
        fallbackLocale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          if (!Get.isRegistered<ConnectivityService>(tag: 'customer')) {
            return content;
          }
          final service = Get.find<ConnectivityService>(tag: 'customer');
          final backendStatus = Get.find<BackendStatusService>();
          return Obx(() {
            if (!service.isOnline.value) {
              return Stack(
                children: [
                  content,
                  Positioned.fill(
                    child: ModalBarrier(
                      dismissible: false,
                      color: Colors.black38,
                    ),
                  ),
                  Positioned.fill(child: NoInternetOverlay(service: service)),
                ],
              );
            }
            if (!backendStatus.isUnavailable.value) return content;
            return Stack(
              children: [
                content,
                Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: Colors.black38,
                  ),
                ),
                Positioned.fill(
                  child: ServerUnavailableOverlay(service: backendStatus),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}

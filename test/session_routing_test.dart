import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/Artisan/core/services/token_storage.dart'
    as artisan_storage;
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart' as artisan_routes;
import 'package:usta/Artisan/main.dart' as artisan_main;
import 'package:usta/Customer/core/services/token_storage.dart'
    as customer_storage;
import 'package:usta/Customer/core/utils/routes/routes.dart' as customer_routes;
import 'package:usta/Customer/main.dart' as customer_main;

import 'support/in_memory_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPrefs();
    await prefs.init();
    await prefs.clear();
  });

  tearDown(Get.reset);

  test('customer route boots into home when a valid session exists', () async {
    final storage = customer_storage.TokenStorage(
      secureStorage: InMemorySecureStorage(),
      boxStorage: InMemoryLocalStorage(),
      originResolver: () => 'https://usta.qzz.io',
      storageBootstrap: () async {},
    );
    await storage.init();
    await storage.save(accessToken: 'customer-access', refreshToken: 'refresh');
    Get.put<customer_storage.TokenStorage>(storage, tag: 'customer');

    final route = await customer_main.resolveCustomerInitialRoute();

    expect(route, customer_routes.AppRoutes.customerBottomNaviBar);
  });

  test('customer route falls back to login after logout', () async {
    final storage = customer_storage.TokenStorage(
      secureStorage: InMemorySecureStorage(),
      boxStorage: InMemoryLocalStorage(),
      originResolver: () => 'https://usta.qzz.io',
      storageBootstrap: () async {},
    );
    await storage.init();
    await storage.clear();
    Get.put<customer_storage.TokenStorage>(storage, tag: 'customer');

    final route = await customer_main.resolveCustomerInitialRoute();

    expect(route, customer_routes.AppRoutes.login);
  });

  test('artisan route boots into home when a valid session exists', () async {
    final prefs = AppPrefs();
    await prefs.init();
    await prefs.setString(
      kCachedProfileKey,
      jsonEncode({
        'verificationStatus': 'approved',
      }),
    );
    final storage = artisan_storage.TokenStorage(
      secureStorage: InMemorySecureStorage(),
      boxStorage: InMemoryLocalStorage(),
      originResolver: () => 'https://usta.qzz.io/api',
      storageBootstrap: () async {},
    );
    await storage.init();
    await storage.save(accessToken: 'artisan-access', refreshToken: 'refresh');
    Get.put<artisan_storage.TokenStorage>(storage, tag: 'artisan');

    final route = await artisan_main.resolveArtisanInitialRoute();

    expect(route, artisan_routes.AppRoutes.bottomNaviBar);
  });

  test('artisan route falls back to login after logout', () async {
    final storage = artisan_storage.TokenStorage(
      secureStorage: InMemorySecureStorage(),
      boxStorage: InMemoryLocalStorage(),
      originResolver: () => 'https://usta.qzz.io/api',
      storageBootstrap: () async {},
    );
    await storage.init();
    await storage.clear();
    Get.put<artisan_storage.TokenStorage>(storage, tag: 'artisan');

    final route = await artisan_main.resolveArtisanInitialRoute();

    expect(route, artisan_routes.AppRoutes.login);
  });

  test('artisan route resumes the KYC step from cached profile', () async {
    final prefs = AppPrefs();
    await prefs.init();
    await prefs.setString(
      kCachedProfileKey,
      jsonEncode({
        'verificationStatus': 'documents_uploaded',
      }),
    );
    final storage = artisan_storage.TokenStorage(
      secureStorage: InMemorySecureStorage(),
      boxStorage: InMemoryLocalStorage(),
      originResolver: () => 'https://usta.qzz.io/api',
      storageBootstrap: () async {},
    );
    await storage.init();
    await storage.save(accessToken: 'artisan-access', refreshToken: 'refresh');
    Get.put<artisan_storage.TokenStorage>(storage, tag: 'artisan');

    final route = await artisan_main.resolveArtisanInitialRoute();

    expect(route, artisan_routes.AppRoutes.artisanVerificationSelfieView);
  });
}

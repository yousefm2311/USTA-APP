import 'package:flutter_test/flutter_test.dart';
import 'package:usta/Customer/core/services/token_storage.dart';

import 'support/in_memory_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer TokenStorage', () {
    test(
      'save clears the cached refresh token when backend omits it',
      () async {
        final secure = InMemorySecureStorage();
        final box = InMemoryLocalStorage();
        final storage = TokenStorage(
          secureStorage: secure,
          boxStorage: box,
          originResolver: () => 'https://usta.qzz.io',
          storageBootstrap: () async {},
        );

        await storage.init();
        await storage.save(accessToken: 'access-1', refreshToken: 'refresh-1');
        await storage.save(accessToken: 'access-2');

        expect(storage.accessToken, 'access-2');
        expect(storage.refreshToken, isNull);
        expect(await secure.read('customer_refresh_token'), isNull);
      },
    );

    test('init migrates legacy box tokens into secure storage', () async {
      final secure = InMemorySecureStorage();
      final box = InMemoryLocalStorage();
      await box.writeString('customer_access_token', 'legacy-access');
      await box.writeString('customer_refresh_token', 'legacy-refresh');
      await box.writeBool('customer_logged_out', false);
      await box.writeString('customer_origin', 'https://usta.qzz.io');

      final storage = TokenStorage(
        secureStorage: secure,
        boxStorage: box,
        originResolver: () => 'https://usta.qzz.io',
        storageBootstrap: () async {},
      );

      await storage.init();

      expect(storage.accessToken, 'legacy-access');
      expect(storage.refreshToken, 'legacy-refresh');
      expect(await secure.read('customer_access_token'), 'legacy-access');
      expect(await secure.read('customer_refresh_token'), 'legacy-refresh');
      expect(box.readString('customer_access_token'), isNull);
      expect(box.readString('customer_refresh_token'), isNull);
    });

    test('init clears stale session when API origin changes', () async {
      final secure = InMemorySecureStorage()
        ..values['customer_access_token'] = 'access'
        ..values['customer_refresh_token'] = 'refresh'
        ..values['customer_logged_out'] = 'false'
        ..values['customer_origin'] = 'https://old.usta.qzz.io';
      final box = InMemoryLocalStorage();
      final storage = TokenStorage(
        secureStorage: secure,
        boxStorage: box,
        originResolver: () => 'https://usta.qzz.io',
        storageBootstrap: () async {},
      );

      await storage.init();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.loggedOut, isFalse);
      expect(await secure.read('customer_access_token'), isNull);
      expect(await secure.read('customer_refresh_token'), isNull);
    });
  });
}

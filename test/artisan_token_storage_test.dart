import 'package:flutter_test/flutter_test.dart';
import 'package:usta/Artisan/core/services/token_storage.dart';

import 'support/in_memory_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Artisan TokenStorage', () {
    test('save persists access and refresh tokens', () async {
      final secure = InMemorySecureStorage();
      final box = InMemoryLocalStorage();
      final storage = TokenStorage(
        secureStorage: secure,
        boxStorage: box,
        originResolver: () => 'https://usta.qzz.io/api',
        storageBootstrap: () async {},
      );

      await storage.init();
      await storage.save(
        accessToken: 'artisan-access',
        refreshToken: 'artisan-refresh',
      );

      expect(storage.accessToken, 'artisan-access');
      expect(storage.refreshToken, 'artisan-refresh');
      expect(await secure.read('artisan_access_token'), 'artisan-access');
      expect(await secure.read('artisan_refresh_token'), 'artisan-refresh');
    });

    test('init migrates fallback box tokens into secure storage', () async {
      final secure = InMemorySecureStorage();
      final box = InMemoryLocalStorage();
      await box.writeString('artisan_access_token', 'legacy-access');
      await box.writeString('artisan_refresh_token', 'legacy-refresh');
      await box.writeBool('artisan_logged_out', false);
      await box.writeString('artisan_origin', 'https://usta.qzz.io/api');

      final storage = TokenStorage(
        secureStorage: secure,
        boxStorage: box,
        originResolver: () => 'https://usta.qzz.io/api',
        storageBootstrap: () async {},
      );

      await storage.init();

      expect(storage.accessToken, 'legacy-access');
      expect(storage.refreshToken, 'legacy-refresh');
      expect(await secure.read('artisan_access_token'), 'legacy-access');
      expect(await secure.read('artisan_refresh_token'), 'legacy-refresh');
      expect(box.readString('artisan_access_token'), isNull);
      expect(box.readString('artisan_refresh_token'), isNull);
    });

    test('origin change resets the artisan session safely', () async {
      final secure = InMemorySecureStorage()
        ..values['artisan_access_token'] = 'access'
        ..values['artisan_refresh_token'] = 'refresh'
        ..values['artisan_logged_out'] = 'false'
        ..values['artisan_origin'] = 'https://legacy.usta.qzz.io/api';
      final box = InMemoryLocalStorage();
      final storage = TokenStorage(
        secureStorage: secure,
        boxStorage: box,
        originResolver: () => 'https://usta.qzz.io/api',
        storageBootstrap: () async {},
      );

      await storage.init();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.loggedOut, isFalse);
      expect(await secure.read('artisan_access_token'), isNull);
      expect(await secure.read('artisan_refresh_token'), isNull);
    });
  });
}

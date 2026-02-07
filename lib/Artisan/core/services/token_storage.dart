// import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
// import 'package:usta/Artisan/core/utils/constants/app_constant.dart';

// /// Wraps [AppPrefs] so the app always persists auth/refresh tokens atomically.
// class TokenStorage {
//   final AppPrefs _prefs = AppPrefs();

//   /// Ensures shared preferences is ready before any reads/writes.
//   Future<void> init() async {
//     await _prefs.init();
//   }

//   String? get accessToken => _prefs.getString(kAuthTokenKey);

//   String? get refreshToken => _prefs.getString(kRefreshTokenKey);

//   /// Store the tokens in one atomic operation to avoid partial updates.
//   Future<void> save({
//     required String accessToken,
//     String? refreshToken,
//   }) async {
//     await init();
//     await _prefs.setString(kAuthTokenKey, accessToken);
//     if (refreshToken != null && refreshToken.isNotEmpty) {
//       await _prefs.setString(kRefreshTokenKey, refreshToken);
//     }
//   }

//   /// Removes both tokens.
//   Future<void> clear() async {
//     await init();
//     await _prefs.remove(kAuthTokenKey);
//     await _prefs.remove(kRefreshTokenKey);
//   }
// }
import 'package:get_storage/get_storage.dart';

class TokenStorage {
  static const _accessKey = 'artisan_access_token';
  static const _refreshKey = 'artisan_refresh_token';
  static const _loggedOutKey = 'artisan_logged_out';

  final GetStorage _box = GetStorage();

  Future<void> init() async {
    await GetStorage.init();
  }

  String? get accessToken {
    final loggedOut = _box.read<bool>(_loggedOutKey) ?? false;
    if (loggedOut) return null;
    return _box.read<String>(_accessKey);
  }

  String? get refreshToken {
    final loggedOut = _box.read<bool>(_loggedOutKey) ?? false;
    if (loggedOut) return null;
    return _box.read<String>(_refreshKey);
  }

  bool get loggedOut => _box.read<bool>(_loggedOutKey) ?? false;

  Future<void> save({required String accessToken, String? refreshToken}) async {
    await _box.write(_accessKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _box.write(_refreshKey, refreshToken);
    } else {
      await _box.remove(_refreshKey);
    }
    await _box.write(_loggedOutKey, false);
  }

  Future<void> clear() async {
    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.write(_loggedOutKey, true);
  }

  Future<void> markLoggedOut() async {
    await _box.write(_loggedOutKey, true);
  }
}


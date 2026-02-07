// import 'package:usta/Customer/core/services/database/share_Prefs.dart';
// import 'package:usta/Customer/core/utils/constants/app_constant.dart';

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
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:usta/Customer/core/config/app_config.dart';

class TokenStorage {
  static const _accessKey = 'customer_access_token';
  static const _refreshKey = 'customer_refresh_token';
  static const _loggedOutKey = 'customer_logged_out';
  static const _originKey = 'customer_origin';
  static const _fcmKey = 'customer_fcm_token';

  final FlutterSecureStorage _secure = FlutterSecureStorage();
  final GetStorage _box = GetStorage();

  String? _cachedAccess;
  String? _cachedRefresh;
  String? _cachedFcm;
  bool _loggedOut = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await GetStorage.init();

    _cachedAccess = await _secure.read(key: _accessKey);
    _cachedRefresh = await _secure.read(key: _refreshKey);
    _cachedFcm = await _secure.read(key: _fcmKey);
    final loggedOutFromSecure = await _secure.read(key: _loggedOutKey);
    final originFromSecure = await _secure.read(key: _originKey);
    _cachedAccess ??= _box.read<String>(_accessKey);
    _cachedRefresh ??= _box.read<String>(_refreshKey);
    _cachedFcm ??= _box.read<String>(_fcmKey);
    final loggedOutFromBox = _box.read<bool>(_loggedOutKey) ?? false;
    final originFromBox = _box.read<String>(_originKey);

    _loggedOut = (loggedOutFromSecure == 'true') || loggedOutFromBox;

    final currentOrigin = AppConfig.instance.origin;
    final lastOrigin = originFromSecure ?? originFromBox;
    if (lastOrigin != null && lastOrigin != currentOrigin) {
      _cachedAccess = null;
      _cachedRefresh = null;
      _loggedOut = false;
      await _secure.delete(key: _accessKey);
      await _secure.delete(key: _refreshKey);
    }

    if (_cachedAccess != null) {
      await _secure.write(key: _accessKey, value: _cachedAccess);
    }
    if (_cachedRefresh != null) {
      await _secure.write(key: _refreshKey, value: _cachedRefresh);
    }
    if (_cachedFcm != null) {
      await _secure.write(key: _fcmKey, value: _cachedFcm);
    }
    await _secure.write(key: _loggedOutKey, value: _loggedOut.toString());
    await _secure.write(key: _originKey, value: currentOrigin);
    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.remove(_fcmKey);
    await _box.write(_loggedOutKey, _loggedOut);
    await _box.write(_originKey, currentOrigin);

    _initialized = true;
  }

  String? get accessToken => _loggedOut ? null : _cachedAccess;

  String? get refreshToken => _loggedOut ? null : _cachedRefresh;

  String? get fcmToken => _cachedFcm;

  bool get loggedOut => _loggedOut;

  Future<void> save({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccess = accessToken;
    _cachedRefresh = refreshToken ?? _cachedRefresh;
    _loggedOut = false;
    final currentOrigin = AppConfig.instance.origin;

    await _secure.write(key: _accessKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secure.write(key: _refreshKey, value: refreshToken);
    } else {
      await _secure.delete(key: _refreshKey);
    }
    if (_cachedFcm != null) {
      await _secure.write(key: _fcmKey, value: _cachedFcm);
    }
    await _secure.write(key: _loggedOutKey, value: 'false');
    await _secure.write(key: _originKey, value: currentOrigin);
    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.remove(_fcmKey);
    await _box.write(_loggedOutKey, false);
    await _box.write(_originKey, currentOrigin);
  }

  Future<void> saveTokens(String access, String? refresh) =>
      save(accessToken: access, refreshToken: refresh);

  Future<void> saveFcmToken(String token) async {
    _cachedFcm = token;
    await _secure.write(key: _fcmKey, value: token);
    await _box.write(_fcmKey, token);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    _cachedFcm = null;
    _loggedOut = true;
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
    await _secure.delete(key: _fcmKey);
    await _secure.write(key: _loggedOutKey, value: 'true');
    await _secure.delete(key: _originKey);
    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.remove(_fcmKey);
    await _box.write(_loggedOutKey, true);
    await _box.remove(_originKey);
  }

  Future<void> markLoggedOut() async {
    _loggedOut = true;
    await _secure.write(key: _loggedOutKey, value: 'true');
    await _box.write(_loggedOutKey, true);
  }
}


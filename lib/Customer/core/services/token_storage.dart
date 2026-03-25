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
import 'package:get_storage/get_storage.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/app/services/storage_backends.dart';

class TokenStorage {
  static const _accessKey = 'customer_access_token';
  static const _refreshKey = 'customer_refresh_token';
  static const _loggedOutKey = 'customer_logged_out';
  static const _originKey = 'customer_origin';
  static const _fcmKey = 'customer_fcm_token';

  TokenStorage({
    SecureStorageBackend? secureStorage,
    LocalStorageBackend? boxStorage,
    String Function()? originResolver,
    Future<void> Function()? storageBootstrap,
  }) : _secure = secureStorage ?? FlutterSecureStorageBackend(),
       _box = boxStorage ?? GetStorageBackend(),
       _originResolver = originResolver ?? (() => AppConfig.instance.origin),
       _storageBootstrap = storageBootstrap ?? GetStorage.init;

  final SecureStorageBackend _secure;
  final LocalStorageBackend _box;
  final String Function() _originResolver;
  final Future<void> Function() _storageBootstrap;

  String? _cachedAccess;
  String? _cachedRefresh;
  String? _cachedFcm;
  bool _loggedOut = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _storageBootstrap();

    _cachedAccess = await _secure.read(_accessKey);
    _cachedRefresh = await _secure.read(_refreshKey);
    _cachedFcm = await _secure.read(_fcmKey);
    final loggedOutFromSecure = await _secure.read(_loggedOutKey);
    final originFromSecure = await _secure.read(_originKey);
    _cachedAccess ??= _box.readString(_accessKey);
    _cachedRefresh ??= _box.readString(_refreshKey);
    _cachedFcm ??= _box.readString(_fcmKey);
    final loggedOutFromBox = _box.readBool(_loggedOutKey) ?? false;
    final originFromBox = _box.readString(_originKey);

    _loggedOut = (loggedOutFromSecure == 'true') || loggedOutFromBox;

    final currentOrigin = _originResolver();
    final lastOrigin = originFromSecure ?? originFromBox;
    if (lastOrigin != null && lastOrigin != currentOrigin) {
      _cachedAccess = null;
      _cachedRefresh = null;
      _loggedOut = false;
      await _secure.delete(_accessKey);
      await _secure.delete(_refreshKey);
    }

    if (_cachedAccess != null) {
      await _secure.write(_accessKey, _cachedAccess!);
    }
    if (_cachedRefresh != null) {
      await _secure.write(_refreshKey, _cachedRefresh!);
    }
    if (_cachedFcm != null) {
      await _secure.write(_fcmKey, _cachedFcm!);
    }
    await _secure.write(_loggedOutKey, _loggedOut.toString());
    await _secure.write(_originKey, currentOrigin);
    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.remove(_fcmKey);
    await _box.writeBool(_loggedOutKey, _loggedOut);
    await _box.writeString(_originKey, currentOrigin);

    _initialized = true;
  }

  String? get accessToken => _loggedOut ? null : _cachedAccess;

  String? get refreshToken => _loggedOut ? null : _cachedRefresh;

  String? get fcmToken => _cachedFcm;

  bool get loggedOut => _loggedOut;

  Future<void> save({required String accessToken, String? refreshToken}) async {
    _cachedAccess = accessToken;
    _cachedRefresh = refreshToken != null && refreshToken.isNotEmpty
        ? refreshToken
        : null;
    _loggedOut = false;
    final currentOrigin = _originResolver();

    await _secure.write(_accessKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secure.write(_refreshKey, refreshToken);
    } else {
      await _secure.delete(_refreshKey);
    }
    if (_cachedFcm != null) {
      await _secure.write(_fcmKey, _cachedFcm!);
    }
    await _secure.write(_loggedOutKey, 'false');
    await _secure.write(_originKey, currentOrigin);
    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.remove(_fcmKey);
    await _box.writeBool(_loggedOutKey, false);
    await _box.writeString(_originKey, currentOrigin);
  }

  Future<void> saveTokens(String access, String? refresh) =>
      save(accessToken: access, refreshToken: refresh);

  Future<void> saveFcmToken(String token) async {
    _cachedFcm = token;
    await _secure.write(_fcmKey, token);
    await _box.writeString(_fcmKey, token);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    _cachedFcm = null;
    _loggedOut = true;
    await _secure.delete(_accessKey);
    await _secure.delete(_refreshKey);
    await _secure.delete(_fcmKey);
    await _secure.write(_loggedOutKey, 'true');
    await _secure.delete(_originKey);
    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.remove(_fcmKey);
    await _box.writeBool(_loggedOutKey, true);
    await _box.remove(_originKey);
  }

  Future<void> markLoggedOut() async {
    _loggedOut = true;
    await _secure.write(_loggedOutKey, 'true');
    await _box.writeBool(_loggedOutKey, true);
  }
}

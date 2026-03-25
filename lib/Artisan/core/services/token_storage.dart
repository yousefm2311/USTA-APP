import 'package:get_storage/get_storage.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/app/services/storage_backends.dart';

class TokenStorage {
  TokenStorage({
    SecureStorageBackend? secureStorage,
    LocalStorageBackend? boxStorage,
    String Function()? originResolver,
    Future<void> Function()? storageBootstrap,
  }) : _secure = secureStorage ?? FlutterSecureStorageBackend(),
       _box = boxStorage ?? GetStorageBackend(),
       _originResolver = originResolver ?? (() => ApiEndpoints.baseUrl),
       _storageBootstrap = storageBootstrap ?? GetStorage.init;

  static const _accessKey = 'artisan_access_token';
  static const _refreshKey = 'artisan_refresh_token';
  static const _loggedOutKey = 'artisan_logged_out';
  static const _originKey = 'artisan_origin';

  final SecureStorageBackend _secure;
  final LocalStorageBackend _box;
  final String Function() _originResolver;
  final Future<void> Function() _storageBootstrap;

  String? _cachedAccess;
  String? _cachedRefresh;
  bool _loggedOut = false;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _storageBootstrap();

    _cachedAccess = await _secure.read(_accessKey);
    _cachedRefresh = await _secure.read(_refreshKey);
    final loggedOutFromSecure = await _secure.read(_loggedOutKey);
    final originFromSecure = await _secure.read(_originKey);

    _cachedAccess ??= _box.readString(_accessKey);
    _cachedRefresh ??= _box.readString(_refreshKey);
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
    await _secure.write(_loggedOutKey, _loggedOut.toString());
    await _secure.write(_originKey, currentOrigin);

    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.writeBool(_loggedOutKey, _loggedOut);
    await _box.writeString(_originKey, currentOrigin);

    _initialized = true;
  }

  String? get accessToken => _loggedOut ? null : _cachedAccess;

  String? get refreshToken => _loggedOut ? null : _cachedRefresh;

  bool get loggedOut => _loggedOut;

  Future<void> save({required String accessToken, String? refreshToken}) async {
    _cachedAccess = accessToken;
    _cachedRefresh = refreshToken != null && refreshToken.isNotEmpty
        ? refreshToken
        : null;
    _loggedOut = false;
    final currentOrigin = _originResolver();

    await _secure.write(_accessKey, accessToken);
    if (_cachedRefresh != null) {
      await _secure.write(_refreshKey, _cachedRefresh!);
    } else {
      await _secure.delete(_refreshKey);
    }
    await _secure.write(_loggedOutKey, 'false');
    await _secure.write(_originKey, currentOrigin);

    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.writeBool(_loggedOutKey, false);
    await _box.writeString(_originKey, currentOrigin);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    _loggedOut = true;

    await _secure.delete(_accessKey);
    await _secure.delete(_refreshKey);
    await _secure.write(_loggedOutKey, 'true');
    await _secure.delete(_originKey);

    await _box.remove(_accessKey);
    await _box.remove(_refreshKey);
    await _box.writeBool(_loggedOutKey, true);
    await _box.remove(_originKey);
  }

  Future<void> markLoggedOut() async {
    _loggedOut = true;
    await _secure.write(_loggedOutKey, 'true');
    await _box.writeBool(_loggedOutKey, true);
  }
}

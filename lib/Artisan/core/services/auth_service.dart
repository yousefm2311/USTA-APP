// import 'dart:async';
// import 'dart:developer';

// import 'package:dio/dio.dart';
// import 'package:get/get.dart';
// import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
// import 'package:usta/Artisan/core/realtime/socket_service.dart';
// import 'package:usta/Artisan/core/services/connectivity/connectivity_service.dart';
// import 'package:usta/Artisan/core/services/network/api_client.dart';
// import 'package:usta/Artisan/core/services/token_storage.dart';
// import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
// import 'package:usta/Artisan/core/utils/routes/routes.dart';

// /// Centralized auth + refresh token manager.
// class AuthService extends GetxService {
//   final TokenStorage _storage = TokenStorage();
//   final Dio _refreshDio = Dio(BaseOptions(
//     baseUrl: ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/api/?$'), ''),
//     connectTimeout: const Duration(seconds: 45),
//     receiveTimeout: const Duration(seconds: 45),
//   ));

//   final RxnString _accessToken = RxnString();
//   Future<bool>? _refreshFuture;
//   bool _isHandlingUnauthorized = false;
//   bool _isPerformingLogout = false;
//   bool _shouldLogoutAfterRefreshFailure = false;
//   final RxBool _authenticated = false.obs;

//   RealtimeLifecycleService get _realtime => Get.find<RealtimeLifecycleService>();
//   ConnectivityService get _connectivity => Get.find<ConnectivityService>(tag: 'artisan');

//   String? get accessToken => _accessToken.value ?? _storage.accessToken;
//   String? get refreshToken => _storage.refreshToken;
//   bool get isAuthenticated => _authenticated.value;
//   Stream<bool> get authenticatedStream => _authenticated.stream;

//   @override
//   Future<void> onInit() async {
//     await _storage.init();
//     _accessToken.value = _storage.accessToken;
//     final hasToken = _accessToken.value?.isNotEmpty ?? false;
//     _updateAuthState(hasToken);
//     if (hasToken) {
//       Future.microtask(_dispatchLoginSideEffects);
//     }
//     super.onInit();
//   }

//   /// Persists a new access (and optional refresh) token pair.
//   Future<void> saveTokens({
//     required String accessToken,
//     String? refreshToken,
//   }) async {
//     await _storage.save(accessToken: accessToken, refreshToken: refreshToken);
//     _accessToken.value = accessToken;
//     _updateAuthState(true);
//     Future.microtask(_dispatchLoginSideEffects);
//   }

//   Future<void> _dispatchLoginSideEffects() async {
//     final token = _accessToken.value;
//     if (token != null && token.isNotEmpty) {
//       if (Get.isRegistered<SocketService>()) {
//         Get.find<SocketService>().connectIfNeeded();
//       }
//       await _realtime.startAll();
//     }
//   }

//   /// Deletes tokens and clears the cached access token.
//   Future<void> clearTokens() async {
//     await _storage.clear();
//     _accessToken.value = null;
//     _updateAuthState(false);
//   }

//   /// Refresh tokens with singleton refresh logic (never completes twice).
//   Future<bool> refreshTokens() {
//     _refreshFuture ??= _runRefreshFlow().then((value) => value).catchError(
//       (error, stack) {
//         log('[AuthService] Refresh failed: $error', stackTrace: stack);
//         _shouldLogoutAfterRefreshFailure = false;
//         return false;
//       },
//     ).whenComplete(() {
//       _refreshFuture = null;
//     });
//     return _refreshFuture!;
//   }

//   Future<bool> _runRefreshFlow() async {
//     // Default to forcing logout on any refresh failure; only clear this on success.
//     _shouldLogoutAfterRefreshFailure = true;
//     final candidate = refreshToken ?? accessToken;
//     if (candidate == null || candidate.isEmpty) {
//       return false;
//     }
//     try {
//       final response = await _refreshDio.post(
//         ApiEndpoints.refresh,
//         options: Options(
//           headers: {'Authorization': 'Bearer $candidate'},
//         ),
//       );
//       final Map<String, dynamic>? body =
//           response.data is Map<String, dynamic> ? response.data : null;
//       if (body == null) return false;
//       final newToken = _extractToken(body);
//       final newRefresh = _extractRefreshToken(body);
//       if (newToken != null && newToken.isNotEmpty) {
//         await saveTokens(accessToken: newToken, refreshToken: newRefresh);
//         _shouldLogoutAfterRefreshFailure = false;
//         return true;
//       }
//       // If backend doesn't return a new token, keep logout flag true to avoid loops.
//     } on DioException catch (error) {
//       final status = error.response?.statusCode;
//       final isNetworkTimeout = error.type == DioExceptionType.connectionTimeout ||
//           error.type == DioExceptionType.receiveTimeout;
//       final isNetworkIssue = isNetworkTimeout ||
//           error.type == DioExceptionType.connectionError ||
//           error.type == DioExceptionType.unknown;
//       if (isNetworkIssue && status == null) {
//         log('[AuthService] Refresh skipped logout due to network/timeout: $error');
//         _shouldLogoutAfterRefreshFailure = false;
//         return false;
//       }
//       log('[AuthService] Refresh error: $error');
//       return false;
//     } catch (error) {
//       log('[AuthService] Refresh error: $error');
//       return false;
//     }
//     return false;
//   }

//   static String? _extractToken(Map<String, dynamic> response) {
//     final direct =
//         response['token'] ?? response['accessToken'] ?? response['access_token'];
//     if (direct is String && direct.isNotEmpty) return direct;
//     if (response['data'] is Map<String, dynamic>) {
//       final nested = (response['data'] as Map<String, dynamic>)['token'] ??
//           (response['data'] as Map<String, dynamic>)['accessToken'];
//       if (nested is String && nested.isNotEmpty) return nested;
//     }
//     return null;
//   }

//   static String? _extractRefreshToken(Map<String, dynamic> response) {
//     final direct =
//         response['refreshToken'] ?? response['refresh_token'] ?? response['refresh'];
//     if (direct is String && direct.isNotEmpty) return direct;
//     if (response['data'] is Map<String, dynamic>) {
//       final nested =
//           (response['data'] as Map<String, dynamic>)['refreshToken'] ??
//               (response['data'] as Map<String, dynamic>)['refresh_token'];
//       if (nested is String && nested.isNotEmpty) return nested;
//     }
//     return null;
//   }

//   /// Notifies other services when the token changes.
//   void registerAccessTokenListener(void Function(String?) listener) {
//     ever<String?>(_accessToken, listener);
//   }

//   /// Completes once the service reports `isAuthenticated == true`.
//   Future<void> waitForAuthentication() async {
//     if (_authenticated.value) return;
//     final completer = Completer<void>();
//     late final StreamSubscription<bool> sub;
//     sub = _authenticated.stream.listen((value) {
//       if (value && !completer.isCompleted) {
//         completer.complete();
//         sub.cancel();
//       }
//     });
//     await completer.future;
//   }

//   void whenAuthenticated(void Function() callback) {
//     ever<bool>(_authenticated, (value) {
//       if (value == true) {
//         callback();
//       }
//     });
//   }

//   Future<void> handleUnauthorized({
//     bool skipRefresh = false,
//     bool fromSocket = false,
//     bool forceLogout = false,
//   }) async {
//     if (_isHandlingUnauthorized) return;
//     _isHandlingUnauthorized = true;
//     if (!skipRefresh) {
//       final refreshed = await refreshTokens();
//       if (refreshed) {
//         _isHandlingUnauthorized = false;
//         return;
//       }
//       if (!_shouldLogoutAfterRefreshFailure) {
//         _isHandlingUnauthorized = false;
//         return;
//       }
//     } else if (!forceLogout && !_shouldLogoutAfterRefreshFailure) {
//       _isHandlingUnauthorized = false;
//       return;
//     }
//     await _performLogout();
//     _isHandlingUnauthorized = false;
//   }

//   Future<void> _performLogout() async {
//     if (_isPerformingLogout) return;
//     _isPerformingLogout = true;
//     _shouldLogoutAfterRefreshFailure = false;
//     await _realtime.stopAll();
//     if (Get.isRegistered<SocketService>()) {
//       await Get.find<SocketService>().disconnect();
//     }
//     await clearTokens();
//     Get.offAllNamed(AppRoutes.login);
//     _isPerformingLogout = false;
//   }

//   /// Verify connectivity and current token validity.
//   Future<bool> verifyConnection() async {
//     try {
//       final reachable = await _connectivity.verifyServerReachable();
//       if (!reachable) return false;
//       await ApiClient.instance.get(ApiEndpoints.me);
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   /// Debug helper that mimics the Postman refresh flow headers.
//   Future<void> debugCheckRefreshTokenEndpoint() async {
//     final candidate = refreshToken ?? accessToken;
//     if (candidate == null || candidate.isEmpty) {
//       log('[AuthService] No token available for refresh check.');
//       return;
//     }
//     try {
//       final response = await _refreshDio.post(
//         ApiEndpoints.refresh,
//         options: Options(
//           headers: {'Authorization': 'Bearer $candidate'},
//         ),
//       );
//       log(
//         '[AuthService] Refresh check response: ${response.statusCode} ${response.data}',
//       );
//     } on DioException catch (error) {
//       log(
//         '[AuthService] Refresh check failed (${error.response?.statusCode}): ${error.response?.data}',
//       );
//     } catch (error) {
//       log('[AuthService] Refresh check unexpected error: $error');
//     }
//   }

//   /// Pushes auth state once; refresh only when the value didn't change.
//   void _updateAuthState(bool newValue) {
//     final changed = _authenticated.value != newValue;
//     if (changed) {
//       _authenticated.value = newValue;
//       return;
//     }
//     _authenticated.refresh();
//   }
// }

import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/chat_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/notifications_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/services/connectivity/connectivity_service.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/token_storage.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/app/app_mode_controller.dart';
import 'package:usta/app/choose_user_type_view.dart';
import 'package:usta/Artisan/features/artisan/controllers/artisan_controller.dart';

/// Centralized auth + refresh token manager for Artisan app.
class AuthService extends GetxService {
  final TokenStorage _storage = TokenStorage();

  // Separate Dio just for refresh endpoint
  final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl.replaceFirst(
        RegExp(r'/api/?$'),
        '',
      ), // نفس اللي عندك
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );

  final RxnString _accessToken = RxnString();
  Future<bool>? _refreshFuture;
  bool _isHandlingUnauthorized = false;
  bool _isPerformingLogout = false;
  bool _shouldLogoutAfterRefreshFailure = false;
  final RxBool _authenticated = false.obs;

  RealtimeLifecycleService get _realtime =>
      Get.find<RealtimeLifecycleService>();
  ConnectivityService get _connectivity => Get.find<ConnectivityService>(tag: 'artisan');
  String? get accessToken => _accessToken.value ?? _storage.accessToken;
  String? get refreshToken => _storage.refreshToken;
  bool get isAuthenticated => _authenticated.value;
  Stream<bool> get authenticatedStream => _authenticated.stream;
  @override
  Future<void> onInit() async {
    await _storage.init();
    _accessToken.value = _storage.accessToken;
    final hasToken = _accessToken.value?.isNotEmpty ?? false;
    _updateAuthState(hasToken);
    if (hasToken) {
      Future.microtask(_dispatchLoginSideEffects);
    }
    super.onInit();
  }
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    log(
      '[AuthService] Saving tokens. hasRefresh=${refreshToken?.isNotEmpty == true}',
    );
    await _storage.save(accessToken: accessToken, refreshToken: refreshToken);
    _accessToken.value = accessToken;
    _updateAuthState(true);
    Future.microtask(_dispatchLoginSideEffects);
  }

  Future<void> _dispatchLoginSideEffects() async {
    final token = _accessToken.value;
    if (token != null && token.isNotEmpty) {
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().connectIfNeeded();
      }
      await _realtime.startAll();
      await handlePostLoginRealtime();
    }
  }

  Future<void> clearTokens() async {
    await _storage.clear();
    _accessToken.value = null;
    _updateAuthState(false);
  }
Future<void> handlePostLoginRealtime() async {
    // 1- socket reconnect
    if (Get.isRegistered<RealtimeController>(tag: 'artisan')) {
      await Get.find<RealtimeController>(tag: 'artisan').reconnect();
    }

    // 2- artisan realtime controller
    if (Get.isRegistered<ArtisanController>()) {
      await Get.find<ArtisanController>().start(); // يعيد join و listeners
    }

    // 3- لو عندك chat realtime service
    if (Get.isRegistered<ChatRealtimeService>(tag: 'artisan')) {
      await Get.find<ChatRealtimeService>(tag: 'artisan').start();
    }

    // 4- لو عندك notifications
    if (Get.isRegistered<NotificationsRealtimeService>()) {
      await Get.find<NotificationsRealtimeService>().start();
    }
  }

  /// Singleton refresh execution – ما يتنفذش مرتين في نفس الوقت
  Future<bool> refreshTokens() {
    _refreshFuture ??= _runRefreshFlow()
        .then((value) => value)
        .catchError((error, stack) {
          log('[AuthService] Refresh failed: $error', stackTrace: stack);
          _shouldLogoutAfterRefreshFailure = false;
          return false;
        })
        .whenComplete(() {
          _refreshFuture = null;
        });

    return _refreshFuture!;
  }

  Future<bool> _runRefreshFlow() async {
    _shouldLogoutAfterRefreshFailure = true;

    // ❗❗ استخدم refreshToken فقط – لا fallback على accessToken
    final candidate = refreshToken;
    if (candidate == null || candidate.isEmpty) {
      log('[AuthService] No refresh token available. Skipping refresh.');
      return false;
    }

    try {
      log('[AuthService] Running refresh flow with refresh token.');
      final response = await _refreshDio.post(
        ApiEndpoints.refresh,
        options: Options(headers: {'Authorization': 'Bearer $candidate'}),
      );

      final Map<String, dynamic>? body = response.data is Map<String, dynamic>
          ? response.data
          : null;
      if (body == null) {
        log('[AuthService] Refresh body is null.');
        return false;
      }

      final newToken = _extractToken(body);
      final newRefresh = _extractRefreshToken(body);

      if (newToken != null && newToken.isNotEmpty) {
        await saveTokens(accessToken: newToken, refreshToken: newRefresh);
        if (Get.isRegistered<RealtimeController>(tag: 'artisan')) {
          await Get.find<RealtimeController>(tag: 'artisan').reconnect();
        }

        if (Get.isRegistered<ArtisanController>()) {
          await Get.find<ArtisanController>().start();
        }
        _shouldLogoutAfterRefreshFailure = false;
        log('[AuthService] Refresh success.');
        return true;
      }

      log('[AuthService] Refresh response did not contain a new token.');
    } on DioException catch (error) {
      final status = error.response?.statusCode;

      final isNetworkTimeout =
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout;

      final isNetworkIssue =
          isNetworkTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;

      if (isNetworkIssue && status == null) {
        log(
          '[AuthService] Refresh skipped logout due to network/timeout: $error',
        );
        _shouldLogoutAfterRefreshFailure = false;
        return false;
      }

      log('[AuthService] Refresh error: $error');
      return false;
    } catch (error) {
      log('[AuthService] Refresh error: $error');
      return false;
    }

    return false;
  }

  static String? _extractToken(Map<String, dynamic> response) {
    final direct =
        response['token'] ??
        response['accessToken'] ??
        response['access_token'];
    if (direct is String && direct.isNotEmpty) return direct;

    if (response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      final nested = data['token'] ?? data['accessToken'];
      if (nested is String && nested.isNotEmpty) return nested;
    }

    return null;
  }

  static String? _extractRefreshToken(Map<String, dynamic> response) {
    final direct =
        response['refreshToken'] ??
        response['refresh_token'] ??
        response['refresh'];
    if (direct is String && direct.isNotEmpty) return direct;

    if (response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      final nested =
          data['refreshToken'] ?? data['refresh_token'] ?? data['refresh'];
      if (nested is String && nested.isNotEmpty) return nested;
    }

    return null;
  }

  /// Listener للمكان اللي محتاج يعرف التوكين اتغيّر
  void registerAccessTokenListener(void Function(String?) listener) {
    ever<String?>(_accessToken, listener);
  }

  Future<void> waitForAuthentication() async {
    if (_authenticated.value) return;
    final completer = Completer<void>();
    late final StreamSubscription<bool> sub;

    sub = _authenticated.stream.listen((value) {
      if (value && !completer.isCompleted) {
        completer.complete();
        sub.cancel();
      }
    });

    await completer.future;
  }

  void whenAuthenticated(void Function() callback) {
    ever<bool>(_authenticated, (value) {
      if (value == true) callback();
    });
  }

  /// يُستخدم من الـ Socket أو أماكن تانية غير HTTP
  Future<void> handleUnauthorized({
    bool skipRefresh = false,
    bool fromSocket = false,
    bool forceLogout = false,
  }) async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    if (!skipRefresh && !forceLogout) {
      final refreshed = await refreshTokens();
      if (refreshed) {
        _isHandlingUnauthorized = false;
        return;
      }

      if (!_shouldLogoutAfterRefreshFailure) {
        _isHandlingUnauthorized = false;
        return;
      }
    } else if (!forceLogout && !_shouldLogoutAfterRefreshFailure) {
      _isHandlingUnauthorized = false;
      return;
    }

    await _performLogout();
    _isHandlingUnauthorized = false;
  }

  Future<void> _performLogout() async {
    if (_isPerformingLogout) return;
    _isPerformingLogout = true;
    _shouldLogoutAfterRefreshFailure = false;

    await _realtime.stopAll();
    if (Get.isRegistered<SocketService>()) {
      await Get.find<SocketService>().disconnect();
    }

    await clearTokens();
    // Return to global chooser after logout
    if (Get.isRegistered<AppModeController>()) {
      final switched = await AppModeController.to.resetToChooser();
      if (switched) {
        Get.offAll(() => const ChooseUserTypeView());
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } else {
      Get.offAllNamed(AppRoutes.login);
    }

    _isPerformingLogout = false;
  }

  Future<bool> verifyConnection() async {
    try {
      final reachable = await _connectivity.verifyServerReachable();
      if (!reachable) return false;
      await ApiClient.instance.get(ApiEndpoints.me);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Debug فقط
  Future<void> debugCheckRefreshTokenEndpoint() async {
    final candidate = refreshToken;
    if (candidate == null || candidate.isEmpty) {
      log('[AuthService] No token available for refresh check.');
      return;
    }

    try {
      final response = await _refreshDio.post(
        ApiEndpoints.refresh,
        options: Options(headers: {'Authorization': 'Bearer $candidate'}),
      );
      log(
        '[AuthService] Refresh check response: ${response.statusCode} ${response.data}',
      );
    } on DioException catch (error) {
      log(
        '[AuthService] Refresh check failed (${error.response?.statusCode}): ${error.response?.data}',
      );
    } catch (error) {
      log('[AuthService] Refresh check unexpected error: $error');
    }
  }

  void _updateAuthState(bool newValue) {
    final changed = _authenticated.value != newValue;
    if (changed) {
      _authenticated.value = newValue;
      return;
    }
    _authenticated.refresh();
  }
}


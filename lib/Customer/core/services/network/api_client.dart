import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get/get.dart' hide Response;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:usta/app/services/backend_status_service.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/core/realtime/realtime_controller.dart';
import 'package:usta/Customer/core/services/connectivity/connectivity_service.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/core/utils/constants/api_endpoints.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/app/app_mode_controller.dart';

class ApiClient extends GetxService {
  late final Dio _dio;
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');
  late final BackendStatusService _backendStatus;

  bool _isRefreshing = false;
  Completer<_RefreshResult>? _refreshCompleter;

  static const _retryFlag = '__retried';
  static const _skipAuthFailureFlag = '__skip_auth_failure';

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _backendStatus = Get.isRegistered<BackendStatusService>()
        ? Get.find<BackendStatusService>()
        : Get.put(BackendStatusService(), permanent: true);
    _backendStatus.configure(baseUrl: ApiEndpoints.baseUrl);
    final config = AppConfig.instance;
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => (status ?? 0) < 300,
      ),
    );

    if (!kIsWeb && config.allowBadCertificates) {
      final adapter = _dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        };
      }
    }

    _dio.interceptors.add(_authInterceptor());
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          responseHeader: false,
          requestBody: false,
          responseBody: false,
          compact: true,
        ),
      );
    }
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _storage.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode ?? 0;
        if (_shouldRefresh(status, error.requestOptions)) {
          final refreshResult = await _tryRefreshToken();
          if (refreshResult == _RefreshResult.success) {
            try {
              final cloned = await _retry(error.requestOptions);
              return handler.resolve(cloned);
            } catch (_) {}
          }
          if (refreshResult == _RefreshResult.deferred) {
            error.requestOptions.extra[_skipAuthFailureFlag] = true;
          }
        }
        return handler.next(error);
      },
    );
  }

  bool _shouldRefresh(int statusCode, RequestOptions request) {
    if (statusCode != 401) return false;
    if (_isPublicAuthEndpoint(request)) return false;
    if (_isRefreshEndpoint(request)) return false;
    if (request.extra[_retryFlag] == true) return false;
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    return true;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
      validateStatus: requestOptions.validateStatus,
      extra: {...requestOptions.extra, _retryFlag: true},
    );

    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers ??= {};
      options.headers!['Authorization'] = 'Bearer $token';
    }

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<_RefreshResult> _tryRefreshToken() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.clear();
      _handleSessionExpired('انتهت صلاحية الجلسة، رجاء سجّل الدخول من جديد'.tr);
      return _RefreshResult.failed;
    }

    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(_RefreshResult.failed);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<_RefreshResult>();

    try {
      final config = AppConfig.instance;
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: config.connectTimeout,
          receiveTimeout: config.receiveTimeout,
          sendTimeout: config.sendTimeout,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refresh,
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        final access = _extractAccessToken(response.data);
        final refresh = _extractRefreshToken(response.data) ?? refreshToken;
        if (access != null && access.isNotEmpty) {
          await _storage.save(accessToken: access, refreshToken: refresh);
          if (Get.isRegistered<RealtimeController>(tag: 'customer')) {
            Get.find<RealtimeController>(tag: 'customer').setAuthToken(access);
          }
          _refreshCompleter?.complete(_RefreshResult.success);
          return _RefreshResult.success;
        }
      }

      await _storage.clear();
      _refreshCompleter?.complete(_RefreshResult.failed);
      _handleSessionExpired('تم تسجيل الخروج، الرجاء الدخول مرة أخرى'.tr);
      return _RefreshResult.failed;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final isNetworkTimeout =
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      final isNetworkIssue =
          isNetworkTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
      if (isNetworkIssue && status == null) {
        _markOffline();
        _refreshCompleter?.complete(_RefreshResult.deferred);
        return _RefreshResult.deferred;
      }
      await _storage.clear();
      _refreshCompleter?.complete(_RefreshResult.failed);
      _handleSessionExpired('تعذر تجديد الجلسة، يرجى إعادة تسجيل الدخول'.tr);
      return _RefreshResult.failed;
    } catch (_) {
      await _storage.clear();
      _refreshCompleter?.complete(_RefreshResult.failed);
      _handleSessionExpired('تعذر تجديد الجلسة، يرجى إعادة تسجيل الدخول'.tr);
      return _RefreshResult.failed;
    } finally {
      _isRefreshing = false;
    }
  }

  String? _extractAccessToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      final direct =
          data['token'] ?? data['accessToken'] ?? data['access_token'];
      if (direct is String && direct.isNotEmpty) return direct;
      if (data['data'] is Map<String, dynamic>) {
        final nested =
            (data['data'] as Map<String, dynamic>)['token'] ??
            (data['data'] as Map<String, dynamic>)['accessToken'] ??
            (data['data'] as Map<String, dynamic>)['access_token'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  String? _extractRefreshToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      final direct =
          data['refreshToken'] ?? data['refresh_token'] ?? data['refresh'];
      if (direct is String && direct.isNotEmpty) return direct;
      if (data['data'] is Map<String, dynamic>) {
        final nested =
            (data['data'] as Map<String, dynamic>)['refreshToken'] ??
            (data['data'] as Map<String, dynamic>)['refresh_token'] ??
            (data['data'] as Map<String, dynamic>)['refresh'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  ApiException _wrapDioError(dynamic error) {
    DioException? dioError;
    if (error is DioException) {
      dioError = error;
    } else if (error is ApiException) {
      return error;
    }

    final status = dioError?.response?.statusCode;
    dynamic details = dioError?.response?.data;
    String message = 'Something went wrong';

    if (dioError != null) {
      final contentType = dioError.response?.headers.value('content-type');
      if (looksLikeServerHtmlPayload(
        dioError.response?.data,
        contentType: contentType,
      )) {
        () async {
          await _backendStatus.reportFailure(
            statusCode: dioError?.response?.statusCode,
            data: dioError?.response?.data,
            contentType: contentType,
            error: dioError,
          );
        }();
        return ApiException(
          message: 'الخدمة غير متاحة مؤقتًا، حاول مرة أخرى بعد قليل'.tr,
          statusCode: dioError.response?.statusCode,
          details: dioError.response?.data,
        );
      }
      if (dioError.response?.data is Map<String, dynamic>) {
        final data = dioError.response!.data as Map<String, dynamic>;
        final serverMessage = data['message'] ?? data['error'] ?? data['msg'];
        if (serverMessage is String && serverMessage.isNotEmpty) {
          message = serverMessage;
        }
        details = data['details'] ?? details ?? data;
      } else if (dioError.response?.data is String) {
        message = dioError.response?.data as String;
      } else if (dioError.message != null && dioError.message!.isNotEmpty) {
        message = dioError.message!;
      }

      if (dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.sendTimeout) {
        message = 'Connection timed out, please try again';
        _markOffline();
        () async {
          await _backendStatus.reportFailure(error: dioError);
        }();
      } else if (dioError.type == DioExceptionType.connectionError) {
        message = 'Network connection failed, please check your internet';
        _markOffline();
        () async {
          await _backendStatus.reportFailure(error: dioError);
        }();
      } else if (dioError.type == DioExceptionType.unknown) {
        final err = dioError.error;
        if (err is HandshakeException) {
          message =
              'SSL handshake failed. Check server certificate or enable ALLOW_BAD_SSL for testing.';
        } else if (err is SocketException) {
          message = 'Network connection failed, please check your internet';
          _markOffline();
          () async {
            await _backendStatus.reportFailure(error: dioError);
          }();
        }
      }
    } else if (error is Exception) {
      message = error.toString();
    }

    return ApiException(
      message: message,
      statusCode: status,
      details: details ?? error,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: query,
        options: options,
      );
      _throwIfFailed(response);
      _markOnline();
      return response;
    } on DioException catch (e) {
      final apiError = _wrapDioError(e);
      if (_handleAuthFailure(apiError, request: e.requestOptions)) {
        return Response<T>(
          requestOptions: e.requestOptions,
          statusCode: apiError.statusCode,
          data: null,
        );
      }
      throw apiError;
    } on ApiException catch (e) {
      if (_handleAuthFailure(e, request: RequestOptions(path: path))) {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          statusCode: e.statusCode,
          data: null,
        );
      }
      throw e;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
      );
      _throwIfFailed(response);
      _markOnline();
      return response;
    } on DioException catch (e) {
      final apiError = _wrapDioError(e);
      if (_handleAuthFailure(apiError, request: e.requestOptions)) {
        return Response<T>(
          requestOptions: e.requestOptions,
          statusCode: apiError.statusCode,
          data: null,
        );
      }
      throw apiError;
    } on ApiException catch (e) {
      if (_handleAuthFailure(e, request: RequestOptions(path: path))) {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          statusCode: e.statusCode,
          data: null,
        );
      }
      throw e;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
      );
      _throwIfFailed(response);
      _markOnline();
      return response;
    } on DioException catch (e) {
      final apiError = _wrapDioError(e);
      if (_handleAuthFailure(apiError, request: e.requestOptions)) {
        return Response<T>(
          requestOptions: e.requestOptions,
          statusCode: apiError.statusCode,
          data: null,
        );
      }
      throw apiError;
    } on ApiException catch (e) {
      if (_handleAuthFailure(e, request: RequestOptions(path: path))) {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          statusCode: e.statusCode,
          data: null,
        );
      }
      throw e;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
      );
      _throwIfFailed(response);
      _markOnline();
      return response;
    } on DioException catch (e) {
      final apiError = _wrapDioError(e);
      if (_handleAuthFailure(apiError, request: e.requestOptions)) {
        return Response<T>(
          requestOptions: e.requestOptions,
          statusCode: apiError.statusCode,
          data: null,
        );
      }
      throw apiError;
    } on ApiException catch (e) {
      if (_handleAuthFailure(e, request: RequestOptions(path: path))) {
        return Response<T>(
          requestOptions: RequestOptions(path: path),
          statusCode: e.statusCode,
          data: null,
        );
      }
      throw e;
    }
  }

  void _throwIfFailed(Response response) {
    final status = response.statusCode ?? 0;
    final contentType = response.headers.value('content-type');
    if (status >= 200 && status < 300) {
      if (looksLikeServerHtmlPayload(response.data, contentType: contentType)) {
        () async {
          await _backendStatus.reportFailure(
            statusCode: status,
            data: response.data,
            contentType: contentType,
          );
        }();
        throw ApiException(
          message: 'الخدمة غير متاحة مؤقتًا، حاول مرة أخرى بعد قليل'.tr,
          statusCode: status,
          details: response.data,
        );
      }
      return;
    }
    if (status == 401) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Unauthorized',
      );
    }
    if (status == 403) {
      final error = ApiException(
        message: response.data is Map<String, dynamic>
            ? (response.data['message'] ??
                  response.data['error'] ??
                  'Your account is blocked by admin')
            : 'Your account is blocked by admin',
        statusCode: status,
        details: response.data,
      );
      _handleAuthFailure(error, request: response.requestOptions);
      throw error;
    }
    () async {
      await _backendStatus.reportFailure(
        statusCode: status,
        data: response.data,
        contentType: contentType,
      );
    }();
    final error = ApiException(
      message: response.data is Map<String, dynamic>
          ? (response.data['message'] ??
                response.data['error'] ??
                (isBackendUnavailableStatus(status)
                    ? 'الخدمة غير متاحة مؤقتًا، حاول مرة أخرى بعد قليل'.tr
                    : 'Request failed'))
          : 'Request failed',
      statusCode: status,
      details: response.data,
    );
    throw error;
  }

  void _handleSessionExpired([String? message]) {
    if (_handlingSession) return;
    _handlingSession = true;
    if (Get.isRegistered<RealtimeController>(tag: 'customer')) {
      Get.find<RealtimeController>(tag: 'customer').disconnect();
    }
    final navigatorKey = Get.key;
    if (navigatorKey == null || navigatorKey.currentState == null) {
      _handlingSession = false;
      return;
    }
    Future.microtask(() {
      try {
        _resetToChooserSafely();
        AppSnackBar.show(
          'انتهت الجلسة'.tr,
          message ?? 'برجاء تسجيل الدخول مرة أخرى'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } finally {
        _handlingSession = false;
      }
    });
  }

  bool _isCustomerModeActive() {
    if (!Get.isRegistered<AppModeController>()) return true;
    final controller = AppModeController.to;
    if (controller.isBootstrapping.value) return false;
    return controller.mode.value == AppUserType.customer;
  }

  bool _isNavigatorReady() {
    final navigatorKey = Get.key;
    return navigatorKey != null && navigatorKey.currentState != null;
  }

  bool _hasAnySessionToken() {
    final access = _storage.accessToken;
    if (access != null && access.isNotEmpty) return true;
    final refresh = _storage.refreshToken;
    return refresh != null && refresh.isNotEmpty;
  }

  void _navigateToLoginSafely() {
    _resetToChooserSafely();
  }

  void _resetToChooserSafely() {
    if (!_isCustomerModeActive()) return;
    if (Get.isRegistered<AppModeController>() &&
        AppModeController.to.switcherAttached) {
      AppModeController.to.resetToChooser();
      return;
    }
    if (_isNavigatorReady()) {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
      return;
    }
    _scheduleLoginNavigation();
  }

  void _scheduleLoginNavigation() {
    if (_pendingLoginNavigation) return;
    _pendingLoginNavigation = true;
    () async {
      const maxAttempts = 10;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        await Future.delayed(const Duration(milliseconds: 100));
        // Stop delayed navigation if app switched away from customer mode.
        if (!_isCustomerModeActive()) {
          break;
        }
        // Stop delayed navigation when session is already gone.
        if (!_hasAnySessionToken()) {
          break;
        }
        if (!_isNavigatorReady()) continue;
        if (Get.currentRoute != AppRoutes.login) {
          Get.offAllNamed(AppRoutes.login);
        }
        break;
      }
      _pendingLoginNavigation = false;
    }();
  }

  bool _handlingSession = false;
  bool _handlingAuthFailure = false;
  bool _pendingLoginNavigation = false;

  void _markOnline() {
    _backendStatus.markAvailable();
    if (!Get.isRegistered<ConnectivityService>(tag: 'customer')) return;
    final svc = Get.find<ConnectivityService>(tag: 'customer');
    if (!svc.isOnline.value) {
      svc.setOnline(true, notify: true);
    }
  }

  void _markOffline() {
    if (!Get.isRegistered<ConnectivityService>(tag: 'customer')) return;
    final svc = Get.find<ConnectivityService>(tag: 'customer');
    svc.checkNow(force: true);
  }

  bool _handleAuthFailure(ApiException error, {RequestOptions? request}) {
    final status = error.statusCode;
    if (status != 401 && status != 403) return false;
    if (request != null && _isPublicAuthEndpoint(request)) return false;
    if (request?.extra[_skipAuthFailureFlag] == true) return false;
    if (!_isCustomerModeActive()) return false;
    if (!_hasAnySessionToken()) return false;
    if (_handlingAuthFailure) return true;
    _handlingAuthFailure = true;

    final message = error.message.isNotEmpty
        ? error.message
        : (status == 403
              ? 'تم حظر حسابك بواسطة الإدارة'.tr
              : 'انتهت صلاحية الجلسة، رجاء سجّل الدخول من جديد'.tr);

    Future.microtask(() async {
      try {
        if (Get.isRegistered<AuthController>(tag: 'customer')) {
          await Get.find<AuthController>(tag: 'customer').logout(remote: false);
        } else {
          await _storage.clear();
          _navigateToLoginSafely();
        }
        AppSnackBar.show(
          'تنبيه'.tr,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } finally {
        _handlingAuthFailure = false;
      }
    });
    return true;
  }

  static const List<String> _publicAuthPaths = [
    '/customer/login',
    '/customer/signup',
    '/customer/verify',
    '/customer/verify-reset-code',
    '/customer/forgot-password',
    '/customer/resend-verification',
  ];

  bool _isPublicAuthEndpoint(RequestOptions request) {
    final path = request.path;
    for (final fragment in _publicAuthPaths) {
      if (path.contains(fragment)) return true;
    }
    return false;
  }

  bool _isRefreshEndpoint(RequestOptions request) {
    final path = request.path;
    if (path.contains(ApiEndpoints.refresh)) return true;
    return path.contains('/customer/refresh-token');
  }
}

enum _RefreshResult { success, failed, deferred }

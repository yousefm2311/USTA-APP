import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:get/get.dart' hide Response;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
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
import 'package:usta/app/choose_user_type_view.dart';

class ApiClient extends GetxService {
  late final Dio _dio;
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
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
          requestBody: true,
          responseBody: true,
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
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            try {
              final cloned = await _retry(error.requestOptions);
              return handler.resolve(cloned);
            } catch (_) {
            }
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

  static const _retryFlag = '__retried';

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
      extra: {
        ...requestOptions.extra,
        _retryFlag: true,
      },
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

  Future<bool> _tryRefreshToken() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.clear();
      _handleSessionExpired(
        'انتهت صلاحية الجلسة، رجاء سجّل الدخول من جديد'.tr,
      );
      return false;
    }

    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

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
          _refreshCompleter?.complete(true);
          return true;
        }
      }

      await _storage.clear();
      _refreshCompleter?.complete(false);
      _handleSessionExpired('تم تسجيل الخروج، الرجاء الدخول مرة أخرى'.tr);
      return false;
    } catch (_) {
      await _storage.clear();
      _refreshCompleter?.complete(false);
      _handleSessionExpired('تعذر تجديد الجلسة، يرجى إعادة تسجيل الدخول'.tr);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  String? _extractAccessToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      final direct = data['token'] ?? data['accessToken'] ?? data['access_token'];
      if (direct is String && direct.isNotEmpty) return direct;
      if (data['data'] is Map<String, dynamic>) {
        final nested = (data['data'] as Map<String, dynamic>)['token'] ??
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
        final nested = (data['data'] as Map<String, dynamic>)['refreshToken'] ??
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
      } else if (dioError.type == DioExceptionType.connectionError) {
        message = 'Network connection failed, please check your internet';
        _markOffline();
      } else if (dioError.type == DioExceptionType.unknown) {
        final err = dioError.error;
        if (err is HandshakeException) {
          message =
              'SSL handshake failed. Check server certificate or enable ALLOW_BAD_SSL for testing.';
        } else if (err is SocketException) {
          message = 'Network connection failed, please check your internet';
          _markOffline();
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
    if (status >= 200 && status < 300) return;
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
    final error = ApiException(
      message: response.data is Map<String, dynamic>
          ? (response.data['message'] ??
              response.data['error'] ??
              'Request failed')
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

  bool _isNavigatorReady() {
    final navigatorKey = Get.key;
    return navigatorKey != null && navigatorKey.currentState != null;
  }

  void _navigateToLoginSafely() {
    _resetToChooserSafely();
  }

  void _resetToChooserSafely() {
    if (Get.isRegistered<AppModeController>()) {
      AppModeController.to.resetToChooser().then((switched) {
        if (!switched) {
          if (Get.currentRoute != AppRoutes.login) {
            Get.offAllNamed(AppRoutes.login);
          }
        } else {
          Get.offAll(() => const ChooseUserTypeView());
        }
      });
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





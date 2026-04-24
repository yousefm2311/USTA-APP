// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:get/get.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';
// import 'package:usta/Artisan/core/services/auth_service.dart';
// import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

// class ApiException implements Exception {
//   final String message;
//   final int? statusCode;

//   ApiException(this.message, {this.statusCode});

//   @override
//   String toString() => message;
// }

// /// Global HTTP client that always injects the current Bearer token.
// class ApiClient extends GetxService {
//   ApiClient();

//   static ApiClient get instance => Get.find<ApiClient>(tag: 'artisan');
//   static ApiClient get to => instance;

//   late final Dio _dio;
//   late final AuthService _authService;

//   @override
//   Future<void> onInit() async {
//     super.onInit();
//     _authService = Get.find<AuthService>();
//     _dio = Dio(BaseOptions(
//       baseUrl: ApiEndpoints.baseUrl,
//       connectTimeout: const Duration(seconds: 15),
//       receiveTimeout: const Duration(seconds: 15),
//       responseType: ResponseType.json,
//       headers: const {
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//       },
//     ))
//       ..interceptors.addAll([
//         PrettyDioLogger(
//           requestHeader: true,
//           requestBody: true,
//           responseBody: true,
//           compact: true,
//         ),
//         InterceptorsWrapper(
//           onRequest: _onRequest,
//           onError: _onError,
//         ),
//       ]);
//   }

//   Future<void> _onRequest(
//     RequestOptions options,
//     RequestInterceptorHandler handler,
//   ) async {
//     final token = _authService.accessToken;
//     if (token != null && token.isNotEmpty) {
//       options.headers['Authorization'] = 'Bearer $token';
//     }
//     handler.next(options);
//   }

//   Future<void> _onError(
//     DioException error,
//     ErrorInterceptorHandler handler,
//   ) async {
//     final status = error.response?.statusCode;
//     final alreadyRetried = error.requestOptions.extra['retried'] == true;
//     final isRefreshCall = error.requestOptions.path.contains('refresh');

//     if (status == 401 && !alreadyRetried && !isRefreshCall) {
//       error.requestOptions.extra['retried'] = true;
//       final refreshed = await _authService.refreshTokens();

//       if (refreshed) {
//         final token = _authService.accessToken;
//         if (token != null && token.isNotEmpty) {
//           error.requestOptions.headers['Authorization'] = 'Bearer $token';
//         }
//         try {
//           final retryResponse = await _dio.fetch(error.requestOptions);
//           return handler.resolve(retryResponse);
//         } on DioException catch (retryError) {
//           return handler.next(retryError);
//         }
//       } else {
//         await _authService.handleUnauthorized(skipRefresh: true);
//       }
//     }

//     handler.next(error);
//   }

//   Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
//     return _request(method: 'GET', path: path, queryParameters: query);
//   }

//   Future<dynamic> post(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? query,
//   }) {
//     return _request(
//       method: 'POST',
//       path: path,
//       data: data,
//       queryParameters: query,
//     );
//   }

//   Future<dynamic> put(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? query,
//   }) {
//     return _request(
//       method: 'PUT',
//       path: path,
//       data: data,
//       queryParameters: query,
//     );
//   }

//   Future<dynamic> delete(
//     String path, {
//     dynamic data,
//     Map<String, dynamic>? query,
//   }) {
//     return _request(
//       method: 'DELETE',
//       path: path,
//       data: data,
//       queryParameters: query,
//     );
//   }

//   Future<dynamic> _request({
//     required String method,
//     required String path,
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//   }) async {
//     try {
//       final response = await _dio.request(
//         path,
//         data: data,
//         queryParameters: queryParameters,
//         options: Options(method: method),
//       );
//       return response.data ?? {};
//     } on DioException catch (error) {
//       final message = _formatError(error);
//       throw ApiException(message, statusCode: error.response?.statusCode);
//     } catch (_) {
//       throw ApiException('Unexpected error, please try again.');
//     }
//   }

//   String _formatError(DioException error) {
//     final response = error.response;
//     String? extracted;
//     if (response?.data is Map<String, dynamic>) {
//       final data = response!.data as Map<String, dynamic>;
//       extracted =
//           (data['message'] ?? data['error'] ?? data['msg'])?.toString();
//     } else if (response?.data is String) {
//       extracted = response!.data.toString();
//     }
//     extracted ??= error.message;
//     if (extracted == null ||
//         extracted.trim().isEmpty ||
//         extracted.toLowerCase().contains('message not found')) {
//       final code = response?.statusCode;
//       extracted = code != null
//           ? 'Request failed ($code)'
//           : 'Unexpected error, please try again.';
//     }
//     return extracted;
//   }

//   Future<void> init() async {
//     // kept for compatibility
//   }

//   dynamic unwrapData(dynamic response) {
//     if (response is Map<String, dynamic>) {
//       if (response['data'] is Map<String, dynamic> ||
//           response['data'] is List) {
//         return response['data'];
//       }
//       if (response.containsKey('data')) {
//         return response['data'];
//       }
//     }
//     return response;
//   }
// }

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:usta/app/services/backend_status_service.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/services/network/auth_retry_interceptor.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.statusCode, this.code, this.details});

  @override
  String toString() => message;
}

class ApiClient extends GetxService {
  ApiClient();

  static ApiClient get instance => Get.find<ApiClient>(tag: 'artisan');
  static ApiClient get to => instance;

  late final Dio _dio;
  late final AuthService _authService;
  late final BackendStatusService _backendStatus;

  @override
  Future<void> onInit() async {
    super.onInit();
    _authService = Get.find<AuthService>();
    _backendStatus = Get.isRegistered<BackendStatusService>()
        ? Get.find<BackendStatusService>()
        : Get.put(BackendStatusService(), permanent: true);
    _backendStatus.configure(baseUrl: ApiEndpoints.baseUrl);

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    /// Logging (debug only, avoid leaking secrets)
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          compact: true,
        ),
      );
    }

    /// ⭐ أهم إضافة لحل refresh / retry بدون مشاكل
    _dio.interceptors.add(
      AuthRetryInterceptor(dio: _dio, authService: _authService),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _request(method: 'GET', path: path, queryParameters: query);
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: query,
    );
  }

  Future<dynamic> postMultipart(
    String path, {
    required dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: query,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: query,
    );
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: query,
    );
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: query,
    );
  }

  /// ⭐ نفس طريقة الـ request الموجودة عندك (ما غيرتهاش)
  Future<dynamic> _request({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
      );
      final contentType = response.headers.value('content-type');
      if (looksLikeServerHtmlPayload(response.data, contentType: contentType)) {
        await _backendStatus.reportFailure(
          statusCode: response.statusCode,
          data: response.data,
          contentType: contentType,
        );
        throw ApiException(
          'الخدمة غير متاحة مؤقتًا، حاول مرة أخرى بعد قليل',
          statusCode: response.statusCode,
          code: 'server_unavailable',
          details: {'contentType': contentType},
        );
      }
      _backendStatus.markAvailable();
      return response.data ?? {};
    } on DioException catch (error) {
      final contentType = error.response?.headers.value('content-type');
      await _backendStatus.reportFailure(
        statusCode: error.response?.statusCode,
        data: error.response?.data,
        contentType: contentType,
        error: error,
      );
      if (looksLikeServerHtmlPayload(
            error.response?.data,
            contentType: contentType,
          ) ||
          isBackendUnavailableStatus(error.response?.statusCode)) {
        throw ApiException(
          'الخدمة غير متاحة مؤقتًا، حاول مرة أخرى بعد قليل',
          statusCode: error.response?.statusCode,
          code: 'server_unavailable',
          details: _toDetailsMap(error.response?.data),
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw ApiException('Request timed out', code: 'network_timeout');
      }
      if (error.type == DioExceptionType.connectionError) {
        throw ApiException('Network unavailable', code: 'network_unavailable');
      }
      final payload = _extractErrorPayload(error);
      throw ApiException(
        payload.message,
        statusCode: error.response?.statusCode,
        code: payload.code,
        details: payload.details,
      );
    } catch (_) {
      throw ApiException('Unexpected error, please try again.');
    }
  }

  Map<String, dynamic>? _toDetailsMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// ⭐ نفس formatter اللي عندك
  ({String message, String? code, Map<String, dynamic>? details})
  _extractErrorPayload(DioException error) {
    final response = error.response;
    String? extracted;
    String? code;
    Map<String, dynamic>? details;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      extracted = (data['message'] ?? data['error'] ?? data['msg'])?.toString();
      code = data['code']?.toString();
      final rawDetails = data['details'];
      if (rawDetails is Map<String, dynamic>) {
        details = rawDetails;
      } else if (rawDetails is Map) {
        details = rawDetails.cast<String, dynamic>();
      }
    } else if (response?.data is String) {
      extracted = response!.data.toString();
    }

    extracted ??= error.message;

    if (extracted == null ||
        extracted.trim().isEmpty ||
        extracted.toLowerCase().contains('message not found')) {
      final statusCode = response?.statusCode;
      extracted = code != null
          ? 'Request failed ($code)'
          : statusCode != null
          ? 'Request failed ($statusCode)'
          : 'Unexpected error, please try again.';
    }

    return (message: extracted, code: code, details: details);
  }

  /// compatibility
  Future<void> init() async {}

  dynamic unwrapData(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic> ||
          response['data'] is List) {
        return response['data'];
      }
      if (response.containsKey('data')) {
        return response['data'];
      }
    }
    return response;
  }
}

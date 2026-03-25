import 'dart:async';

import 'package:dio/dio.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';

class AuthRetryInterceptor extends Interceptor {
  final Dio dio;
  final AuthService authService;

  bool _refreshing = false;
  final List<Completer<Response>> _pending = [];

  AuthRetryInterceptor({required this.dio, required this.authService});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = authService.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final request = err.requestOptions;

    if (status != 401) {
      return handler.next(err);
    }

    if (request.extra['retry'] == true) {
      await authService.handleUnauthorized(
        skipRefresh: true,
        forceLogout: true,
      );
      return handler.reject(err);
    }

    if (request.path.contains('/login')) {
      // Login failures should not trigger logout/navigation.
      return handler.reject(err);
    }

    if (request.path.contains('/refresh')) {
      await authService.handleUnauthorized(
        skipRefresh: true,
        forceLogout: true,
      );
      return handler.reject(err);
    }

    if (_refreshing) {
      final completer = Completer<Response>();
      _pending.add(completer);
      try {
        final resp = await completer.future;
        return handler.resolve(resp);
      } catch (_) {
        return handler.reject(err);
      }
    }

    _refreshing = true;
    var refreshed = false;
    try {
      refreshed = await authService.refreshTokens();
    } catch (_) {
      refreshed = false;
    } finally {
      _refreshing = false;
    }

    if (!refreshed) {
      for (final c in _pending) {
        if (!c.isCompleted) {
          c.completeError(err);
        }
      }
      _pending.clear();
      if (!authService.logoutRequiredAfterRefreshFailure) {
        return handler.next(err);
      }
      await authService.handleUnauthorized(
        skipRefresh: true,
        forceLogout: true,
      );
      return handler.reject(err);
    }

    for (final c in _pending) {
      if (!c.isCompleted) {
        _retry(request).then(
          (value) => c.complete(value),
          onError: (e) => c.completeError(e),
        );
      }
    }
    _pending.clear();

    try {
      final retryResp = await _retry(request);
      return handler.resolve(retryResp);
    } catch (e) {
      if (e is DioException &&
          e.response?.statusCode == 401 &&
          authService.logoutRequiredAfterRefreshFailure) {
        await authService.handleUnauthorized(
          skipRefresh: true,
          forceLogout: true,
        );
      }
      return handler.reject(e is DioException ? e : err);
    }
  }

  Future<Response> _retry(RequestOptions o) async {
    final newToken = authService.accessToken;
    final headers = Map<String, dynamic>.from(o.headers);
    final extra = Map<String, dynamic>.from(o.extra);
    extra['retry'] = true;

    if (newToken != null && newToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $newToken';
    }

    return dio.request(
      o.path,
      data: o.data,
      queryParameters: o.queryParameters,
      options: Options(
        method: o.method,
        headers: headers,
        extra: extra,
        responseType: o.responseType,
        contentType: o.contentType,
        followRedirects: o.followRedirects,
        validateStatus: o.validateStatus,
        receiveDataWhenStatusError: o.receiveDataWhenStatusError,
      ),
      cancelToken: o.cancelToken,
      onSendProgress: o.onSendProgress,
      onReceiveProgress: o.onReceiveProgress,
    );
  }
}

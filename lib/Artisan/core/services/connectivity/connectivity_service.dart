import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

class ConnectivityService extends GetxService {
  late final Dio _dio;
  DateTime? _lastCheckAt;
  bool _lastResult = true;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 2),
      receiveTimeout: const Duration(seconds: 2),
    ));
  }

  Future<bool> verifyServerReachable({String? token}) async {
    // Throttle to avoid hammering the backend with repeated /api pings.
    final now = DateTime.now();
    if (_lastCheckAt != null &&
        now.difference(_lastCheckAt!).inSeconds < 20) {
      return _lastResult;
    }

    // Prefer origin without /api to avoid 404 noise.
    final parsed = Uri.tryParse(ApiEndpoints.baseUrl);
    final url = parsed == null
        ? ApiEndpoints.baseUrl
        : '${parsed.scheme}://${parsed.authority}';
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: token != null && token.isNotEmpty
              ? {'Authorization': 'Bearer $token'}
              : null,
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 500) {
        _lastCheckAt = now;
        _lastResult = true;
        return true;
      }
      log(
        '[ConnectivityService] Server returned unexpected status: $status',
      );
      _lastCheckAt = now;
      _lastResult = false;
      return false;
    } on DioException catch (error, stack) {
      if (error.response != null &&
          (error.response!.statusCode ?? 0) >= 200 &&
          (error.response!.statusCode ?? 0) < 500) {
        _lastCheckAt = now;
        _lastResult = true;
        return true;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        _lastCheckAt = now;
        _lastResult = true;
        return true;
      }
      log('[ConnectivityService] Server unreachable: $error',
          stackTrace: stack);
      _lastCheckAt = now;
      _lastResult = false;
      return false;
    } catch (error, stack) {
      log('[ConnectivityService] Server unreachable: $error',
          stackTrace: stack);
      _lastCheckAt = now;
      _lastResult = false;
      return false;
    }
  }
}


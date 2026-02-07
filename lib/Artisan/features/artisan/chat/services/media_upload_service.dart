import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/network/auth_retry_interceptor.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

/// Uploads chat media as multipart/form-data and returns the uploaded URL.
class MediaUploadService {
  MediaUploadService() {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: const {dio.Headers.acceptHeader: 'application/json'},
      ),
    );
    if (Get.isRegistered<AuthService>()) {
      _dio.interceptors.add(
        AuthRetryInterceptor(dio: _dio, authService: Get.find<AuthService>()),
      );
    }
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        compact: true,
      ),
    );
  }

  late final dio.Dio _dio;

  Future<String> uploadChatMedia({
    required File file,
    required String mime,
    dio.ProgressCallback? onSendProgress,
    dio.CancelToken? cancelToken,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
          contentType: MediaType.parse(mime),
        ),
      });

      final response = await _dio.post(
        ApiEndpoints.uploadChat,
        data: formData,
        options: dio.Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final url = data['data']?['url'] ?? data['url'];
        final urlString = url?.toString() ?? '';
        if (urlString.isNotEmpty) return urlString;
      }
      throw ApiException('Upload failed: missing url');
    } on dio.DioException catch (e) {
      if (dio.CancelToken.isCancel(e)) {
        throw ApiException('Upload cancelled');
      }
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['message'] ??
              e.response!.data['error'] ??
              e.message)
          : e.message;
      throw ApiException(message ?? 'Upload failed');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Upload failed');
    }
  }
}


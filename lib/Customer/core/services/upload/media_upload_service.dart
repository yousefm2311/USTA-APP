import 'dart:io';
import 'package:dio/dio.dart';
typedef UploadProgress = void Function(double progress);
class MediaUploadService {
  MediaUploadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String> uploadFile({
    required File file,
    required String endpoint,
    UploadProgress? onProgress,
    String fieldName = 'file',
    Map<String, String>? headers,
  }) async {
    final form = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: form,
      options: Options(
        headers: headers,
        contentType: 'multipart/form-data',
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );

    final data = response.data ?? {};
    String? url;
    url = data['url'] ?? data['path'] ?? data['message'] ?? data['file'];
    if ((url == null || url.isEmpty) && data['data'] is Map<String, dynamic>) {
      final nested = data['data'] as Map<String, dynamic>;
      url = nested['url'] ??
          nested['path'] ??
          nested['message'] ??
          nested['file'] ??
          nested['photo'];
    } else if ((url == null || url.isEmpty) && data['data'] is String) {
      url = data['data'] as String;
    }
    if ((url == null || url.isEmpty) && data['photo'] is String) {
      url = data['photo'] as String;
    }
    if (url is String && url.isNotEmpty) {
      return url;
    }
    throw Exception('Upload failed: missing url in response');
  }
}

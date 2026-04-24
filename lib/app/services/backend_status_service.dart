import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

bool isBackendUnavailableStatus(int? statusCode) {
  return statusCode == 502 || statusCode == 503 || statusCode == 504;
}

bool looksLikeServerHtmlPayload(dynamic data, {String? contentType}) {
  final normalizedType = contentType?.toLowerCase() ?? '';
  if (normalizedType.contains('text/html') ||
      normalizedType.contains('application/xhtml+xml')) {
    return true;
  }
  if (data is! String) return false;
  final normalized = data.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.startsWith('<!doctype html') ||
      normalized.startsWith('<html') ||
      normalized.contains('<html') ||
      normalized.contains('</html>') ||
      normalized.contains('<body') ||
      normalized.contains('</body>');
}

class BackendStatusService extends GetxService {
  final RxBool isUnavailable = false.obs;
  final RxBool isChecking = false.obs;
  final RxString message =
      'الخدمة غير متاحة مؤقتًا، نحاول استعادتها في أسرع وقت.'.obs;

  final Connectivity _connectivity = Connectivity();

  String? _probeUrl;
  DateTime? _lastProbeAt;
  bool _lastProbeResult = true;

  static const Duration _probeTimeout = Duration(seconds: 6);
  static const Duration _probeCacheDuration = Duration(seconds: 8);

  void configure({required String baseUrl}) {
    final parsed = Uri.tryParse(baseUrl);
    if (parsed == null || parsed.host.isEmpty) return;
    _probeUrl = '${parsed.scheme}://${parsed.authority}';
  }

  void markAvailable() {
    if (isUnavailable.value) {
      isUnavailable.value = false;
    }
  }

  Future<void> reportFailure({
    int? statusCode,
    dynamic data,
    String? contentType,
    Object? error,
  }) async {
    if (looksLikeServerHtmlPayload(data, contentType: contentType) ||
        isBackendUnavailableStatus(statusCode)) {
      _setUnavailable();
      return;
    }

    if (_requiresProbe(statusCode: statusCode, error: error)) {
      final hasNetwork = await _hasNetworkConnection();
      if (!hasNetwork) return;
      final reachable = await probeBackend(force: true);
      if (!reachable) {
        _setUnavailable();
      }
    }
  }

  Future<void> retry() async {
    isChecking.value = true;
    try {
      final reachable = await probeBackend(force: true);
      if (reachable) {
        markAvailable();
      } else {
        _setUnavailable();
      }
    } finally {
      isChecking.value = false;
    }
  }

  Future<bool> probeBackend({bool force = false}) async {
    final probeUrl = _probeUrl;
    if (probeUrl == null || probeUrl.isEmpty) return true;

    final now = DateTime.now();
    if (!force &&
        _lastProbeAt != null &&
        now.difference(_lastProbeAt!) < _probeCacheDuration) {
      return _lastProbeResult;
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        sendTimeout: _probeTimeout,
        validateStatus: (_) => true,
      ),
    );

    try {
      final response = await dio.get<dynamic>(probeUrl);
      final status = response.statusCode ?? 0;
      final contentType = response.headers.value('content-type');
      final html = looksLikeServerHtmlPayload(
        response.data,
        contentType: contentType,
      );
      final ok = status > 0 && status < 500 && !html;
      _lastProbeAt = now;
      _lastProbeResult = ok;
      return ok;
    } on DioException {
      _lastProbeAt = now;
      _lastProbeResult = false;
      return false;
    } catch (_) {
      _lastProbeAt = now;
      _lastProbeResult = false;
      return false;
    }
  }

  bool _requiresProbe({int? statusCode, Object? error}) {
    if (statusCode == 500) return true;
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
    }
    return false;
  }

  Future<bool> _hasNetworkConnection() async {
    final result = await _connectivity.checkConnectivity();
    if (result is List<ConnectivityResult>) {
      return result.isNotEmpty && !result.contains(ConnectivityResult.none);
    }
    return true;
  }

  void _setUnavailable() {
    message.value =
        'الخدمة غير متاحة مؤقتًا، نعمل الآن على إعادة تشغيلها. حاول مرة أخرى بعد قليل.';
    isUnavailable.value = true;
  }
}

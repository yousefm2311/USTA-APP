class AppConfig {
  AppConfig._internal({
    required this.origin,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
    String? socketUrl,
    required this.allowBadCertificates,
  }) : socketUrl = socketUrl ?? origin;
  final String origin;
  String get baseUrl =>
      origin.endsWith('/api') ? origin : '$origin/api';
  final String socketUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final bool allowBadCertificates;

  static AppConfig instance = AppConfig._default();
  static Future<void> load({String? baseUrlOverride}) async {
    final envBase =
        baseUrlOverride?.trim().isNotEmpty == true
            ? baseUrlOverride!.trim()
            : _envBaseUrl;
    final normalized = _normalizeOrigin(envBase);
    if (normalized.isNotEmpty && normalized != instance.origin) {
      instance = AppConfig._internal(
        origin: normalized,
        connectTimeout: instance.connectTimeout,
        receiveTimeout: instance.receiveTimeout,
        sendTimeout: instance.sendTimeout,
        socketUrl: normalized,
        allowBadCertificates: instance.allowBadCertificates,
      );
    }
  }


  static const String _defaultOrigin = 'https://usta.qzz.io';
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: _defaultOrigin);
  static const bool _allowBadCertificates =
      bool.fromEnvironment('ALLOW_BAD_SSL', defaultValue: false);
  factory AppConfig._default() {
    final origin = _normalizeOrigin(
      _envBaseUrl.isNotEmpty ? _envBaseUrl : _defaultOrigin,
    );
    return AppConfig._internal(
      origin: origin,
      // Servers are sometimes slow; allow more breathing room.
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 20),
      socketUrl: origin,
      allowBadCertificates: _allowBadCertificates,
    );
  }

  static String _normalizeOrigin(String input) {
    var value = input.trim();
    if (value.isEmpty) return value;
    if (value.endsWith('/')) value = value.substring(0, value.length - 1);
    if (value.endsWith('/api')) value = value.substring(0, value.length - 4);
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.host.isNotEmpty) {
      final scheme = parsed.scheme.isNotEmpty ? parsed.scheme : 'https';
      final port = parsed.hasPort ? ':${parsed.port}' : '';
      return '$scheme://${parsed.host}$port';
    }
    return value;
  }
}

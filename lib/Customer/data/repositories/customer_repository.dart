import 'package:get/get.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/data/models/customer_profile.dart';
import 'package:usta/Customer/data/providers/customer_api.dart';

class CustomerRepository extends GetxService {
  final CustomerApi _api = Get.find<CustomerApi>();
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  CustomerApi get api => _api;

  Future<Map<String, dynamic>> signup({
    required String name,
    required String password,
    String? phone,
    String? email,
  }) async {
    final result = await _api.signup(
      name: name,
      password: password,
      phone: phone,
      email: email,
    );
    await _persistTokens(result);
    return result;
  }

  Future<Map<String, dynamic>> login({
    required String password,
    String? phone,
    String? email,
  }) async {
    final result = await _api.login(
      password: password,
      phone: phone,
      email: email,
    );
    await _persistTokens(result);
    return result;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.clear();
    }
  }

  Future<Map<String, dynamic>> refresh() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _storage.markLoggedOut();
      return {};
    }
    final result = await _api.refreshToken(refreshToken);
    await _persistTokens(result);
    return result;
  }

  CustomerProfile? extractProfile(Map<String, dynamic> data) {
    Map<String, dynamic>? profile;
    profile ??= _asMap(data['customer']);
    profile ??= _asMap(data['user']);

    if (profile == null && data['data'] is Map<String, dynamic>) {
      final nested = data['data'] as Map<String, dynamic>;
      profile ??= _asMap(nested['customer']);
      profile ??= _asMap(nested['user']);
      profile ??= nested;
    }
    if (profile == null) return null;
    final id = (profile['_id'] ?? profile['id'])?.toString();
    if (id == null || id.isEmpty) return null;
    return CustomerProfile.fromMap(profile);
  }

  Future<void> _persistTokens(Map<String, dynamic> data) async {
    final access = _extractAccessToken(data);
    final refresh = _extractRefreshToken(data);
    if (access != null && access.isNotEmpty) {
      await _storage.save(accessToken: access, refreshToken: refresh);
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  String? _extractAccessToken(Map<String, dynamic> data) {
    final direct =
        data['token'] ?? data['accessToken'] ?? data['access_token'];
    if (direct is String && direct.isNotEmpty) return direct;
    if (data['data'] is Map<String, dynamic>) {
      final nested = (data['data'] as Map<String, dynamic>)['token'] ??
          (data['data'] as Map<String, dynamic>)['accessToken'] ??
          (data['data'] as Map<String, dynamic>)['access_token'];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    return null;
  }

  String? _extractRefreshToken(Map<String, dynamic> data) {
    final direct =
        data['refreshToken'] ?? data['refresh_token'] ?? data['refresh'];
    if (direct is String && direct.isNotEmpty) return direct;
    if (data['data'] is Map<String, dynamic>) {
      final nested = (data['data'] as Map<String, dynamic>)['refreshToken'] ??
          (data['data'] as Map<String, dynamic>)['refresh_token'] ??
          (data['data'] as Map<String, dynamic>)['refresh'];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    return null;
  }
}



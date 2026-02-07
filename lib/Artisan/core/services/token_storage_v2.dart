import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageV2 {
  TokenStorageV2._();
  static final TokenStorageV2 instance = TokenStorageV2._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<Map<String, String?>> readTokens() async {
    final access = await _storage.read(key: 'access_token');
    final refresh = await _storage.read(key: 'refresh_token');
    return {'access': access, 'refresh': refresh};
  }

  Future<void> clear() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

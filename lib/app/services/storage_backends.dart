import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';

abstract class SecureStorageBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

abstract class LocalStorageBackend {
  String? readString(String key);
  bool? readBool(String key);
  Future<void> writeString(String key, String value);
  Future<void> writeBool(String key, bool value);
  Future<void> remove(String key);
}

class FlutterSecureStorageBackend implements SecureStorageBackend {
  FlutterSecureStorageBackend([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class GetStorageBackend implements LocalStorageBackend {
  GetStorageBackend([GetStorage? box]) : _box = box ?? GetStorage();

  final GetStorage _box;

  @override
  String? readString(String key) => _box.read<String>(key);

  @override
  bool? readBool(String key) => _box.read<bool>(key);

  @override
  Future<void> writeString(String key, String value) => _box.write(key, value);

  @override
  Future<void> writeBool(String key, bool value) => _box.write(key, value);

  @override
  Future<void> remove(String key) => _box.remove(key);
}

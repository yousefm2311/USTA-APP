import 'package:usta/app/services/storage_backends.dart';

class InMemorySecureStorage implements SecureStorageBackend {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class InMemoryLocalStorage implements LocalStorageBackend {
  final Map<String, Object?> values = <String, Object?>{};

  @override
  String? readString(String key) => values[key] as String?;

  @override
  bool? readBool(String key) => values[key] as bool?;

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

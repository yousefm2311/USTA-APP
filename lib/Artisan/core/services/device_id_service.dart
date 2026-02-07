import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  DeviceIdService({
    FlutterSecureStorage? secureStorage,
    GetStorage? fallbackStorage,
    DeviceInfoPlugin? deviceInfo,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _fallbackStorage = fallbackStorage ?? GetStorage(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _uuid = uuid ?? const Uuid();

  static const _storageKey = 'device_id';
  final FlutterSecureStorage _secureStorage;
  final GetStorage _fallbackStorage;
  final DeviceInfoPlugin _deviceInfo;
  final Uuid _uuid;

  Future<String> getDeviceId() async {
    final stored = await _readStoredId();
    if (stored != null && stored.isNotEmpty) return stored;

    final generated = await _resolvePlatformId() ?? _uuid.v4();
    await _writeStoredId(generated);
    return generated;
  }

  Future<String?> _readStoredId() async {
    if (kIsWeb) {
      return _fallbackStorage.read<String>(_storageKey);
    }
    return _secureStorage.read(key: _storageKey);
  }

  Future<void> _writeStoredId(String value) async {
    if (kIsWeb) {
      await _fallbackStorage.write(_storageKey, value);
      return;
    }
    await _secureStorage.write(key: _storageKey, value: value);
  }

  Future<String?> _resolvePlatformId() async {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      final id = _readAndroidId(info);
      if (id != null && id.isNotEmpty) return id;
    }
    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      final id = info.identifierForVendor;
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  String? _readAndroidId(AndroidDeviceInfo info) {
    try {
      final dynamic dynInfo = info;
      final String? androidId = dynInfo.androidId;
      if (androidId != null && androidId.isNotEmpty) return androidId;
    } catch (_) {
      // androidId isn't available in some device_info_plus versions.
    }
    final fallback = info.id;
    if (fallback.isNotEmpty) return fallback;
    return null;
  }
}

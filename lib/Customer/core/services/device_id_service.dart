import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService extends GetxService {
  static const _deviceIdKey = 'customer_device_id';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  final AndroidId _androidId = const AndroidId();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  String? _cached;
  Future<DeviceIdService> init() async {
    _cached = await _secure.read(key: _deviceIdKey);
    if (_cached == null || _cached!.isEmpty) {
      _cached = await _resolveDeviceId();
      await _secure.write(key: _deviceIdKey, value: _cached);
    }
    return this;
  }

  String? get deviceId => _cached;

  Future<String> getOrCreateDeviceId() async {
    if (_cached != null && _cached!.isNotEmpty) return _cached!;
    await init();
    return _cached ?? _uuid.v4();
  }

  Future<String> _resolveDeviceId() async {
    try {
      if (kIsWeb) {
        return _uuid.v4();
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidId = await _androidId.getId();
        if (androidId != null && androidId.isNotEmpty) return androidId;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        final idfv = info.identifierForVendor;
        if (idfv != null && idfv.isNotEmpty) return idfv;
      }
    } catch (_) {
    }
    return _uuid.v4();
  }
}

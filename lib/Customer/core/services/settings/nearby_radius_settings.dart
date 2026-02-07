import 'package:usta/Customer/core/services/database/share_Prefs.dart';
import 'package:usta/Customer/core/utils/constants/app_constant.dart';

class NearbyRadiusSettings {
  static Future<double?> readKm() async {
    final prefs = AppPrefs();
    await prefs.init();
    final storedDouble = prefs.getDouble(kNearbyRadiusKmKey);
    if (storedDouble != null) return storedDouble;
    final storedInt = prefs.getInt(kNearbyRadiusKmKey);
    if (storedInt != null) return storedInt.toDouble();
    return null;
  }

  static Future<int?> readMeters() async {
    final km = await readKm();
    if (km == null) return null;
    return (km * 1000).round();
  }

  static Future<void> saveKm(double? km) async {
    final prefs = AppPrefs();
    await prefs.init();
    if (km == null) {
      await prefs.remove(kNearbyRadiusKmKey);
      return;
    }
    await prefs.setDouble(kNearbyRadiusKmKey, km);
  }
}


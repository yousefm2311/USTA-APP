import 'package:get/get.dart';
import 'package:usta/Customer/core/services/database/share_Prefs.dart';

import 'package:usta/Customer/core/services/settings/local_controller.dart';
import 'package:usta/Customer/core/services/settings/theme_controller.dart';

class SettingsServices extends GetxService {
  final prefs = AppPrefs();
  final ThemeController themeController =
      Get.isRegistered<ThemeController>(tag: 'customer')
          ? Get.find<ThemeController>(tag: 'customer')
          : Get.put(ThemeController(), tag: 'customer');
  final LocaleController localeController =
      Get.isRegistered<LocaleController>(tag: 'customer')
          ? Get.find<LocaleController>(tag: 'customer')
          : Get.put(LocaleController(), tag: 'customer');
  Future<SettingsServices> init() async {
    await prefs.init();
    await themeController.loadTheme();
    await localeController.loadLocale();
    return this;
  }
}


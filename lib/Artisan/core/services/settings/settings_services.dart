import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/theme_controller.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/locale_controller.dart';

class SettingsServices extends GetxService {
  final prefs = AppPrefs();
  final ThemeController themeController =
      Get.isRegistered<ThemeController>(tag: 'artisan')
          ? Get.find<ThemeController>(tag: 'artisan')
          : Get.put(ThemeController(), tag: 'artisan');
  final LocaleController localeController =
      Get.isRegistered<LocaleController>(tag: 'artisan')
          ? Get.find<LocaleController>(tag: 'artisan')
          : Get.put(LocaleController(), tag: 'artisan');
  Future<SettingsServices> init() async {
    await prefs.init();
    await themeController.loadTheme();
    await localeController.loadLocale();
    
    await ApiClient.instance.init();
    return this;
  }
}


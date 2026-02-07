import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';


class ThemeController extends GetxController {
  RxBool isDark = true.obs;
  final prefs = AppPrefs();

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final cachedValue = prefs.getBool('isDark');
    isDark.value = cachedValue ?? false;
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    update();
  }

  Future<void> changeTheme() async {
    isDark.value = !isDark.value;
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    update();
  }
}


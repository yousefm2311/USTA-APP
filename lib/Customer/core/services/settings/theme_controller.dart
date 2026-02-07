import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/database/share_Prefs.dart';

class ThemeController extends GetxController {
  final AppPrefs _prefs = AppPrefs();
  final RxBool isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  Future<void> loadTheme() async {
    await _prefs.init();
    final cachedValue = _prefs.getBool('isDark');
    isDark.value = cachedValue ?? false;
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    update();
  }

  Future<void> changeTheme() async {
    await _prefs.init();
    isDark.value = !isDark.value;
    await _prefs.setBool('isDark', isDark.value);
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    await Get.forceAppUpdate();
    update();
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.init();
    final normalized = mode.toLowerCase();
    final newValue = normalized == 'dark';
    final didChange = isDark.value != newValue;
    isDark.value = newValue;
    await _prefs.setBool('isDark', isDark.value);
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
    if (didChange) {
      await Get.forceAppUpdate();
    }
    update();
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';

class LocaleController extends GetxController {
  final AppPrefs _prefs = AppPrefs();
  final Rx<Locale> locale = const Locale('ar', 'EG').obs;

  @override
  void onInit() {
    super.onInit();
    loadLocale();
  }

  Future<void> loadLocale() async {
    await _prefs.init();
    final code = _prefs.getString(kLocaleCodeKey);
    if (code != null && code.isNotEmpty) {
      locale.value = Locale(code);
      Get.updateLocale(locale.value);
    }
  }

  Future<void> changeLocale(Locale newLocale) async {
    locale.value = newLocale;
    await _prefs.setString(kLocaleCodeKey, newLocale.languageCode);
    Get.updateLocale(newLocale);
    update();
  }
}


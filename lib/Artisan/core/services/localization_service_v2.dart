import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'settings/settings_service_v2.dart';

class LocalizationServiceV2 extends Translations {
  static const fallback = Locale('en');

  static Locale get initialLocale {
    final lang = Get.find<SettingsServiceV2>().language.value;
    return lang == 'ar' ? const Locale('ar') : fallback;
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en': {
          'login': 'Login',
          'logout': 'Logout',
        },
        'ar': {
          'login': 'تسجيل الدخول',
          'logout': 'تسجيل الخروج',
        },
      };
}

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsServiceV2 extends GetxService {
  final RxString language = 'en'.obs;
  final RxString theme = 'light'.obs;
  final RxBool marketingNotifications = true.obs;
  final RxBool requestsNotifications = true.obs;
  final RxBool chatNotifications = true.obs;

  Future<SettingsServiceV2> init() async {
    final prefs = await SharedPreferences.getInstance();
    language.value = prefs.getString('language_v2') ?? 'en';
    theme.value = prefs.getString('theme_v2') ?? 'light';
    marketingNotifications.value = prefs.getBool('marketing_n_v2') ?? true;
    requestsNotifications.value = prefs.getBool('requests_n_v2') ?? true;
    chatNotifications.value = prefs.getBool('chat_n_v2') ?? true;
    return this;
  }

  Future<void> setLanguage(String lang, {bool syncRemote = true}) async {
    language.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_v2', lang);
    // if (syncRemote && Get.isRegistered<CustomerProfileRepoV2>()) {
    //   await Get.find<CustomerProfileRepoV2>().updateLanguage(lang);
    // }
  }

  Future<void> setTheme(String value, {bool syncRemote = true}) async {
    theme.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_v2', value);
    // if (syncRemote && Get.isRegistered<CustomerProfileRepoV2>()) {
    //   await Get.find<CustomerProfileRepoV2>().updateTheme(value);
    // }
  }

  Future<void> setNotificationSettings({
    required bool marketing,
    required bool requests,
    required bool chat,
    bool syncRemote = true,
  }) async {
    marketingNotifications.value = marketing;
    requestsNotifications.value = requests;
    chatNotifications.value = chat;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('marketing_n_v2', marketing);
    await prefs.setBool('requests_n_v2', requests);
    await prefs.setBool('chat_n_v2', chat);
    // if (syncRemote && Get.isRegistered<CustomerProfileRepoV2>()) {
    //   await Get.find<CustomerProfileRepoV2>().updateNotificationSettings(
    //     marketing: marketing,
    //     requests: requests,
    //     chat: chat,
    //   );
    // }
  }
}

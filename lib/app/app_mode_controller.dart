import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/Artisan/main.dart' as artisan_app;
import 'package:usta/Customer/main.dart' as customer_app;

enum AppUserType { none, artisan, customer }

class AppModeController extends GetxController {
  static const String _storageKey = 'selected_user_type';

  static AppModeController get to => Get.find<AppModeController>();

  final Rx<AppUserType> mode = AppUserType.none.obs;
  final RxBool isBootstrapping = false.obs;
  final RxnString customerInitialRoute = RxnString();
  final RxnString artisanInitialRoute = RxnString();

  SharedPreferences? _prefs;
  bool _switcherAttached = false;

  Future<void> init() async {
    await _ensurePrefs();
    final stored = _prefs?.getString(_storageKey);
    final parsed = _parse(stored);
    if (parsed == AppUserType.customer) {
      await _ensureCustomerReady();
    } else if (parsed == AppUserType.artisan) {
      await _ensureArtisanReady();
    }
    mode.value = parsed;
  }

  Future<void> selectArtisan() async {
    await _switchTo(AppUserType.artisan);
  }

  Future<void> selectCustomer() async {
    await _switchTo(AppUserType.customer);
  }

  Future<void> reset() async {
    await _ensurePrefs();
    customerInitialRoute.value = null;
    artisanInitialRoute.value = null;
    mode.value = AppUserType.none;
    await _prefs?.remove(_storageKey);
  }

  void attachSwitcher() {
    _switcherAttached = true;
  }

  void detachSwitcher() {
    _switcherAttached = false;
  }

  bool get switcherAttached => _switcherAttached;

  Future<bool> resetToChooser() async {
    await reset();
    return _switcherAttached;
  }

  Future<void> _switchTo(AppUserType next) async {
    if (mode.value == next && !isBootstrapping.value) return;
    isBootstrapping.value = true;
    try {
      if (next == AppUserType.artisan) {
        customerInitialRoute.value = null;
        await _ensureArtisanReady();
        await _persistSelection('Artisan');
      } else if (next == AppUserType.customer) {
        await _ensureCustomerReady();
        await _persistSelection('Customer');
      }
      mode.value = next;
    } finally {
      isBootstrapping.value = false;
    }
  }

  Future<void> _ensureArtisanReady() async {
    await artisan_app.ensureArtisanInitialized();
    artisanInitialRoute.value = await artisan_app.resolveArtisanInitialRoute();
  }

  Future<void> _ensureCustomerReady() async {
    await customer_app.ensureCustomerInitialized();
    customerInitialRoute.value = await customer_app.resolveCustomerInitialRoute();
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _persistSelection(String value) async {
    await _ensurePrefs();
    await _prefs?.setString(_storageKey, value);
  }

  AppUserType _parse(String? value) {
    if (value == 'Artisan') return AppUserType.artisan;
    if (value == 'Customer') return AppUserType.customer;
    return AppUserType.none;
  }
}

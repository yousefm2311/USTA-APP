import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart'
    as artisan_rt;
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart'
    as artisan_lifecycle;
import 'package:usta/Artisan/core/realtime/socket_service.dart'
    as artisan_socket;
import 'package:usta/Artisan/main.dart' as artisan_app;
import 'package:usta/Customer/core/realtime/realtime_controller.dart'
    as customer_rt;
import 'package:usta/Customer/features/customer/chat/services/chat_realtime_service.dart'
    as customer_chat_rt;
import 'package:usta/Customer/features/customer/chat/controller/chat_controller.dart'
    as customer_chat;
import 'package:usta/Customer/features/customer/customer_navigation_controller.dart'
    as customer_nav;
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
  int _switchToken = 0;

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

  Future<void> selectArtisan({bool force = false}) async {
    await _switchTo(AppUserType.artisan, force: force);
  }

  Future<void> selectCustomer({bool force = false}) async {
    await _switchTo(AppUserType.customer, force: force);
  }

  Future<void> reset() async {
    _switchToken++;
    await _ensurePrefs();
    customerInitialRoute.value = null;
    artisanInitialRoute.value = null;
    mode.value = AppUserType.none;
    isBootstrapping.value = false;
    await _prefs?.remove(_storageKey);
    // Cleanup is best-effort and must not block switching to chooser.
    try {
      await _deactivateArtisanServices();
    } catch (error, stack) {
      developer.log(
        '[AppMode] artisan cleanup failed: $error',
        stackTrace: stack,
      );
    }
    try {
      await _deactivateCustomerServices();
    } catch (error, stack) {
      developer.log(
        '[AppMode] customer cleanup failed: $error',
        stackTrace: stack,
      );
    }
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

  Future<void> _switchTo(AppUserType next, {bool force = false}) async {
    if (!force && mode.value == next && !isBootstrapping.value) return;
    final token = ++_switchToken;
    isBootstrapping.value = true;
    mode.value = next;
    customerInitialRoute.value = null;
    artisanInitialRoute.value = null;
    try {
      if (next == AppUserType.artisan) {
        try {
          await _deactivateCustomerServices();
        } catch (error, stack) {
          developer.log(
            '[AppMode] customer cleanup before artisan failed: $error',
            stackTrace: stack,
          );
        }
        await _ensureArtisanReady();
        if (token != _switchToken) return;
        await _persistSelection('Artisan');
      } else if (next == AppUserType.customer) {
        try {
          await _deactivateArtisanServices();
        } catch (error, stack) {
          developer.log(
            '[AppMode] artisan cleanup before customer failed: $error',
            stackTrace: stack,
          );
        }
        await _ensureCustomerReady();
        if (token != _switchToken) return;
        await _persistSelection('Customer');
      }
      if (token != _switchToken) return;
      mode.value = next;
    } finally {
      if (token == _switchToken) {
        isBootstrapping.value = false;
      }
    }
  }

  Future<void> _deactivateArtisanServices() async {
    if (Get.isRegistered<artisan_lifecycle.RealtimeLifecycleService>()) {
      try {
        await Get.find<artisan_lifecycle.RealtimeLifecycleService>().stopAll();
      } catch (error, stack) {
        developer.log(
          '[AppMode] stopAll artisan lifecycle failed: $error',
          stackTrace: stack,
        );
      }
    }
    if (Get.isRegistered<artisan_rt.RealtimeController>(tag: 'artisan')) {
      try {
        await Get.find<artisan_rt.RealtimeController>(
          tag: 'artisan',
        ).disconnect();
      } catch (error, stack) {
        developer.log(
          '[AppMode] artisan realtime disconnect failed: $error',
          stackTrace: stack,
        );
      }
    }
    if (Get.isRegistered<artisan_socket.SocketService>()) {
      try {
        await Get.find<artisan_socket.SocketService>().disconnect();
      } catch (error, stack) {
        developer.log(
          '[AppMode] artisan socket disconnect failed: $error',
          stackTrace: stack,
        );
      }
    }
  }

  Future<void> _deactivateCustomerServices() async {
    if (Get.isRegistered<customer_chat_rt.ChatRealtimeService>(
      tag: 'customer',
    )) {
      try {
        await Get.find<customer_chat_rt.ChatRealtimeService>(
          tag: 'customer',
        ).stop();
      } catch (error, stack) {
        developer.log(
          '[AppMode] customer chat realtime stop failed: $error',
          stackTrace: stack,
        );
      }
    }
    if (Get.isRegistered<customer_rt.RealtimeController>(tag: 'customer')) {
      try {
        Get.find<customer_rt.RealtimeController>(tag: 'customer').disconnect();
      } catch (error, stack) {
        developer.log(
          '[AppMode] customer realtime disconnect failed: $error',
          stackTrace: stack,
        );
      }
    }
    if (Get.isRegistered<customer_chat.ChatController>(tag: 'customer')) {
      Get.delete<customer_chat.ChatController>(tag: 'customer', force: true);
    }
    if (Get.isRegistered<customer_chat_rt.ChatRealtimeService>(
      tag: 'customer',
    )) {
      Get.delete<customer_chat_rt.ChatRealtimeService>(
        tag: 'customer',
        force: true,
      );
    }
    if (Get.isRegistered<customer_rt.RealtimeController>(tag: 'customer')) {
      Get.delete<customer_rt.RealtimeController>(tag: 'customer', force: true);
    }
    if (Get.isRegistered<customer_nav.CustomerNavigationController>()) {
      Get.delete<customer_nav.CustomerNavigationController>(force: true);
    }
  }

  Future<void> _ensureArtisanReady() async {
    await artisan_app.ensureArtisanInitialized();
    artisanInitialRoute.value = await artisan_app.resolveArtisanInitialRoute();
  }

  Future<void> _ensureCustomerReady() async {
    await customer_app.ensureCustomerInitialized();
    customerInitialRoute.value = await customer_app
        .resolveCustomerInitialRoute();
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

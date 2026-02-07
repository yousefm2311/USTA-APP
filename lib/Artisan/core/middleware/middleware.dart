import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/token_storage.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/bindings/customer_binding_v2.dart';


class AuthMiddleWare extends GetMiddleware {
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'artisan');

  @override
  RouteSettings? redirect(String? route) {
    final token = _storage.accessToken;
    final loggedOut = _storage.loggedOut;
    final bool hasToken = token != null && token.isNotEmpty && !loggedOut;

    if (!hasToken) {
      if (route == AppRoutes.login || route == AppRoutes.register) {
        return null;
      }
      return const RouteSettings(name: AppRoutes.login);
    }

    if (route == AppRoutes.login || route == AppRoutes.register) {
      CustomerBindingV2.ensureInitialized();
      return const RouteSettings(name: AppRoutes.bottomNaviBar);
    }

    return null;
  }
}




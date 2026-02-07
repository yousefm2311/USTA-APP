import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';


class AuthMiddleWare extends GetMiddleware {
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  @override
  RouteSettings? redirect(String? route) {
    final token = _storage.accessToken;
    final loggedOut = _storage.loggedOut;
    if (token == null || token.isEmpty || loggedOut) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return const RouteSettings(name: AppRoutes.bottomNaviBar);
  }
}





// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:usta/Customer/core/services/auth_service.dart';
// import 'package:usta/Customer/core/services/settings/settings_services.dart';
// import 'package:usta/Customer/core/utils/constants/app_constant.dart' show kAuthTokenKey;
// import 'package:usta/Customer/core/utils/routes/routes.dart';

// class SessionMiddleware extends GetMiddleware {
//   @override
//   RouteSettings? redirect(String? route) {
//     final prefs = Get.find<SettingsServices>(tag: 'customer').prefs;
//     final token = prefs.getString(kAuthTokenKey);
//     if (token != null && token.isNotEmpty) {
//       return const RouteSettings(name: AppRoutes.bottomNaviBar);
//     }
//     return null;
//   }
// }


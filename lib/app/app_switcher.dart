import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/app/app_mode_controller.dart';
import 'package:usta/app/choose_user_type_view.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart' as artisan_routes;
import 'package:usta/Artisan/main.dart' as artisan_app;
import 'package:usta/Customer/core/utils/routes/routes.dart' as customer_routes;
import 'package:usta/Customer/main.dart' as customer_app;

class AppSwitcher extends StatefulWidget {
  const AppSwitcher({super.key});

  @override
  State<AppSwitcher> createState() => _AppSwitcherState();
}

class _AppSwitcherState extends State<AppSwitcher> {
  late final AppModeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AppModeController>();
    _controller.attachSwitcher();
  }

  @override
  void dispose() {
    _controller.detachSwitcher();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isBootstrapping.value) {
        return const _BootstrapLoadingApp();
      }
      switch (_controller.mode.value) {
        case AppUserType.artisan:
          final route = _controller.artisanInitialRoute.value ??
              artisan_routes.AppRoutes.login;
          return artisan_app.ArtisanApp(
            key: const ValueKey('artisan_app'),
            initialRoute: route,
          );
        case AppUserType.customer:
          final route = _controller.customerInitialRoute.value ??
              customer_routes.AppRoutes.login;
          return customer_app.CustomerApp(
            key: const ValueKey('customer_app'),
            initialRoute: route,
          );
        case AppUserType.none:
        default:
          return const GetMaterialApp(
            debugShowCheckedModeBanner: false,
            home: ChooseUserTypeView(),
          );
      }
    });
  }
}

class _BootstrapLoadingApp extends StatelessWidget {
  const _BootstrapLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

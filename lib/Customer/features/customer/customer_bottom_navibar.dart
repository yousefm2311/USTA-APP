import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';

import 'customer_navigation_controller.dart';

class CustomerBottomNaviBar extends StatelessWidget {
  CustomerBottomNaviBar({super.key});

  final CustomerNavigationController controller =
      Get.isRegistered<CustomerNavigationController>()
      ? Get.find<CustomerNavigationController>()
      : Get.put(CustomerNavigationController(), permanent: true);

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.screens,
        ),
      ),

      bottomNavigationBar: Obx(
        () => Container(
          height: MediaQuery.of(context).size.height * 0.129,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: const Border(top: BorderSide(color: Colors.white12)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: NavigationBar(
              backgroundColor: scheme.surface,
              elevation: 0,
              height: 50,
              indicatorColor: primaryBlue.withOpacity(0.18),
              surfaceTintColor: Colors.transparent,
              animationDuration: const Duration(milliseconds: 300),
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: controller.changeTab,
              destinations: [
                NavigationDestination(
                  icon: Icon(IconBroken.Home, size: 26),
                  selectedIcon: Icon(
                    IconBroken.Home,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                  label: "الرئيسية".tr,
                ),
                NavigationDestination(
                  icon: Icon(Icons.history, size: 26),
                  selectedIcon: Icon(
                    Icons.history,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                  label: "السجل".tr,
                ),
                NavigationDestination(
                  icon: Icon(IconBroken.Chat, size: 26),
                  selectedIcon: Icon(
                    IconBroken.Chat,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                  label: "الرسائل".tr,
                ),
                NavigationDestination(
                  icon: Icon(IconBroken.Document, size: 26),
                  selectedIcon: Icon(
                    IconBroken.Document,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                  label: "الطلبات".tr,
                ),
                NavigationDestination(
                  icon: Icon(IconBroken.Profile, size: 26),
                  selectedIcon: Icon(
                    IconBroken.Profile,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                  label: "حسابي".tr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

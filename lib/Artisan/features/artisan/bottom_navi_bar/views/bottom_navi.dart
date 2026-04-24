// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/widgets/icon_broken.dart';
import 'package:usta/Artisan/features/artisan/bottom_navi_bar/controllers/botton_navi_controller.dart';

class ArtisanBottomNaviBar extends StatelessWidget {
  ArtisanBottomNaviBar({super.key});

  final NavigationController controller =
      Get.isRegistered<NavigationController>()
      ? Get.find<NavigationController>()
      : Get.put(NavigationController());

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.surface,
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.screens,
        ),
      ),
      bottomNavigationBar: Obx(() {
        final bottomPad = MediaQuery.of(context).padding.bottom;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: bottomPad),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            // border: const Border(top: BorderSide(color: Colors.white12)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            boxShadow: [BoxShadow(blurRadius: .5)],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 64,
              indicatorColor: primaryBlue.withOpacity(0.15),
              surfaceTintColor: Colors.transparent,
              animationDuration: const Duration(milliseconds: 250),
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: (value) {
                controller.selectedIndex.value = value;
              },
              destinations: [
                _item(IconBroken.Home, "الرئيسية"),
                _item(IconBroken.Chat, "المحادثات"),
                _item(IconBroken.Setting, "الإعدادات"),
                _item(IconBroken.Profile, "حسابي"),
              ],
            ),
          ),
        );
      }),
    );
  }

  NavigationDestination _item(IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon, size: 26),
      selectedIcon: Icon(icon, size: 28, color: primaryBlue),
      label: label, // مخفي أصلاً
    );
  }
}

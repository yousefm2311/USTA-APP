import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_list_view.dart';
import 'package:usta/Customer/features/customer/complaints/views/customer_complaints_view.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';
import 'package:usta/Customer/features/customer/notifications/views/customer_notifications_view.dart';
import 'package:usta/Customer/features/customer/payments/add_card/customer_add_bank_card_view.dart';
import 'package:usta/Customer/features/customer/profile/controllers/customer_profile_controller.dart';
import 'package:usta/Customer/features/customer/profile/views/customer_change_password_view.dart';
import 'package:usta/Customer/features/customer/profile/views/customer_delete_account_view.dart';
import 'package:usta/Customer/features/customer/profile/views/customer_edit_profile_view.dart';
import 'package:usta/Customer/features/customer/profile/views/customer_settings_view.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/profile_action_tile.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/profile_danger_card.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/profile_header_card.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/profile_info_tile.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/profile_quick_actions.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/profile_section_title.dart';
import 'package:usta/Customer/features/customer/reviews/views/customer_reviews_view.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_wallet_view.dart';

class CustomerProfileView extends StatelessWidget {
  const CustomerProfileView({super.key});

  Color get cardDark => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);
  Color get dangerRed => const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerProfileController>();
    final notificationsCtrl = Get.find<CustomerNotificationsController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "حسابي".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.loading.value && controller.profile.value == null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ShimmerSkeletons.gridCard(height: 140, borderRadius: 20),
              const SizedBox(height: 16),
              ShimmerSkeletons.listTile(height: 70),
              const SizedBox(height: 12),
              ShimmerSkeletons.listTile(height: 70),
            ],
          );
        }

        final profile = controller.profile.value ?? {};

        return RefreshIndicator(
          color: primaryBlue,
          onRefresh: () =>
              controller.refreshProfile(showLoader: false, force: true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ProfileHeaderCard(
                name: profile['name']?.toString() ?? 'مستخدم'.tr,
                email: profile['email']?.toString() ?? '',
                online: controller.online.value,
                imageProvider: _resolveImageProvider(
                  profile['photo'] ??
                      profile['photoUrl'] ??
                      profile['avatar'] ??
                      profile['image'],
                ),
                primaryColor: primaryBlue,
                cardColor: cardDark,
              ),
              const SizedBox(height: 14),
              ProfileQuickActions(
                primaryColor: primaryBlue,
                actions: [
                  ProfileQuickActionItem(
                    icon: Icons.account_balance_wallet,
                    title: "المحفظة".tr,
                    onTap: () => Get.to(() => CustomerWalletView()),
                  ),
                  ProfileQuickActionItem(
                    icon: Icons.notifications,
                    title: "الإشعارات".tr,
                    onTap: () => Get.to(() => CustomerNotificationsView()),
                  ),
                  ProfileQuickActionItem(
                    icon: IconBroken.Chat,
                    title: "المحادثات".tr,
                    onTap: () => Get.to(() => const CustomerChatListView()),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              ProfileSectionTitle(title: "المعلومات".tr),
              ProfileInfoTile(
                icon: Icons.person,
                label: "الاسم".tr,
                value: profile['name'],
                primaryColor: primaryBlue,
              ),
              ProfileCopyTile(
                icon: Icons.email,
                label: "البريد".tr,
                value: profile['email'],
                primaryColor: primaryBlue,
              ),
              ProfileCopyTile(
                icon: Icons.phone,
                label: "الجوال".tr,
                value: profile['phone'],
                primaryColor: primaryBlue,
              ),
              ProfileInfoTile(
                icon: Icons.location_on,
                label: "العنوان".tr,
                value: profile['address'],
                maxLines: 2,
                primaryColor: primaryBlue,
              ),

              const SizedBox(height: 5),
              ProfileSectionTitle(title: "الإعدادات".tr),
              ProfileActionTile(
                icon: Icons.edit,
                title: "تعديل البيانات".tr,
                onTap: () => Get.to(() => CustomerEditProfileView()),
                primaryColor: primaryBlue,
              ),
              ProfileActionTile(
                icon: Icons.settings,
                title: "إعدادات الحساب".tr,
                onTap: () => Get.to(() => const CustomerSettingsView()),
                primaryColor: primaryBlue,
              ),
              ProfileActionTile(
                icon: Icons.lock_outline,
                title: "تغيير كلمة المرور".tr,
                onTap: () => Get.to(() => const CustomerChangePasswordView()),
                primaryColor: primaryBlue,
              ),

              const SizedBox(height: 5),
              ProfileSectionTitle(title: "الخدمات".tr),
              Obx(
                () => ProfileActionTile(
                  icon: Icons.notifications_none,
                  title: "الإشعارات".tr,
                  onTap: () => Get.to(() => CustomerNotificationsView()),
                  primaryColor: primaryBlue,
                  badgeCount: notificationsCtrl.unreadCount,
                ),
              ),
              ProfileActionTile(
                icon: IconBroken.Chat,
                title: "المحادثات".tr,
                onTap: () => Get.to(() => const CustomerChatListView()),
                primaryColor: primaryBlue,
              ),
              ProfileActionTile(
                icon: Icons.support_agent,
                title: "الشكاوى".tr,
                onTap: () => Get.to(() => CustomerComplaintsView()),
                primaryColor: primaryBlue,
              ),
              ProfileActionTile(
                icon: Icons.rate_review_outlined,
                title: "تقييماتي".tr,
                onTap: () => Get.to(() => CustomerReviewsView()),
                primaryColor: primaryBlue,
              ),
              ProfileActionTile(
                icon: Icons.account_balance_wallet_outlined,
                title: "المحفظة".tr,
                onTap: () => Get.to(() => CustomerWalletView()),
                primaryColor: primaryBlue,
              ),
              ProfileActionTile(
                icon: Icons.credit_card,
                title: "إضافة كارت".tr,
                onTap: () => Get.to(() => const CustomerAddBankCardView()),
                primaryColor: primaryBlue,
              ),

              const SizedBox(height: 5),
              ProfileSectionTitle(title: "إجراءات".tr),
              ProfileDangerCard(
                icon: Icons.logout,
                title: "تسجيل الخروج".tr,
                onTap: () => _confirmLogout(context, controller),
              ),
              const SizedBox(height: 10),
              ProfileDangerCard(
                icon: Icons.delete_forever,
                title: "حذف الحساب".tr,
                onTap: () => Get.to(() => CustomerDeleteAccountView()),
                color: dangerRed,
              ),
            ],
          ),
        );
      }),
    );
  }
  ImageProvider? _resolveImageProvider(String? value) {
    if (value == null || value.isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http')) {
      return CachedNetworkImageProvider(trimmed);
    }

    if (trimmed.startsWith('/')) {
      final origin = AppConfig.instance.origin;
      if (origin.isEmpty) return null;
      return CachedNetworkImageProvider('$origin$trimmed');
    }

    try {
      final cleaned = trimmed.startsWith('data:image')
          ? trimmed.split(',').last
          : trimmed;
      return MemoryImage(base64Decode(cleaned));
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    CustomerProfileController controller,
  ) async {
    await Get.dialog(
      AlertDialog(
        title: Text(
          AppStrings.logout.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          AppStrings.logoutConfirm.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              AppStrings.cancel.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: Text(
              AppStrings.logout.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}


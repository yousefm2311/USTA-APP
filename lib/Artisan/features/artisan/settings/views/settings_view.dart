import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_help_view.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/theme_controller.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_location_settings_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_reviews_view.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';

class ArtisanSettingsView extends StatelessWidget {
  ArtisanSettingsView({super.key});

  final Color primaryBlue = const Color(0xFF2563EB);
  final ThemeController themeController =
      Get.isRegistered<ThemeController>(tag: 'artisan')
          ? Get.find<ThemeController>(tag: 'artisan')
          : Get.put(ThemeController(), tag: 'artisan');
  final AuthController authController = Get.find<AuthController>(tag: 'artisan');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppStrings.settings.tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _SectionTitle(title: AppStrings.settings.tr),
            _SettingsTile(
              icon: Icons.notifications_active,
              title: AppStrings.notifications.tr,
              iconColor: primaryBlue,
              onTap: () =>
                  pushNamedRoute(AppRoutes.artisanNotificationSettingsView),
            ),
            _SettingsTile(
              icon: Icons.lock,
              title: AppStrings.privacy.tr,
              iconColor: primaryBlue,
              onTap: () => pushNamedRoute(AppRoutes.artisanPrivacyView),
            ),
            _SettingsTile(
              icon: Icons.help_outline,
              title: AppStrings.help.tr,
              iconColor: primaryBlue,
              onTap: () => Get.to(() => ArtisanHelpView()),
            ),
            _SettingsTile(
              icon: Icons.language,
              title: AppStrings.language.tr,
              iconColor: primaryBlue,
              onTap: () => pushNamedRoute(AppRoutes.artisanLanguageView),
            ),
            // const SizedBox(height: 10),
            _SectionTitle(title: AppStrings.profileTitle.tr),
            _SettingsTile(
              icon: Icons.location_on,
              title: AppStrings.setLocation.tr,
              iconColor: primaryBlue,
              onTap: () => Get.to(() => ArtisanLocationSettingsView()),
            ),
            // _SettingsTile(
            //   icon: Icons.online_prediction_rounded,
            //   title: AppStrings.availability.tr,
            //   iconColor: primaryBlue,
            //   onTap: () => Get.to(() => ArtisanAvailabilityView()),
            // ),
            _SettingsTile(
              icon: Icons.camera_alt_rounded,
              title: AppStrings.profilephoto.tr,
              iconColor: primaryBlue,
              onTap: () => Get.toNamed(AppRoutes.artisanProfileEditView),
            ),
            _SettingsTile(
              icon: Icons.rate_review_rounded,
              title: AppStrings.reviews.tr,
              iconColor: primaryBlue,
              onTap: () => Get.to(() => ArtisanReviewsView()),
            ),
            // const SizedBox(height: 10),
            _SectionTitle(title: AppStrings.appearance.tr),

            // ✅ Theme tile (Reactive)
            Obx(() {
              final isDark = themeController.isDark.value;
              return _SettingsTile(
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                title: isDark
                    ? AppStrings.darkMode.tr
                    : AppStrings.lightMode.tr,
                iconColor: primaryBlue,
                onTap: () async {
                  await themeController.changeTheme();
                  final prefs = AppPrefs();
                  await prefs.setBool('isDark', themeController.isDark.value);
                },
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) async {
                    await themeController.changeTheme();
                    final prefs = AppPrefs();
                    await prefs.setBool('isDark', themeController.isDark.value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }),
            // const SizedBox(height: 10),
            _SectionTitle(title: AppStrings.more.tr),
            _SettingsTile(
              icon: Icons.info,
              title: AppStrings.about.tr,
              iconColor: primaryBlue,
              onTap: () => pushNamedRoute(AppRoutes.artisanAboutView),
            ),
            // const SizedBox(height: 10),
            _SectionTitle(title: AppStrings.security.tr),
            _SettingsTile(
              icon: Icons.logout,
              title: AppStrings.logout.tr,
              iconColor: AppColors.error,
              onTap: () => _confirmLogout(context),
              trailing: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppStrings.logout.tr, style: AppTextStyles.title(context)),
        content: Text(AppStrings.logoutConfirm.tr, style: AppTextStyles.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel.tr, style: AppTextStyles.body(context)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              authController.logout();
            },
            child: Text(
              AppStrings.logout.tr,
              style: AppTextStyles.body(context).copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Text(
        title,
        style: AppTextStyles.body(context).copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final outline = Theme.of(context).colorScheme.outline.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.20)),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withOpacity(0.6),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


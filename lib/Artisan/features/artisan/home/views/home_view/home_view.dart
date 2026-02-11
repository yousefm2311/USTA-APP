// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/profile_completion_helper.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/icon_broken.dart';
import 'package:usta/Artisan/core/utils/widgets/profile_completion_card.dart';
import 'package:usta/Artisan/features/artisan/earnings/controllers/earnings_controller.dart';
import 'package:usta/Artisan/features/artisan/notifications/views/artisan_notifications_view.dart';
import 'package:usta/Artisan/features/artisan/profile/controllers/profile_controller.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';
import 'package:usta/Artisan/features/artisan/wallet/controllers/wallet_controller.dart';

class ArtisanHomeView extends StatefulWidget {
  const ArtisanHomeView({super.key});

  @override
  State<ArtisanHomeView> createState() => _ArtisanHomeViewState();
}

class _ArtisanHomeViewState extends State<ArtisanHomeView>
    with SingleTickerProviderStateMixin {
  final ProfileController profileController = Get.find<ProfileController>();
  final ArtisanRequestsController requestsController =
      Get.find<ArtisanRequestsController>();
  final EarningsController earningsController = Get.find<EarningsController>();
  final WalletController walletController = Get.find<WalletController>();

  late final AnimationController _controller;
  late final Animation<double> _headerScale;
  late final Animation<Offset> _statsOffset;
  late final Animation<double> _walletOpacity;

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _headerScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _statsOffset = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _walletOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    try {
      await profileController.fetchProfile();
      await requestsController.fetchNewRequests();
      await requestsController.fetchActiveRequests();
      await requestsController.fetchHistoryRequests();
      await earningsController.fetchEarnings();
      await walletController.fetchWallet();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.artisanHomeTitle.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(onPressed: () {
            pushRoute(ArtisanNotificationsView());
          }, icon: Icon(IconBroken.Notification)),
        ],
      ),
      bottomSheet: Obx(() {
        final items = ProfileCompletionHelper.items();
        final completion = ProfileCompletionHelper.effectiveCompletionPercent(
          profileController.profile,
          items,
        );
        final missing = ProfileCompletionHelper.missingFields(
          profileController.profile,
        );
        final shouldShow = ProfileCompletionHelper.shouldShowBottomSheet(
          profileController.profile,
          items,
        );
        if (!shouldShow) return const SizedBox.shrink();

        final nextItem = ProfileCompletionHelper.firstMissingItem(
          items,
          missing,
        );
        final onCompleteTap =
            nextItem?.onTap ??
            () => pushNamedRoute(AppRoutes.artisanProfileEditView);

        return ProfileCompletionBottomSheet(
          completionPercent: completion,
          missingFields: missing,
          items: items,
          title: AppStrings.profileCompletionTitle.tr,
          subtitle: AppStrings.profileCompletionSubtitle.tr,
          missingCtaLabel: AppStrings.edit.tr,
          primaryCtaLabel: AppStrings.profileCompletionCta.tr,
          onPrimaryCta: onCompleteTap,
          onHide: () {
            ProfileCompletionHelper.hideBottomSheet(
              profileController.profile,
              missing,
            );
            setState(() {});
          },
          hideLabel: AppStrings.profileCompletionDismiss.tr,
          expandLabel: AppStrings.profileCompletionViewDetails.tr,
          collapseLabel: AppStrings.profileCompletionHideDetails.tr,
          percentLabelBuilder: (percent) => AppStrings
              .profileCompletionPercentLabel
              .trParams({'percent': '$percent'}),
        );
      }),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: Obx(() {
            final items = ProfileCompletionHelper.items();
            final completion =
                ProfileCompletionHelper.effectiveCompletionPercent(
                  profileController.profile,
                  items,
                );
            final shouldShow = ProfileCompletionHelper.shouldShowBottomSheet(
              profileController.profile,
              items,
            );
            final bottomPadding = shouldShow && completion < 100 ? 230.0 : 22.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleTransition(
                    scale: _headerScale,
                    child: _headerCard(context),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    AppStrings.quickStats.tr,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  SlideTransition(
                    position: _statsOffset,
                    child: Obx(() {
                      return Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => pushNamedRoute(
                                AppRoutes.artisanCustomerRequestsView,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: _statCard(
                                title: AppStrings.statNew.tr,
                                number: requestsController.newRequests.length
                                    .toString(),
                                icon: Icons.fiber_new_rounded,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => pushNamedRoute(
                                AppRoutes.artisanActiveRequestsView,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: _statCard(
                                title: AppStrings.statActive.tr,
                                number: requestsController.activeRequests.length
                                    .toString(),
                                icon: Icons.timelapse_rounded,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => pushNamedRoute(
                                AppRoutes.artisanCompletedRequestsView,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: _statCard(
                                title: AppStrings.statCompleted.tr,
                                number: requestsController
                                    .historyRequests
                                    .length
                                    .toString(),
                                icon: Icons.check_circle_rounded,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    AppStrings.walletTitle.tr,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  AnimatedBuilder(
                    animation: _walletOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _walletOpacity.value,
                        child: child,
                      );
                    },
                    child: Obx(() {
                      final loadingWallet = walletController.loading.value;
                      final loadingEarn = earningsController.loading.value;

                      final balance = walletController.balance.value;
                      final monthEarn = earningsController.month.value;
                      final totalEarn = earningsController.total.value;

                      return InkWell(
                        onTap: () =>
                            pushNamedRoute(AppRoutes.artisanWalletView),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            // border: Border.all(
                            //   color: scheme.outline.withOpacity(0.12),
                            // ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryBlue,
                                      const Color(0xFF1E40AF),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.walletSubtitle.tr,
                                      style: AppTextStyles.small(
                                        context,
                                      ).copyWith(fontSize: 12.5),
                                    ),
                                    const SizedBox(height: 6),
                                    loadingWallet
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "$balance EGP",
                                            style: AppTextStyles.body(context)
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                          ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _miniMetric(
                                            title: 'هذا الشهر',
                                            value: loadingEarn
                                                ? null
                                                : "${monthEarn.toStringAsFixed(2)} EGP",
                                            icon: Icons.calendar_month_rounded,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _miniMetric(
                                            title: 'الإجمالي',
                                            value: loadingEarn
                                                ? null
                                                : "${totalEarn.toStringAsFixed(2)} EGP",
                                            icon: Icons.all_inclusive_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: scheme.onSurface.withOpacity(0.45),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    AppStrings.quickActions.tr,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _quickActionsGrid(context),

                  const SizedBox(height: 22),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue.withOpacity(0.95), const Color(0xFF60A5FA)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              scheme.brightness == Brightness.dark ? 0.22 : 0.10,
            ),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.construction, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.homeHeadline.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Obx(() {
                    final online = profileController.isOnline;
                    return Text(
                      online ? AppStrings.online.tr : AppStrings.offline.tr,
                      style: const TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    );
                  }),
                  Obx(() {
                    final online = profileController.isOnline;
                    return Switch(
                      value: online,
                      onChanged: (v) => profileController.toggleOnline(v),
                      activeThumbColor: Colors.limeAccent,
                      inactiveThumbColor: Colors.grey[300],
                      inactiveTrackColor: Colors.white24,
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: h * 0.056),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryBlue,
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              onPressed: () => pushNamedRoute(AppRoutes.artisanNewRequestsView),
              icon: const Icon(Icons.flash_on_rounded, size: 20),
              label: Text(
                AppStrings.newRequestsCta.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetric({
    required String title,
    required String? value,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(
          scheme.brightness == Brightness.dark ? 0.25 : 0.55,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.small(context).copyWith(fontSize: 11.5),
                ),
                const SizedBox(height: 4),
                value == null
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        value,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String number,
    required IconData icon,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: scheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.22)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: TextStyle(
              fontFamily: "Cairo",
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small(context),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsGrid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // ✅ خليها تتغير حسب عرض الجهاز
    final crossAxisCount = w < 360 ? 2 : 3;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.12,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _shortcut(
          AppStrings.quickActionsServices.tr,
          Icons.build,
          onTap: () => pushNamedRoute(AppRoutes.artisanServicesPricingView),
        ),
        _shortcut(
          AppStrings.quickActionsHistory.tr,
          Icons.history_rounded,
          onTap: () => pushNamedRoute(AppRoutes.artisanHistoryView),
        ),
        _shortcut(
          AppStrings.quickActionsWallet.tr,
          Icons.account_balance_wallet,
          onTap: () => pushNamedRoute(AppRoutes.artisanWalletView),
        ),
        _shortcut(
          AppStrings.quickActionsPortfolio.tr,
          Icons.photo_library,
          onTap: () => pushNamedRoute(AppRoutes.artisanPortfolioView),
        ),
        _shortcut(
          AppStrings.quickActionsNotifications.tr,
          Icons.notifications_active,
          onTap: () => pushNamedRoute(AppRoutes.artisanNotificationsView),
        ),
        _shortcut(
          AppStrings.quickActionsProfile.tr,
          Icons.person,
          onTap: () => pushNamedRoute(AppRoutes.profile),
        ),
      ],
    );
  }

  Widget _shortcut(String title, IconData icon, {VoidCallback? onTap}) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            // border: Border.all(color: scheme.outline.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight;
              final compact = maxH < 78;
              final iconSize = compact ? 38.0 : 44.0;
              final glyphSize = compact ? 20.0 : 24.0;
              final spacing = compact ? 6.0 : 10.0;
              final fontSize = compact ? 12.0 : 13.0;
              final maxLines = compact ? 1 : 2;
              final lineHeight = compact ? 1.2 : 1.5;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: glyphSize, color: primaryBlue),
                  ),
                  SizedBox(height: spacing),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontSize: fontSize, height: lineHeight),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

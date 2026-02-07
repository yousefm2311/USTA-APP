import 'dart:math' as math;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/features/customer/dashboard/views/customer_dashboard_view.dart';
import 'package:usta/Customer/features/customer/favorites/views/customer_favorites_view.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_ai_feedback_view.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_coupons_view.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_rewards_view.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';
import 'package:usta/Customer/features/customer/notifications/views/customer_notifications_view.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_wallet_view.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final GlobalKey _quickLinksKey = GlobalKey();

  final List<_QuickLinkEntry> _links = [
    _QuickLinkEntry(
      title: 'المفضلة',
      icon: Icons.favorite,
      target: CustomerFavoritesView(),
    ),
    _QuickLinkEntry(
      title: 'الكوبونات',
      icon: Icons.discount,
      target: CustomerCouponsView(),
    ),
    _QuickLinkEntry(
      title: 'المحفظة',
      icon: Icons.account_balance_wallet,
      target: CustomerWalletView(),
    ),
    _QuickLinkEntry(
      title: 'المكافآت',
      icon: Icons.point_of_sale_rounded,
      target: CustomerRewardsView(),
    ),
    _QuickLinkEntry(
      title: 'اقتراحات بالذكاء الاصطناعي',
      icon: Icons.rate_review_outlined,
      target: CustomerAIFeedbackView(),
    ),
    _QuickLinkEntry(
      title: 'لوحة التحكم',
      icon: IconBroken.Graph,
      target: CustomerDashboardView(),
    ),
  ];

  void _showQuickLinksMenu() {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final box =
        _quickLinksKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;
    final mediaPadding = MediaQuery.of(context).padding;
    const screenPadding = 12.0;

    final overlaySize = overlay.size;
    final maxWidth = overlaySize.width -
        mediaPadding.left -
        mediaPadding.right -
        screenPadding * 2;
    final popupWidth = math.min(320.0, maxWidth);

    final minLeft = mediaPadding.left + screenPadding;
    final maxLeft = overlaySize.width -
        mediaPadding.right -
        screenPadding -
        popupWidth;
    final boundedMaxLeft = math.max(minLeft, maxLeft);
    final desiredLeft = offset.dx + size.width - popupWidth;
    final safeLeft =
        desiredLeft.clamp(minLeft, boundedMaxLeft) as double;

    const approxHeight = 276.0;
    final minTop = mediaPadding.top + screenPadding;
    final maxTop = overlaySize.height -
        mediaPadding.bottom -
        screenPadding -
        approxHeight;
    final boundedMaxTop = math.max(minTop, maxTop);
    final belowTop = offset.dy + size.height + 8;
    final desiredTop =
        belowTop <= boundedMaxTop ? belowTop : offset.dy - approxHeight - 8;
    final safeTop = desiredTop.clamp(minTop, boundedMaxTop) as double;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'quick_links'.tr,
      pageBuilder: (ctx, _, __) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              top: safeTop,
              left: safeLeft,
              child: _QuickLinksPopup(
                links: _links,
                width: popupWidth,
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifCtrl = Get.find<CustomerNotificationsController>();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("مرحباً بك في أستا".tr, style: AppText.title),
              const SizedBox(height: 4),
              Text(
                "اختر الخدمة المناسبة لك بسرعة".tr,
                style: AppText.subtitle,
              ),
            ],
          ),
        ),
        _QuickLinksButton(
          iconKey: _quickLinksKey,
          onTap: _showQuickLinksMenu,
        ),
        const SizedBox(width: 10),
        Obx(() {
          final count = notifCtrl.unreadCount;
          return InkWell(
            onTap: () => Get.to(() => const CustomerNotificationsView()),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    IconlyLight.notification,
                    size: 24,
                  ),
                  if (count > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: _badge(count),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _badge(int count) {
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _QuickLinksButton extends StatelessWidget {
  final GlobalKey iconKey;
  final VoidCallback onTap;

  const _QuickLinksButton({
    required this.iconKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        key: iconKey,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.grid_view_rounded,
          size: 24,
        ),
      ),
    );
  }
}

class _QuickLinksPopup extends StatelessWidget {
  final List<_QuickLinkEntry> links;
  final double width;
  final VoidCallback onClose;

  const _QuickLinksPopup({
    required this.links,
    required this.width,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final bg = Color.alphaBlend(
      Colors.white.withOpacity(isDark ? 0.06 : 0.9),
      scheme.surface,
    );
    final border = scheme.outlineVariant.withOpacity(isDark ? 0.4 : 0.25);
    final shadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'روابط سريعة'.tr,
                        style: const TextStyle(
                          fontFamily: AppText.font,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'انتقل لأي صفحة بنقرة واحدة'.tr,
                        style: TextStyle(
                          fontFamily: AppText.font,
                          fontSize: 11,
                          color: scheme.onSurface.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 86,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: links.length,
              itemBuilder: (_, i) => _QuickLinkMiniTile(
                entry: links[i],
                onTap: () {
                  onClose();
                  Get.to(() => links[i].target);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkMiniTile extends StatelessWidget {
  final _QuickLinkEntry entry;
  final VoidCallback onTap;

  const _QuickLinkMiniTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final bg = Color.alphaBlend(
      Colors.white.withOpacity(isDark ? 0.03 : 0.85),
      scheme.surface,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(isDark ? 0.35 : 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                entry.icon,
                color: AppColors.primaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.title.tr,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppText.font,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkEntry {
  final String title;
  final IconData icon;
  final Widget target;

  const _QuickLinkEntry({
    required this.title,
    required this.icon,
    required this.target,
  });
}


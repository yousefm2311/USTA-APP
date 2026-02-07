import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/features/customer/dashboard/views/customer_dashboard_view.dart';
import 'package:usta/Customer/features/customer/favorites/views/customer_favorites_view.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_ai_feedback_view.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_coupons_view.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_rewards_view.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_wallet_view.dart';
import 'package:usta/Customer/features/customer/home/widgets/quick_link_tile.dart';

class QuickLinksGrid extends StatelessWidget {
  const QuickLinksGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 120,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        QuickLinkTile(
          title: "المفضلة".tr,
          icon: Icons.favorite,
          go: CustomerFavoritesView(),
        ),
        QuickLinkTile(
          title: "الكوبونات".tr,
          icon: Icons.discount,
          go: CustomerCouponsView(),
        ),
        QuickLinkTile(
          title: "المحفظة".tr,
          icon: Icons.account_balance_wallet,
          go: CustomerWalletView(),
        ),
        QuickLinkTile(
          title: "المكافآت".tr,
          icon: Icons.point_of_sale_rounded,
          go: CustomerRewardsView(),
        ),
        QuickLinkTile(
          title: "اقتراحات بالذكاء الاصطناعي".tr,
          icon: Icons.rate_review_outlined,
          go: CustomerAIFeedbackView(),
        ),
        QuickLinkTile(
          title: "لوحة التحكم".tr,
          icon: IconBroken.Graph,
          go: CustomerDashboardView(),
        ),
      ],
    );
  }
}


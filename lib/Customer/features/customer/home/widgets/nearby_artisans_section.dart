import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';
import 'package:usta/Customer/features/customer/home/widgets/artisan_card.dart';

class NearbyArtisansSection extends StatelessWidget {
  final CustomerExploreController explore;
  const NearbyArtisansSection({super.key, required this.explore});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (explore.loadingNearby.value) {
        return SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => ShimmerSkeletons.artisanHorizontalCard(
              height: 175,
              width: 175,
              context: context,
            ),
          ),
        );
      }

      if (explore.nearby.isEmpty) {
        return Text(
          'لا يوجد حرفيين قريبين حالياً'.tr,
          style: const TextStyle(fontFamily: AppText.font),
        );
      }

      return SizedBox(
        height: 196,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: explore.nearby.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => ArtisanCard(artisan: explore.nearby[i]),
        ),
      );
    });
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';
import 'package:usta/Customer/features/customer/home/widgets/artisan_row.dart';

class TopRatedSection extends StatelessWidget {
  final CustomerExploreController explore;
  const TopRatedSection({super.key, required this.explore});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (explore.loadingTop.value) {
        return Column(
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerSkeletons.listTile(height: 72),
            ),
          ),
        );
      }

      if (explore.topRated.isEmpty) {
        return Text(
          'لا يوجد حرفيين مميزين حالياً'.tr,
          style: const TextStyle(fontFamily: AppText.font),
        );
      }

      return Column(
        children: explore.topRated.take(4).map<Widget>((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ArtisanRow(artisan: e),
          );
        }).toList(),
      );
    });
  }
}


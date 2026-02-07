import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/top_rated_artisan_tile.dart';

class ExploreTopRatedSection extends StatelessWidget {
  final CustomerExploreController controller;
  final Color primaryColor;
  final VoidCallback onViewAll;

  const ExploreTopRatedSection({
    super.key,
    required this.controller,
    required this.primaryColor,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loadingTop.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final list = controller.topRated;
      if (list.isEmpty) {
        return Text(
          'لا توجد نتائج حالياً'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الأعلى تقييماً'.tr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'عرض الكل'.tr,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...list.take(5).map(
                (artisan) => TopRatedArtisanTile(
                  artisan: artisan,
                  primaryColor: primaryColor,
                ),
              ),
        ],
      );
    });
  }
}


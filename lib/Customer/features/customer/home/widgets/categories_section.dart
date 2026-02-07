import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/constants/app_assets.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_list_view.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_explore_view.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';
import 'package:usta/Customer/features/customer/home/widgets/section_header.dart';

class CategoriesSection extends StatelessWidget {
  final CustomerExploreController explore;
  const CategoriesSection({super.key, required this.explore});

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionHeader(title: "الفئات".tr)),
            TextButton(
              onPressed: () => Get.to(() => const CustomerExploreView()),
              child: Text(
                "عرض الكل".tr,
                style: const TextStyle(fontFamily: AppText.font),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (explore.loadingCategories.value) {
            return SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) =>
                    ShimmerSkeletons.gridCard(height: 82, borderRadius: 14),
              ),
            );
          }

          final cats = explore.categories;
          if (cats.isEmpty) {
            return Text(
              'لا توجد فئات متاحة حالياً'.tr,
              style: const TextStyle(fontFamily: AppText.font),
            );
          }

          return SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final name =
                    cats[i]['name'] ?? cats[i]['title'] ?? 'غير محدد'.tr;
                return InkWell(
                  onTap: () => Get.to(
                    () => CustomerArtisanListView(
                      categoryName: name.toString(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.asset(
                            AssetsData.logo,
                            scale: 1,
                            color: Get.isDarkMode
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppText.font,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}


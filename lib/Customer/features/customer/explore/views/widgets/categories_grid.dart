import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';

class ExploreCategoriesGrid extends StatelessWidget {
  final CustomerExploreController controller;
  final Color primaryColor;
  final ValueChanged<String> onTapCategory;

  const ExploreCategoriesGrid({
    super.key,
    required this.controller,
    required this.primaryColor,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (controller.loadingCategories.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final cats = controller.categories;
      if (cats.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'لا توجد فئات متاحة'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: .92,
        ),
        itemBuilder: (context, i) {
          final item = cats[i];
          final name = (item['name'] ?? item['title'] ?? 'فئة'.tr).toString();
          final icon = item['icon']?.toString();
          return InkWell(
            onTap: () => onTapCategory(name),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Icon(
                      Icons.category,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (icon != null && icon.isNotEmpty) const SizedBox(height: 0),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}


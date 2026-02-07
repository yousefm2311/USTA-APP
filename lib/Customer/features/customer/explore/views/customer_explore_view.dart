import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/customer_live_map_view.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_list_view.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_explore_filters_view.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/categories_grid.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/explore_search_field.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/explore_section_title.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/top_rated_section.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerExploreView extends StatefulWidget {
  const CustomerExploreView({super.key});

  @override
  State<CustomerExploreView> createState() => _CustomerExploreViewState();
}

class _CustomerExploreViewState extends State<CustomerExploreView> {
  final controller = Get.find<CustomerExploreController>();
  final searchCtrl = TextEditingController();

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      AppSnackBar.show(
        'تنبيه'.tr,
        'اكتب كلمة بحث الأول'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    await controller.searchArtisans(query: q);
    Get.to(() => CustomerArtisanListView(categoryName: q));
  }

  Future<void> _openCategory(String name) async {
    final cat = name.trim();
    if (cat.isEmpty) return;
    await controller.searchArtisans(category: cat);
    Get.to(() => CustomerArtisanListView(categoryName: cat));
  }

  Future<void> _refresh() async {
    try {
      if (controller.categories.isEmpty) {
        await controller.fetchCategories.call();
      } else {
        await controller.fetchCategories.call();
      }
      await controller.fetchTopRated.call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "اكتشاف الحرفيين".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
          actions: [
            IconButton(
              onPressed: () => Get.to(() => const CustomerExploreFiltersView()),
              icon: const Icon(Icons.filter_alt_outlined),
              tooltip: 'فلاتر'.tr,
            ),
            IconButton(
              onPressed: () => Get.to(() => CustomerLiveMapView()),
              icon: const Icon(Icons.map_outlined),
              tooltip: 'الخريطة'.tr,
            ),
          ],
        ),
        body: RefreshIndicator(
          color: primaryBlue,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ExploreSearchField(
                controller: searchCtrl,
                onSearch: () => _doSearch(searchCtrl.text),
                onClear: () => setState(() => searchCtrl.clear()),
                onSubmitted: _doSearch,
                showClear: searchCtrl.text.trim().isNotEmpty,
              ),
              const SizedBox(height: 18),

              ExploreSectionTitle(title: "الفئات".tr),
              const SizedBox(height: 10),
              ExploreCategoriesGrid(
                controller: controller,
                primaryColor: primaryBlue,
                onTapCategory: _openCategory,
              ),

              const SizedBox(height: 18),
              ExploreTopRatedSection(
                controller: controller,
                primaryColor: primaryBlue,
                onViewAll: () {
                  Get.to(
                    () => CustomerArtisanListView(
                      categoryName: 'الأعلى تقييماً',
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}



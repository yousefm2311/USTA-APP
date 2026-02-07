import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/customer_artisan_details_view.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/widgets/artisan_list_card.dart';
import 'package:usta/Customer/features/customer/favorites/controllers/customer_favorites_controller.dart';

class CustomerArtisanListView extends StatefulWidget {
  final String categoryName;

  const CustomerArtisanListView({super.key, required this.categoryName});

  @override
  State<CustomerArtisanListView> createState() =>
      _CustomerArtisanListViewState();
}

class _CustomerArtisanListViewState extends State<CustomerArtisanListView>
    with AutomaticKeepAliveClientMixin {
  final CustomerExploreController controller =
      Get.find<CustomerExploreController>();
  final CustomerFavoritesController favCtrl =
      Get.find<CustomerFavoritesController>();

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.searchArtisans(category: widget.categoryName);
    });
  }

  @override
  void didUpdateWidget(covariant CustomerArtisanListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryName != widget.categoryName) {
      controller.searchArtisans(category: widget.categoryName);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            widget.categoryName.tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: Obx(() {
          if (controller.loadingSearch.value) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => ShimmerSkeletons.listTile(height: 92),
            );
          }

          final list = controller.searchResults;

          if (list.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد حرفيين في هذا القسم حالياً'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: () async {
              await controller.searchArtisans(category: widget.categoryName);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final artisan = list[index];
                final id = (artisan['_id'] ?? artisan['id'])?.toString() ?? '';
                return ArtisanListCard(
                  artisan: artisan,
                  favorites: favCtrl,
                  primaryColor: primaryBlue,
                  onTap: () {
                    if (id.isEmpty) return;
                    Get.to(
                      () => CustomerArtisanDetailsView(
                        artisanId: id,
                        artisan: artisan,
                      ),
                    );
                  },
                  onToggleFavorite: () async {
                    if (id.isEmpty) return;
                    if (favCtrl.isFavorite(id)) {
                      await favCtrl.remove(id);
                    } else {
                      await favCtrl.add(id, artisan: artisan);
                    }
                    setState(() {});
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}


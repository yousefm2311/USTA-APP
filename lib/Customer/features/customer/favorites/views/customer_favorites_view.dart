import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/favorites/controllers/customer_favorites_controller.dart';
import 'package:usta/Customer/features/customer/favorites/views/widgets/favorite_card.dart';

class CustomerFavoritesView extends StatelessWidget {
  CustomerFavoritesView({super.key});

  final controller = Get.put(CustomerFavoritesController());

  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            "المفضلة".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.favorites.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد عناصر حالياً'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }

          return RefreshIndicator(
            color: blue,
            onRefresh: controller.fetchFavorites,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.favorites.length,
              itemBuilder: (_, i) => FavoriteCard(
                artisan: controller.favorites[i],
                controller: controller,
                primaryColor: blue,
              ),
            ),
          );
        }),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/favorites/controllers/customer_favorites_controller.dart';

class ArtisanFavoriteButton extends StatelessWidget {
  final CustomerFavoritesController favorites;
  final String artisanId;
  final Map<String, dynamic> artisan;

  const ArtisanFavoriteButton({
    super.key,
    required this.favorites,
    required this.artisanId,
    required this.artisan,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFav = favorites.isFavorite(artisanId);
      final disabled =
          artisanId.isEmpty || favorites.saving.value || favorites.loading.value;

      return SizedBox(
        height: 46,
        child: ElevatedButton.icon(
          onPressed: disabled
              ? null
              : () async {
                  if (isFav) {
                    await favorites.remove(artisanId);
                  } else {
                    await favorites.add(artisanId, artisan: artisan);
                  }
                },
          icon: favorites.saving.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
          ),
          label: Text(
            isFav ? "إزالة من المفضلة".tr : "إضافة للمفضلة".tr,
            style: const TextStyle(fontFamily: "Cairo", fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFav ? Colors.redAccent : Colors.white10,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white10.withOpacity(0.25),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
          ),
        ),
      );
    });
  }
}


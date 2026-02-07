import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/customer_artisan_details_view.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';

class ArtisanCard extends StatelessWidget {
  final Map<String, dynamic> artisan;
  const ArtisanCard({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    final name = artisan['name'] ?? artisan['artisanName'] ?? 'حرفي'.tr;
    final distance = artisan['distance'];
    final rating =
        artisan['rating'] ?? artisan['avgRating'] ?? artisan['average'] ?? '-';
    final border = AppColors.border(context);
    final distanceText = distance != null
        ? '${'يبعد'.tr} ${distance.toString()} ${'كم'.tr} • '
        : '';

    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryBlue.withOpacity(.16),
                child: const Icon(Icons.person, color: AppColors.primaryBlue),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border),
                ),
                child: Text(
                  "متاح".tr,
                  style: TextStyle(
                    fontFamily: AppText.font,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppText.font,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$distanceText${'تقييم'.tr} $rating ★',
            style: const TextStyle(
              fontFamily: AppText.font,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final id = (artisan['_id'] ?? artisan['id'])?.toString() ?? '';
                if (id.isNotEmpty) {
                  Get.to(
                    () => CustomerArtisanDetailsView(
                      artisanId: id,
                      artisan: artisan,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: Text(
                "عرض".tr,
                style: const TextStyle(fontFamily: AppText.font),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


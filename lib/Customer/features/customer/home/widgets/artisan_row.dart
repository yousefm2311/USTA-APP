import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/customer_artisan_details_view.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';

class ArtisanRow extends StatelessWidget {
  final Map<String, dynamic> artisan;
  const ArtisanRow({super.key, required this.artisan});

  @override
  Widget build(BuildContext context) {
    final name = artisan['name'] ?? artisan['artisanName'] ?? 'حرفي'.tr;
    final rating =
        artisan['rating'] ?? artisan['avgRating'] ?? artisan['average'] ?? '-';
    final category =
        artisan['profession'] ??
        artisan['category'] ??
        artisan['serviceType'] ??
        '';

    return AppCard(
      radius: 14,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBlue.withOpacity(.16),
            child: const Icon(Icons.person, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 4),
                Text(
                  '$category • $rating ★',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppText.font,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
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
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}


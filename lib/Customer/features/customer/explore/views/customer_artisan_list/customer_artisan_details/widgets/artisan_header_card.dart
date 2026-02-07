import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_card.dart';

class ArtisanHeaderCard extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final double? rating;
  final dynamic ratingCount;
  final String? snippet;
  final Color primaryColor;
  final Color borderColor;
  final Widget favoriteButton;
  final VoidCallback onChat;

  const ArtisanHeaderCard({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.rating,
    required this.ratingCount,
    required this.snippet,
    required this.primaryColor,
    required this.borderColor,
    required this.favoriteButton,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return ArtisanCard(
      borderColor: borderColor,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: primaryColor.withOpacity(0.12),
                backgroundImage: photoUrl != null
                    ? CachedNetworkImageProvider(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? Icon(
                        Icons.person,
                        color: primaryColor,
                        size: 34,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rating != null
                              ? rating!.toStringAsFixed(1)
                              : 'لا يوجد تقييم'.tr,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (ratingCount != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '($ratingCount ${'تقييم'.tr})',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (snippet != null && snippet!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        snippet!.trim(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: favoriteButton),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(IconBroken.Chat, size: 18),
                    label: Text(
                      'محادثة'.tr,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


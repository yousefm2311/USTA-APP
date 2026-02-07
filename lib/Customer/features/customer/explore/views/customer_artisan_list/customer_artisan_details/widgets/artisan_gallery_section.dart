import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ArtisanGallerySection extends StatelessWidget {
  final List<String> imageUrls;
  final Color borderColor;
  final ValueChanged<int> onOpen;

  const ArtisanGallerySection({
    super.key,
    required this.imageUrls,
    required this.borderColor,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            'لا توجد صور متاحة حتى الآن'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          return GestureDetector(
            onTap: () => onOpen(index),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.white10),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.white10,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

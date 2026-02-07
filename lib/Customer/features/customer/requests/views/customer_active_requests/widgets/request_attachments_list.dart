import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_section_card.dart';

class RequestAttachmentsList extends StatelessWidget {
  const RequestAttachmentsList({
    super.key,
    required this.urls,
    required this.onOpenGallery,
  });

  final List<String> urls;
  final void Function(List<String> urls, int initialIndex) onOpenGallery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (urls.isEmpty) {
      return RequestSectionCard(
        child: Text(
          'لا توجد مرفقات'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = urls[index];
          return GestureDetector(
            onTap: () => onOpenGallery(urls, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: scheme.onSurface.withOpacity(0.06)),
                  errorWidget: (_, __, ___) => Container(
                    color: scheme.surface,
                    child: Icon(Icons.broken_image, color: scheme.onSurface),
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


import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TopRatedArtisanTile extends StatelessWidget {
  final Map<String, dynamic> artisan;
  final Color primaryColor;
  final VoidCallback? onTap;

  const TopRatedArtisanTile({
    super.key,
    required this.artisan,
    required this.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name =
        (artisan['name'] ?? artisan['artisanName'] ?? 'فني'.tr).toString();
    final rating =
        (artisan['rating'] ?? artisan['avgRating'] ?? artisan['average'] ?? '-')
            .toString();

    final category = (artisan['profession'] ??
            artisan['category'] ??
            artisan['serviceType'] ??
            '')
        .toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: primaryColor.withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(
                  fontFamily: "Cairo",
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 44),
                    child: Text(
                      rating,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: "Cairo",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/features/customer/favorites/controllers/customer_favorites_controller.dart';

class ArtisanListCard extends StatelessWidget {
  final Map<String, dynamic> artisan;
  final CustomerFavoritesController favorites;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const ArtisanListCard({
    super.key,
    required this.artisan,
    required this.favorites,
    required this.primaryColor,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = artisan['name'] ?? artisan['artisanName'] ?? 'حرفي'.tr;
    final distance = artisan['distance'];
    final rating =
        artisan['rating'] ?? artisan['avgRating'] ?? artisan['average'] ?? '-';
    final id = (artisan['_id'] ?? artisan['id'])?.toString() ?? '';
    final photo = _photoUrl(artisan);

    String subtitle = '${'تقييم'.tr} $rating';
    if (distance != null) {
      final d = double.tryParse(distance.toString());
      final dText = d != null ? d.toStringAsFixed(1) : distance.toString();
      subtitle += ' • $dText ${'كم'.tr}';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: primaryColor.withOpacity(0.15),
              backgroundImage: (photo != null && photo.isNotEmpty)
                  ? CachedNetworkImageProvider(photo)
                  : null,
              child: (photo == null || photo.isEmpty)
                  ? Icon(Icons.person, color: primaryColor, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toString(),
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                favorites.isFavorite(id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.redAccent,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String? _photoUrl(Map<String, dynamic> artisan) {
    final direct =
        artisan['photo'] ??
        artisan['photoUrl'] ??
        artisan['avatar'] ??
        artisan['profilePhoto'] ??
        artisan['image'];

    if (direct is String && direct.trim().isNotEmpty) {
      return _fullUrl(direct.trim());
    }

    final portfolio = artisan['portfolio'];
    if (portfolio is List && portfolio.isNotEmpty) {
      final first = portfolio.first;
      if (first is Map) {
        final path = first['path'] ?? first['url'] ?? first['image'];
        if (path is String && path.trim().isNotEmpty) {
          return _fullUrl(path.trim());
        }
      } else if (first is String && first.trim().isNotEmpty) {
        return _fullUrl(first.trim());
      }
    }

    return null;
  }

  String _fullUrl(String path) {
    if (path.isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    var origin = (AppConfig.instance.origin).trim();

    if (origin.isNotEmpty &&
        !origin.startsWith('http://') &&
        !origin.startsWith('https://')) {
      origin = 'http://$origin';
    }
    if (origin.endsWith('/')) origin = origin.substring(0, origin.length - 1);

    if (path.startsWith('/')) {
      return origin.isEmpty ? path : '$origin$path';
    }

    return origin.isEmpty ? path : '$origin/$path';
  }
}


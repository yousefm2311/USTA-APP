import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/customer_artisan_details_view.dart';
import 'package:usta/Customer/features/customer/favorites/controllers/customer_favorites_controller.dart';

class FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> artisan;
  final CustomerFavoritesController controller;
  final Color primaryColor;

  const FavoriteCard({
    super.key,
    required this.artisan,
    required this.controller,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = artisan['name'] ?? artisan['artisanName'] ?? 'مزود الخدمة'.tr;
    final rating =
        artisan['rating'] ??
        artisan['avgRating'] ??
        artisan['averageRating'] ??
        artisan['average'] ??
        '—';
    final category =
        artisan['serviceType'] ??
        artisan['category'] ??
        artisan['profession'] ??
        '';

    final id =
        (artisan['_id'] ?? artisan['id'] ?? artisan['artisanId'])?.toString() ??
        '';
    final photo = _photoUrl(artisan);

    return InkWell(
      onTap: () {
        if (id.isEmpty) return;
        Get.to(
          () => CustomerArtisanDetailsView(artisanId: id, artisan: artisan),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor.withOpacity(.15),
              backgroundImage: (photo != null && photo.isNotEmpty)
                  ? CachedNetworkImageProvider(photo)
                  : null,
              child: (photo == null || photo.isEmpty)
                  ? Icon(Icons.person, color: primaryColor, size: 30)
                  : null,
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
                      fontFamily: "Cairo",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.toString()} • ${rating.toString()} ★',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: id.isEmpty
                  ? null
                  : () async {
                      await controller.remove(id);
                    },
              icon: Icon(
                Icons.delete,
                color: Colors.redAccent.withOpacity(.85),
              ),
              tooltip: 'حذف من المفضلة'.tr,
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


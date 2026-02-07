import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_room_view.dart';
import 'package:usta/Customer/features/customer/customer_live_map_view.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_bio_card.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_bottom_buttons.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_favorite_button.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_gallery_section.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_header_card.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_pricing_card.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_section_title.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_services_chips.dart';
import 'package:usta/Customer/features/customer/favorites/controllers/customer_favorites_controller.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/views/customer_create_request_view.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerArtisanDetailsView extends StatefulWidget {
  const CustomerArtisanDetailsView({super.key, this.artisanId, this.artisan});

  final String? artisanId;
  final Map<String, dynamic>? artisan;

  @override
  State<CustomerArtisanDetailsView> createState() =>
      _CustomerArtisanDetailsViewState();
}

class _CustomerArtisanDetailsViewState
    extends State<CustomerArtisanDetailsView> {
  final explore = Get.find<CustomerExploreController>();
  late final CustomerFavoritesController fav;

  Color get primaryBlue => const Color(0xFF2563EB);
  Color get border => Colors.white10;

  @override
  void initState() {
    super.initState();
    fav = Get.isRegistered<CustomerFavoritesController>()
        ? Get.find<CustomerFavoritesController>()
        : Get.put(CustomerFavoritesController(), permanent: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.artisan != null) {
        explore.artisanDetail.value = widget.artisan;
      }
      if ((widget.artisanId ?? '').isNotEmpty) {
        await explore.fetchArtisanDetails(widget.artisanId!);
      }
    });
  }

  Future<void> _refresh() async {
    if ((widget.artisanId ?? '').isNotEmpty) {
      await explore.fetchArtisanDetails(widget.artisanId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'تفاصيل الحرفي'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        body: Obx(() {
          final artisan = (explore.artisanDetail.value ?? widget.artisan ?? {})
              .cast<String, dynamic>();
          if (explore.loadingDetail.value && artisan.isEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, __) => ShimmerSkeletons.listTile(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: 8,
            );
          }
          if (!explore.loadingDetail.value && artisan.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'تعذر تحميل بيانات الحرفي'.tr,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'حاول مرة أخرى.'.tr,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'إعادة المحاولة'.tr,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final artisanId =
              (widget.artisanId ?? artisan['_id'] ?? artisan['id'])
                  ?.toString() ??
              '';

          final name =
              artisan['name']?.toString() ?? artisan['artisanName']?.toString();
          final displayName = (name == null || name.trim().isEmpty)
              ? 'بدون اسم'.tr
              : name.trim();

          final rating = _ratingValue(artisan);
          final ratingCount = (artisan['rating'] is Map)
              ? artisan['rating']['count']
              : null;

          final bio =
              artisan['bio']?.toString() ??
              artisan['description']?.toString() ??
              'لا توجد نبذة متاحة'.tr;

          final services =
              artisan['services'] ??
              artisan['categories'] ??
              artisan['skills'] ??
              [];
          final servicesList = _extractServicesNames(services);

          final photos =
              artisan['photos'] ??
              artisan['gallery'] ??
              artisan['images'] ??
              artisan['portfolio'] ??
              [];
          final imageUrls = _imageUrls(photos);

          final photoUrl = _firstPhoto(artisan, photos);
          final coords = _extractCoords(artisan);

          final firstServiceName = _extractFirstServiceName(artisan);
          final pricingRows = _pricingRows(artisan['pricing']);

          final snippet =
              artisan['profession']?.toString() ??
              (firstServiceName.isNotEmpty ? firstServiceName : null);

          return RefreshIndicator(
            onRefresh: _refresh,
            color: primaryBlue,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ArtisanHeaderCard(
                  displayName: displayName,
                  photoUrl: photoUrl,
                  rating: rating,
                  ratingCount: ratingCount,
                  snippet: snippet,
                  primaryColor: primaryBlue,
                  borderColor: border,
                  favoriteButton: ArtisanFavoriteButton(
                    favorites: fav,
                    artisanId: artisanId,
                    artisan: artisan,
                  ),
                  onChat: () {
                    if (artisanId.isEmpty) {
                      AppSnackBar.show(
                        'تنبيه'.tr,
                        'لم يتم العثور على معرف الحرفي'.tr,
                      );
                      return;
                    }
                    Get.to(
                      () => CustomerChatRoomView(
                        requestId: '',
                        customerId: artisanId,
                        customerName: displayName,
                        isDirect: true,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const ArtisanSectionTitle(title: 'الخدمات'),
                const SizedBox(height: 8),
                ArtisanServicesChips(
                  services: servicesList,
                  borderColor: border,
                ),
                const SizedBox(height: 16),
                if (pricingRows.isNotEmpty) ...[
                  const ArtisanSectionTitle(title: 'الأسعار'),
                  const SizedBox(height: 8),
                  ArtisanPricingCard(
                    rows: pricingRows,
                    borderColor: border,
                  ),
                  const SizedBox(height: 16),
                ],

                const ArtisanSectionTitle(title: 'النبذة'),
                const SizedBox(height: 8),
                ArtisanBioCard(
                  bio: bio,
                  borderColor: border,
                ),

                const SizedBox(height: 16),

                const ArtisanSectionTitle(title: 'الأعمال'),
                const SizedBox(height: 10),
                ArtisanGallerySection(
                  imageUrls: imageUrls,
                  borderColor: border,
                  onOpen: (index) => _openGallery(imageUrls, index),
                ),

                const SizedBox(height: 22),

                ArtisanBottomButtons(
                  primaryColor: primaryBlue,
                  onRequest: () {
                    final servicesList = _extractServicesList(artisan);
                    Get.to(
                      () => CustomerCreateRequestView(
                        presetArtisanId: artisanId,
                        presetArtisanName: displayName,
                        presetService: firstServiceName,
                        presetServices: servicesList,
                      ),
                    );
                  },
                  onShowMap: () {
                    if (coords == null) {
                      AppSnackBar.show(
                        'تنبيه'.tr,
                        'لم يتم العثور على موقع الحرفي'.tr,
                      );
                      return;
                    }
                    Get.to(
                      () => CustomerLiveMapView(
                        focusLat: coords.latitude,
                        focusLng: coords.longitude,
                        focusTitle: displayName,
                        focusSnippet:
                            firstServiceName.isNotEmpty ? firstServiceName : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }


  void _openGallery(List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) {
        final pageCtrl = PageController(initialPage: initialIndex);
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              PageView.builder(
                controller: pageCtrl,
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: CachedNetworkImage(
                        imageUrl: urls[index],
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white38,
                          size: 80,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _imageUrls(dynamic photos) {
    final List<String> urls = [];

    void addAny(dynamic p) {
      if (p == null) return;
      String? raw;
      if (p is Map && p['path'] is String) raw = p['path'] as String;
      if (p is Map && p['url'] is String) raw = p['url'] as String;
      if (p is String) raw = p;
      if (raw != null && raw.trim().isNotEmpty) {
        urls.add(_fullUrl(raw.trim()));
      }
    }
    if (photos is List) {
      for (final p in photos) {
        addAny(p);
      }
    }
    final detail = explore.artisanDetail.value;
    if (detail != null && detail['portfolio'] is List) {
      for (final p in (detail['portfolio'] as List)) {
        addAny(p);
      }
    }
    if (urls.isEmpty && detail != null && detail['photo'] is String) {
      final p = detail['photo'] as String;
      if (p.isNotEmpty) addAny(p);
    }

    return urls.toSet().toList();
  }

  List<String> _extractServicesNames(dynamic services) {
    final list = <String>[];
    if (services is List) {
      for (final s in services) {
        if (s is Map) {
          final n = s['name']?.toString();
          if (n != null && n.trim().isNotEmpty) list.add(n.trim());
        } else {
          final n = s.toString();
          if (n.trim().isNotEmpty) list.add(n.trim());
        }
      }
    }
    return list;
  }

  List<Map<String, String>> _pricingRows(dynamic pricing) {
    if (pricing is! List) return [];
    return pricing
        .whereType<Map>()
        .map(
          (p) => {
            'name': p['serviceName']?.toString() ?? 'خدمة'.tr,
            'min': p['min']?.toString() ?? '',
            'max': p['max']?.toString() ?? '',
            'currency': p['currency']?.toString() ?? '',
          },
        )
        .toList();
  }
  String _fullUrl(String path) {
    if (path.startsWith('http')) return path;
    final origin = AppConfig.instance.origin;
    if (path.startsWith('/')) return '$origin$path';
    return '$origin/$path';
  }
  String? _firstPhoto(Map<String, dynamic> artisan, dynamic photos) {
    final direct =
        artisan['photo'] ??
        artisan['photoUrl'] ??
        artisan['avatar'] ??
        artisan['profilePhoto'] ??
        artisan['image'];
    if (direct is String && direct.isNotEmpty) return _fullUrl(direct);
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is String && first.isNotEmpty) return _fullUrl(first);
      if (first is Map && first['path'] is String)
        return _fullUrl(first['path']);
      if (first is Map && first['url'] is String) return _fullUrl(first['url']);
    }

    return null;
  }

  double? _ratingValue(Map<String, dynamic> artisan) {
    final rating =
        artisan['rating'] ?? artisan['avgRating'] ?? artisan['average'];
    if (rating is num) return rating.toDouble();
    if (rating is Map && rating['average'] is num) {
      return (rating['average'] as num).toDouble();
    }
    if (rating is String) return double.tryParse(rating);
    return null;
  }

  LatLng? _extractCoords(Map<String, dynamic> artisan) {
    try {
      if (artisan['lat'] is num && artisan['lng'] is num) {
        return LatLng(
          (artisan['lat'] as num).toDouble(),
          (artisan['lng'] as num).toDouble(),
        );
      }
      if (artisan['location'] is Map &&
          (artisan['location']['coordinates'] is List) &&
          (artisan['location']['coordinates'] as List).length >= 2) {
        final coords = artisan['location']['coordinates'];
        if (coords[0] is num && coords[1] is num) {
          return LatLng(
            (coords[1] as num).toDouble(),
            (coords[0] as num).toDouble(),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  List<String> _extractServicesList(Map<String, dynamic> artisan) {
    final s = artisan['services'];
    if (s is! List) return [];
    return s
        .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  String _extractFirstServiceName(Map<String, dynamic> artisan) {
    final s = artisan['services'];
    if (s is List && s.isNotEmpty) {
      final first = s.first;
      if (first is Map) {
        final n = first['name']?.toString();
        if (n != null && n.trim().isNotEmpty) return n.trim();
      }
      final n = first.toString();
      if (n.trim().isNotEmpty) return n.trim();
    }
    final profession = artisan['profession']?.toString();
    if (profession != null && profession.trim().isNotEmpty)
      return profession.trim();
    return '';
  }
}


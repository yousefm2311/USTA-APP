import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/customer_artisan_details_view.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';

class NearbyMapSection extends StatelessWidget {
  final CustomerExploreController explore;
  final LatLng defaultCenter;
  final VoidCallback onOpenLiveMap;

  const NearbyMapSection({
    super.key,
    required this.explore,
    required this.defaultCenter,
    required this.onOpenLiveMap,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border(context);
    return Obx(() {
      if (explore.loadingNearby.value) {
        return ShimmerSkeletons.mapPlaceholder(height: 175);
      }

      final items = explore.nearby;
      if (items.isEmpty) {
        return AppCard(
          radius: 16,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 175,
              child: Center(
                child: Text(
                  'لا يوجد حرفيين قريبين حالياً'.tr,
                  style: AppText.body.copyWith(),
                ),
              ),
            ),
          );
      }

      final markers = explore.nearbyMarkers(
        onTap: (art) {
          final id = (art['_id'] ?? art['id'])?.toString() ?? '';
          if (id.isNotEmpty) {
            Get.to(
              () => CustomerArtisanDetailsView(
                artisanId: id,
                artisan: art,
              ),
            );
          }
        },
      );
      final initial = explore.firstNearbyPosition() ?? defaultCenter;

      return Container(
        height: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            RepaintBoundary(
              child: GoogleMap(
                key: const ValueKey('home-google-map'),
                initialCameraPosition: CameraPosition(
                  target: initial,
                  zoom: 11.5,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onTap: (_) => onOpenLiveMap(),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: InkWell(
                onTap: onOpenLiveMap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.open_in_full,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "توسيع الخريطة".tr,
                        style: const TextStyle(
                          fontFamily: AppText.font,
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}


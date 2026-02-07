import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:usta/Customer/features/customer/customer_live_map_view.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_explore_filters_view.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_explore_view.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';
import 'package:usta/Customer/features/customer/home/widgets/categories_section.dart';
import 'package:usta/Customer/features/customer/home/widgets/create_request_cta.dart';
import 'package:usta/Customer/features/customer/home/widgets/home_header.dart';
import 'package:usta/Customer/features/customer/home/widgets/nearby_artisans_section.dart';
import 'package:usta/Customer/features/customer/home/widgets/nearby_map_section.dart';
import 'package:usta/Customer/features/customer/home/widgets/promo_banner.dart';
import 'package:usta/Customer/features/customer/home/widgets/recent_activity_section.dart';
import 'package:usta/Customer/features/customer/home/widgets/search_field.dart';
import 'package:usta/Customer/features/customer/home/widgets/section_header.dart';
import 'package:usta/Customer/features/customer/home/widgets/status_card.dart';
import 'package:usta/Customer/features/customer/home/widgets/top_rated_section.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/views/customer_create_request_view.dart';

class CustomerHomeView extends StatefulWidget {
  const CustomerHomeView({super.key});

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<CustomerHomeView> {
  late final CustomerExploreController explore;
  late final CustomerRequestsController requestsCtrl;

  static const LatLng _defaultCenter = LatLng(24.7136, 46.6753);

  @override
  void initState() {
    super.initState();
    explore = Get.find<CustomerExploreController>();
    requestsCtrl = Get.find<CustomerRequestsController>();
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, double>? _firstNearbyCoords() {
    if (explore.nearby.isEmpty) return null;

    final art = explore.nearby.first;
    final coords = explore.coordsOf(art);
    if (coords == null) return null;

    final lat = _toDouble(coords['lat']);
    final lng = _toDouble(coords['lng']);

    if (lat == null || lng == null) return null;
    return {'lat': lat, 'lng': lng};
  }

  void _openLiveMap() {
    final coords = _firstNearbyCoords();
    Get.to(
      () => CustomerLiveMapView(
        initialLat: coords?['lat'],
        initialLng: coords?['lng'],
        initialRadiusKm: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final cardColor = _homeCardColor(context);
    final cardBorder = _homeCardBorder(context);
    final heroGradient = LinearGradient(
      colors: [
        cardColor,
        Color.lerp(cardColor, scheme.primary, isDark ? 0.12 : 0.08)!,
        cardColor,
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    final heroShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? .25 : .08),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  cardColor.withOpacity(isDark ? 0.15 : 0.35),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () async {
                await Future.wait([
                  explore.fetchTopRated(force: true),
                  explore.fetchNearby(force: true),
                  requestsCtrl.fetchHistoryRequests(force: true),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: heroGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: heroShadow,
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        const HomeHeader(),
                        const SizedBox(height: 12),
                        SearchField(
                          onTap: () => Get.to(() => const CustomerExploreView()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _HeroActionButton(
                                label: "إنشاء طلب جديد".tr,
                                icon: Icons.add_circle_outline,
                                filled: true,
                                onTap: () => Get.to(
                                  () => const CustomerCreateRequestView(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeroActionButton(
                                label: "الخريطة الحية".tr,
                                icon: Icons.map_outlined,
                                filled: false,
                                onTap: _openLiveMap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const StatusCard(),
                  const SizedBox(height: 14),
                  const PromoBanner(),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: CategoriesSection(explore: explore),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: "الخريطة الحية للحرفيين".tr,
                          onTap: _openLiveMap,
                          trailing: HeaderActionPill(
                            text: "فتح".tr,
                            icon: Icons.map_outlined,
                            onTap: _openLiveMap,
                          ),
                        ),
                        const SizedBox(height: 12),
                        NearbyMapSection(
                          explore: explore,
                          defaultCenter: _defaultCenter,
                          onOpenLiveMap: _openLiveMap,
                        ),
                        const SizedBox(height: 12),
                        NearbyArtisansSection(explore: explore),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SectionHeader(
                                title: "الأعلى تقييماً".tr,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Get.to(() => const CustomerExploreFiltersView()),
                              icon: const Icon(
                                Icons.filter_list,
                                size: 20,
                              ),
                              tooltip: "فلترة".tr,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TopRatedSection(explore: explore),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: RecentActivitySection(requestsCtrl: requestsCtrl),
                  ),
                  const SizedBox(height: 4),
                  CreateRequestCTA(
                    onTap: () =>
                        Get.to(() => const CustomerCreateRequestView()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(

      decoration: BoxDecoration(
        // color: _homeCardColor(context),
        borderRadius: BorderRadius.circular(20),
        // border: Border.all(color: _homeCardBorder(context)),
      ),
      child: child,
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = filled ? AppColors.primaryBlue : _homeCardColor(context);
    final fg = filled ? Colors.white : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? Colors.transparent : _homeCardBorder(context),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppText.font,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _homeCardColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  final base = scheme.surface;
  return Color.alphaBlend(
    Colors.white.withOpacity(isDark ? 0.009 : 0.85),
    base,
  );
}

Color _homeCardBorder(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = scheme.brightness == Brightness.dark;
  return scheme.outlineVariant.withOpacity(isDark ? 0.35 : 0.25);
}


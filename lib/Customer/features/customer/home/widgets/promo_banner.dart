import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';
import 'package:usta/Customer/features/customer/customer_live_map_view.dart';
import 'package:usta/Customer/features/customer/dashboard/views/customer_dashboard_view.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_explore_view.dart';
import 'package:usta/Customer/features/customer/favorites/views/customer_favorites_view.dart';
import 'package:usta/Customer/features/customer/favorites/views/customer_history_view.dart';
import 'package:usta/Customer/features/customer/home/controllers/customer_banners_controller.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_ai_feedback_view.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_coupons_view.dart';
import 'package:usta/Customer/features/customer/marketing/views/customer_rewards_view.dart';
import 'package:usta/Customer/features/customer/notifications/views/customer_notifications_view.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/views/customer_create_request_view.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_wallet_view.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key, this.category});

  final String? category;

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  late final CustomerBannersController _controller;
  late final PageController _pageController;
  Timer? _timer;
  Worker? _worker;
  int _page = 0;
  int _count = 0;
  String _lastCategory = '';

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CustomerBannersController>();
    _pageController = PageController();
    _setupWorker();
    _fetchForCategory(widget.category);
    _onBannersChanged();
  }

  @override
  void didUpdateWidget(covariant PromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _fetchForCategory(widget.category);
    }
  }

  void _fetchForCategory(String? category) {
    final cat = category?.trim() ?? '';
    if (cat.isEmpty || cat == _lastCategory) return;
    _lastCategory = cat;
    _controller.fetchBanners(category: cat);
  }

  void _setupWorker() {
    _worker = ever(_controller.banners, (_) => _onBannersChanged());
  }

  void _onBannersChanged() {
    final count = _controller.banners.length;
    if (count == _count) return;
    _count = count;
    _page = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients || _count <= 1) return;
      _page = (_page + 1) % _count;
      _pageController.animateToPage(
        _page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _worker?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category == null || widget.category!.trim().isEmpty) {
      _lastCategory = '';
    }

    return Obx(() {
      final items = _controller.banners;
      if (items.isEmpty) {
        return const _FallbackBanner();
      }

      if (_page >= items.length) {
        _page = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      }

      if (items.length == 1) {
        final single = items.first;
        return _BannerCard(
          banner: single,
          onTap: () => _handleAction(single),
        );
      }

      return SizedBox(
        height: 100,
        child: PageView.builder(
          controller: _pageController,
          itemCount: items.length,
          onPageChanged: (index) => _page = index,
          itemBuilder: (context, index) {
            final banner = items[index];
            return _BannerCard(
              banner: banner,
              onTap: () => _handleAction(banner),
            );
          },
        ),
      );
    });
  }

  Future<void> _handleAction(Map<String, dynamic> banner) async {
    final type =
        (banner['actionType'] ?? banner['action_type'] ?? '')
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('-', '_');
    final value =
        (banner['actionValue'] ?? banner['action_value'] ?? '')
            .toString()
            .trim();

    if (type.isEmpty || type == 'none') return;

    switch (type) {
      case 'open_url':
        await _openUrl(value);
        break;
      case 'open_screen':
        _openScreen(value);
        break;
      case 'apply_coupon':
        await _applyCoupon(value);
        break;
      default:
        break;
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) {
      AppSnackBar.show('تنبيه'.tr, 'الرابط غير متاح حالياً'.tr);
      return;
    }
    Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      uri = Uri.tryParse('https://$url');
    }
    if (uri == null) {
      AppSnackBar.show('خطأ'.tr, 'الرابط غير صالح'.tr);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      AppSnackBar.show('خطأ'.tr, 'تعذر فتح الرابط'.tr);
    }
  }

  void _openScreen(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return;

    if (raw.startsWith('/')) {
      Get.toNamed(raw);
      return;
    }

    final key = raw.toLowerCase();
    final widget = _screenForKey(key);
    if (widget != null) {
      Get.to(() => widget);
      return;
    }

    final route = _routeForKey(key);
    if (route != null) {
      Get.toNamed(route);
      return;
    }

    AppSnackBar.show('تنبيه'.tr, 'الشاشة غير متاحة حالياً'.tr);
  }

  Widget? _screenForKey(String key) {
    switch (key) {
      case 'notifications':
      case 'notification':
      case 'notif':
      case 'الاشعارات':
      case 'الإشعارات':
        return const CustomerNotificationsView();
      case 'coupons':
      case 'coupon':
      case 'الكوبونات':
        return const CustomerCouponsView();
      case 'wallet':
      case 'المحفظة':
        return  CustomerWalletView();
      case 'rewards':
      case 'المكافآت':
        return const CustomerRewardsView();
      case 'favorites':
      case 'favourites':
      case 'المفضلة':
        return  CustomerFavoritesView();
      case 'history':
      case 'الطلبات':
      case 'السجل':
        return const CustomerHistoryView();
      case 'explore':
      case 'استكشاف':
        return const CustomerExploreView();
      case 'dashboard':
      case 'لوحة التحكم':
        return const CustomerDashboardView();
      case 'create_request':
      case 'new_request':
      case 'انشاء_طلب':
      case 'إنشاء_طلب':
        return const CustomerCreateRequestView();
      case 'ai_feedback':
      case 'اقتراحات':
      case 'ai':
        return const CustomerAIFeedbackView();
      case 'live_map':
      case 'map':
      case 'الخريطة':
        return const CustomerLiveMapView();
      default:
        return null;
    }
  }

  String? _routeForKey(String key) {
    switch (key) {
      case 'home':
      case 'customerhomeview':
      case 'customer_bottom_navibar':
      case 'customerbottomnavibar':
        return AppRoutes.customerBottomNaviBar;
      case 'login':
        return AppRoutes.login;
      default:
        return null;
    }
  }

  Future<void> _applyCoupon(String code) async {
    final value = code.trim();
    if (value.isEmpty) {
      AppSnackBar.show('تنبيه'.tr, 'كود الكوبون غير متاح'.tr);
      return;
    }
    final marketing = Get.find<CustomerMarketingController>();
    try {
      await marketing.applyCoupon(value);
      AppSnackBar.show('تم'.tr, 'تم تطبيق الكوبون بنجاح'.tr);
    } catch (e) {
      AppSnackBar.show('خطأ'.tr, _friendlyCouponError(e));
    }
  }

  String _friendlyCouponError(Object e) {
    const fallback = 'تعذر تطبيق الكوبون حالياً. حاول مرة أخرى.';
    if (e is ApiException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('expired')) {
        return 'عذراً، هذا الكوبون منتهي الصلاحية.'.tr;
      }
      if (msg.contains('invalid') ||
          msg.contains('not found') ||
          e.statusCode == 404) {
        return 'الكوبون غير صالح أو غير صحيح.'.tr;
      }
      if (msg.contains('used') || msg.contains('already')) {
        return 'تم استخدام الكوبون من قبل.'.tr;
      }
      if (e.message.isNotEmpty) return e.message;
    }
    final raw = e.toString().toLowerCase();
    if (raw.contains('expired')) {
      return 'عذراً، هذا الكوبون منتهي الصلاحية.'.tr;
    }
    if (raw.contains('invalid') || raw.contains('not found')) {
      return 'الكوبون غير صالح أو غير صحيح.'.tr;
    }
    if (raw.contains('socketexception') || raw.contains('network')) {
      return 'تحقق من اتصال الإنترنت وحاول مرة أخرى.'.tr;
    }
    return fallback.tr;
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    this.onTap,
  });

  final Map<String, dynamic> banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = _resolveGradient(banner);
    final title = _stringOf(banner['title']) ?? 'عرض خاص'.tr;
    final subtitle = _stringOf(banner['subtitle']) ?? '';
    final imageUrl = _stringOf(banner['image']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppText.font,
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: AppText.font,
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _BannerImage(url: imageUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    if (value.isEmpty) {
      return const Icon(Icons.discount, color: Colors.white, size: 32);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        value,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.discount, color: Colors.white, size: 32),
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner();

  @override
  Widget build(BuildContext context) {
    return _BannerCard(
      banner: {
        'title': 'خصم 20% على أول طلب\nمع كود الخصم أدناه'.tr,
        'subtitle': 'كود الخصم: FIRST20'.tr,
        'image': '',
        'gradientColors': ['#2563EB', '#111827'],
      },
    );
  }
}

List<Color> _resolveGradient(Map<String, dynamic> banner) {
  final raw = banner['gradientColors'] ?? banner['gradient_colors'];
  final colors = _parseGradientColors(raw);
  if (colors.isNotEmpty) {
    return colors.length == 1 ? [colors.first, colors.first] : colors;
  }
  return const [AppColors.primaryBlue, Color(0xFF111827)];
}

List<Color> _parseGradientColors(dynamic raw) {
  if (raw is List) {
    final colors = <Color>[];
    for (final item in raw) {
      final color = _parseColor(item);
      if (color != null) colors.add(color);
    }
    return colors;
  }
  return const <Color>[];
}

Color? _parseColor(dynamic value) {
  if (value is int) return Color(value);
  if (value is String) {
    final cleaned = value.trim().replaceAll('#', '').replaceAll('0x', '');
    if (cleaned.isEmpty) return null;
    try {
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

String? _stringOf(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}



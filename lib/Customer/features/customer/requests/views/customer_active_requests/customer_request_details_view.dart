import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/customer_artisan_details_view.dart';
import 'package:usta/Customer/features/customer/price_request/views/customer_request_price_confirm_view.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_write_review_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_actions_section.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_address_info_card.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_attachments_list.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_artisan_card.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_details_header.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_route_button.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_section_card.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_section_title.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_service_info_card.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_timeline_section.dart';
import 'package:usta/Customer/features/customer/requests/views/request_route_map_view.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';

class CustomerRequestDetailsView extends StatefulWidget {
  const CustomerRequestDetailsView({super.key, required this.requestId});
  final String requestId;

  @override
  State<CustomerRequestDetailsView> createState() =>
      _CustomerRequestDetailsViewState();
}

class _CustomerRequestDetailsViewState
    extends State<CustomerRequestDetailsView> {
  late final CustomerRequestsController controller;

  Color get darkBg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);
  Color get green => const Color(0xFF22C55E);
  Color get red => const Color(0xFFE11D48);

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomerRequestsController>();
    _load();
  }

  Future<void> _load() async {
    controller.requestDetails.value = null;
    controller.timeline.clear();
    try {
      await controller.fetchRequestDetails(widget.requestId);
      await controller.fetchTimeline(widget.requestId);
    } on ApiException catch (e) {
      _handleApiException(e);
    } catch (_) {
      AppSnackBar.show('خطأ'.tr, 'حدث خطأ غير متوقع'.tr);
    }
  }

  void _handleApiException(ApiException e) {
    final message = e.message.isNotEmpty
        ? e.message
        : 'تعذّر تحميل بيانات الطلب'.tr;
    AppSnackBar.show('خطأ'.tr, message);
    if ((e.statusCode == 401 || e.statusCode == 403) &&
        Get.isRegistered<AuthController>(tag: 'customer')) {
      Get.find<AuthController>(tag: 'customer').logout(remote: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: scheme.surface,
          title: Text(
            'تفاصيل الطلب'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        body: Obx(() {
          final details = controller.requestDetails.value;
          final detailsId =
              (details?['_id'] ?? details?['id'])?.toString() ?? '';

          if (controller.loadingDetails.value ||
              details == null ||
              detailsId != widget.requestId) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ShimmerSkeletons.listTile(height: 90),
                const SizedBox(height: 12),
                ShimmerSkeletons.mapPlaceholder(height: 160),
                const SizedBox(height: 16),
                ShimmerSkeletons.listTile(height: 80),
                const SizedBox(height: 12),
                ShimmerSkeletons.listTile(height: 80),
                const SizedBox(height: 16),
                _timelineShimmer(),
              ],
            );
          }

          final map = Map<String, dynamic>.from(details);
          final status = (map['status'] ?? '').toString();
          final updatedAt = map['updatedAt'];
          final attachmentsRaw = map['images'] ?? map['attachments'] ?? [];
          final attachments = (attachmentsRaw is List)
              ? attachmentsRaw
              : <dynamic>[];

          final attachmentUrls = attachments
              .map((e) => _resolveUrl(e?.toString() ?? ''))
              .where((u) => u.trim().isNotEmpty)
              .toList();

          final service =
              map['serviceType'] ?? map['service'] ?? 'غير متاح'.tr;
          final price = map['price'];
          final desc = (map['description'] ?? '').toString();
          final reqId = (map['_id'] ?? map['id'] ?? '').toString();
          final address = map['address'] ?? 'عنوان غير متاح'.tr;
          final lat =
              _toDouble(map['lat']) ?? _toDouble(map['location']?['coordinates']?[1]);
          final lng =
              _toDouble(map['lng']) ?? _toDouble(map['location']?['coordinates']?[0]);

          final artisanRaw = map['artisan'];
          final artisanId = _artisanIdFrom(map);

          final s = status.toLowerCase();
          final canCancel = s == 'new' || s == 'accepted' || s == 'in_progress';
          final canConfirm = s == 'awaiting_confirmation';
          final canPriceConfirm =
              s == 'priced' || s == 'awaiting_customer_price_confirm';
          final isClosed =
              s == 'completed' ||
              s == 'cancelled' ||
              s == 'rejected' ||
              s == 'closed';
          final timelineReady =
              controller.timelineRequestId.value == widget.requestId;
          final timelineLoading =
              controller.loadingTimeline.value || !timelineReady;

          Widget artisanSection;
          if (artisanRaw is! Map) {
            artisanSection = RequestSectionCard(
              child: Text(
                'لا توجد معلومات عن الحرفي'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          } else {
            final a = Map<String, dynamic>.from(artisanRaw);
            final name = (a['name'] ?? 'اسم غير متاح'.tr).toString();
            final profession =
                (a['profession'] ?? a['service'] ?? 'حرفة غير متاحة'.tr)
                    .toString();
            final rating = a['rating'] ?? a['avgRating'];
            final phone = a['phone']?.toString();
            final email = a['email']?.toString();
            final id =
                (artisanId.isNotEmpty ? artisanId : (a['_id'] ?? a['id'])?.toString() ?? '')
                    .trim();

            artisanSection = RequestArtisanCard(
              name: name,
              profession: profession,
              rating: rating,
              phone: phone,
              email: email,
              onTap: id.isEmpty
                  ? null
                  : () {
                      Get.to(
                        () => CustomerArtisanDetailsView(
                          artisanId: id,
                          artisan: a,
                        ),
                      );
                    },
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            color: scheme.primary,
            backgroundColor: scheme.surface,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RequestDetailsHeader(
                  statusLabel: _statusLabel(status),
                  statusColor: _statusColor(context, status),
                  updatedAtText: _formatDate(updatedAt),
                ),
                const SizedBox(height: 12),
                RequestRouteButton(onPressed: () => _openRoute(map)),
                const SizedBox(height: 18),
                const RequestSectionTitle(text: 'تفاصيل الخدمة'),
                RequestServiceInfoCard(
                  service: service.toString(),
                  price: price,
                  description: desc,
                  requestId: reqId,
                ),
                const SizedBox(height: 12),
                const RequestSectionTitle(text: 'العنوان'),
                RequestAddressInfoCard(
                  address: address.toString(),
                  lat: lat,
                  lng: lng,
                ),
                if (attachmentUrls.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const RequestSectionTitle(text: 'المرفقات'),
                  RequestAttachmentsList(
                    urls: attachmentUrls,
                    onOpenGallery: _openGallery,
                  ),
                ],
                const SizedBox(height: 18),
                const RequestSectionTitle(text: 'الحرفي'),
                artisanSection,
                const SizedBox(height: 18),
                const RequestSectionTitle(text: 'خط الزمن'),
                if (timelineLoading)
                  _timelineShimmer()
                else
                  RequestTimelineSection(
                    items: List<Map<String, dynamic>>.from(controller.timeline),
                    statusColor: (s) => _statusColor(context, s),
                    statusLabel: _statusLabel,
                    statusIcon: _statusIcon,
                    formatDate: _formatDate,
                  ),
                const SizedBox(height: 18),
                const RequestSectionTitle(text: 'الإجراءات'),
                RequestActionsSection(
                  canCancel: canCancel,
                  canConfirm: canConfirm,
                  canPriceConfirm: canPriceConfirm,
                  isClosed: isClosed,
                  confirmColor: green,
                  cancelColor: red,
                  onPriceConfirm: () => _openPriceConfirm(map),
                  onConfirmCompletion: () async {
                    final ok = await _confirmDialog(
                      title: 'تأكيد اكتمال الطلب'.tr,
                      message: 'هل أنت متأكد من تأكيد اكتمال الطلب؟'.tr,
                      confirmText: 'تأكيد'.tr,
                      confirmColor: green,
                    );
                    if (!ok) return;
                    await controller.confirmCompletion(widget.requestId);
                    if (mounted) Get.back();
                  },
                  onCancel: () async {
                    final ok = await _confirmDialog(
                      title: 'إلغاء الطلب'.tr,
                      message: 'هل أنت متأكد من إلغاء الطلب؟'.tr,
                      confirmText: 'إلغاء الطلب'.tr,
                      confirmColor: red,
                    );
                    if (!ok) return;
                    await controller.cancelRequest(widget.requestId);
                    if (mounted) Get.back();
                  },
                  onWriteReview: () {
                    if (artisanId.isEmpty) {
                      AppSnackBar.show('تنبيه'.tr, 'تعذر تحديد الحرفي'.tr);
                      return;
                    }
                    Get.to(() => CustomerWriteReviewView(artisanId: artisanId));
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }),
      ),
    );
  }

  Color _borderColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.outlineVariant.withOpacity(0.55);
  }

  Widget _timelineShimmer() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ShimmerSkeletons.timelineItem(context),
          ),
        ),
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
          backgroundColor: Colors.transparent,
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
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 80),
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

  Future<void> _openPriceConfirm(Map<String, dynamic> details) async {
    final price = _extractProposedPrice(details);
    if (price == null || price <= 0) {
      AppSnackBar.show('تنبيه'.tr, 'السعر غير متاح'.tr);
      return;
    }

    await Get.to(
      () => CustomerRequestPriceConfirmView(
        price: price,
        requestId: widget.requestId,
        onAccept: ({
          required double price,
          required String notes,
          String? requestId,
        }) async {
          await controller.decidePrice(
            id: requestId ?? widget.requestId,
            action: 'accept',
            notes: notes,
            price: price,
          );
          await _load();
        },
        onReject: ({
          required double price,
          required String notes,
          String? requestId,
        }) async {
          await controller.decidePrice(
            id: requestId ?? widget.requestId,
            action: 'reject',
            notes: notes,
            price: price,
          );
          await _load();
        },
      ),
    );
  }

  double? _extractProposedPrice(Map<String, dynamic> details) {
    final pricing = details['pricing'];
    if (pricing is Map && pricing['proposedPrice'] != null) {
      return _toDouble(pricing['proposedPrice']);
    }
    final price = details['price'] ?? details['agreedPrice'];
    return _toDouble(price);
  }

  double? _extractPaymentAmount(Map<String, dynamic> details) {
    final payment = details['payment'];
    if (payment is Map && payment['amount'] != null) {
      return _toDouble(payment['amount']);
    }
    final pricing = details['pricing'];
    if (pricing is Map && pricing['proposedPrice'] != null) {
      return _toDouble(pricing['proposedPrice']);
    }
    return _toDouble(details['price'] ?? details['agreedPrice']);
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final scheme = Theme.of(context).colorScheme;

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(fontFamily: 'Cairo', color: scheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'رجوع'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'assigned':
        return Icons.assignment_ind_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'on_the_way':
        return Icons.directions_run_rounded;
      case 'arrived':
        return Icons.location_on_rounded;
      case 'awaiting_customer_price_confirm':
        return Icons.price_check_rounded;
      case 'price_accepted':
        return Icons.thumb_up_alt_rounded;
      case 'price_rejected':
        return Icons.thumb_down_alt_rounded;
      case 'work_started':
        return Icons.build_circle_rounded;
      case 'in_progress':
        return Icons.autorenew_rounded;
      case 'awaiting_confirmation':
        return Icons.hourglass_bottom_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.block_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _normStatus(String s) => s.trim().toLowerCase().replaceAll('-', '_');

  Color _statusColor(BuildContext context, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _normStatus(status);

    MaterialColor base;
    switch (s) {
      case 'new':
        base = Colors.blue;
        break;
      case 'assigned':
      case 'accepted':
        base = Colors.green;
        break;
      case 'on_the_way':
        base = Colors.indigo;
        break;
      case 'arrived':
        base = Colors.cyan;
        break;
      case 'awaiting_customer_price_confirm':
      case 'awaiting_confirmation':
        base = Colors.amber;
        break;
      case 'price_accepted':
        base = Colors.teal;
        break;
      case 'price_rejected':
        base = Colors.red;
        break;
      case 'work_started':
        base = Colors.orange;
        break;
      case 'in_progress':
        base = Colors.deepOrange;
        break;
      case 'completed':
        base = Colors.teal;
        break;
      case 'rejected':
      case 'cancelled':
        base = Colors.red;
        break;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.75);
    }

    return isDark ? base.shade700 : base.shade700;
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'طلب جديد'.tr;
      case 'assigned':
        return 'تم التعيين'.tr;
      case 'accepted':
        return 'مقبول'.tr;
      case 'on_the_way':
        return 'في الطريق'.tr;
      case 'awaiting_customer_price_confirm':
        return 'في انتظار تأكيد السعر من العميل'.tr;
      case 'price_accepted':
        return 'تم قبول السعر'.tr;
      case 'price_rejected':
        return 'تم رفض السعر'.tr;
      case 'arrived':
        return 'وصل'.tr;
      case 'work_started':
        return 'تم بدء العمل'.tr;
      case 'in_progress':
        return 'قيد التنفيذ'.tr;
      case 'completed':
        return 'مكتمل'.tr;
      case 'awaiting_confirmation':
        return 'بانتظار التأكيد'.tr;
      case 'rejected':
        return 'مرفوض'.tr;
      case 'cancelled':
        return 'ملغي'.tr;
      default:
        return status.isEmpty ? 'غير معروف'.tr : status;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year  $hour:$minute';
    } catch (_) {
      return value.toString();
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _resolveUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '${AppConfig.instance.origin}$raw';
    return raw;
  }

  Future<void> _openRoute(Map<String, dynamic> details) async {
    final userPosition = _extractLatLngDynamic(
      details['location'],
      fallbackLat: details['lat'],
      fallbackLng: details['lng'],
    );

    final artisanRaw =
        details['artisan'] ?? details['artisanId'] ?? details['artisan_id'];
    final artisanId = _artisanIdFrom(details);

    LatLng? artisanPosition;
    Map<String, dynamic>? artisanLocation;
    dynamic artisanLocationRaw;
    Map<String, dynamic>? artisanMap =
        artisanRaw is Map ? Map<String, dynamic>.from(artisanRaw) : null;

    if (artisanMap != null) {
      artisanLocationRaw =
          artisanMap['location'] ??
          artisanMap['currentLocation'] ??
          artisanMap['lastLocation'];
      artisanLocation = _asMap(artisanLocationRaw);
      artisanPosition = _extractLatLngDynamic(
        artisanLocationRaw,
        fallbackLat:
            artisanMap['lat'] ??
            artisanMap['latitude'] ??
            details['artisanLat'] ??
            details['artisan_lat'],
        fallbackLng:
            artisanMap['lng'] ??
            artisanMap['longitude'] ??
            details['artisanLng'] ??
            details['artisan_lng'],
      );
    }

    artisanPosition ??= _extractLatLngDynamic(
      details['artisanLocation'] ?? details['artisan_location'],
      fallbackLat: details['artisanLat'] ?? details['artisan_lat'],
      fallbackLng: details['artisanLng'] ?? details['artisan_lng'],
    );

    if (artisanPosition == null && artisanId.isNotEmpty) {
      final fetched = await _fetchArtisanDetails(artisanId);
      if (fetched != null) {
        artisanMap = fetched;
        artisanLocationRaw =
            fetched['location'] ??
            fetched['currentLocation'] ??
            fetched['lastLocation'];
        artisanLocation = _asMap(artisanLocationRaw) ?? artisanLocation;
        artisanPosition = _extractLatLngDynamic(
          artisanLocationRaw,
          fallbackLat: fetched['lat'] ?? fetched['latitude'],
          fallbackLng: fetched['lng'] ?? fetched['longitude'],
        );
      }
    }

    if (artisanPosition == null) {
      AppSnackBar.show('تنبيه'.tr, 'لا يمكن تحديد موقع الحرفي حالياً'.tr);
      return;
    }

    final artisanName =
        artisanMap?['name'] ??
        'حرفي'.tr;
    final artisanProfession = artisanMap?['profession'];

    Get.to(
      () => RequestRouteMapView(
        userLat: userPosition?.latitude,
        userLng: userPosition?.longitude,
        artisanLat: artisanPosition!.latitude,
        artisanLng: artisanPosition.longitude,
        artisanName: artisanName.toString(),
        artisanProfession: artisanProfession?.toString(),
        artisanLocation: artisanLocation ??
            _asMap(details['artisanLocation'] ?? details['artisan_location']),
      ),
    );
  }

  LatLng? _extractLatLngDynamic(
    dynamic value, {
    dynamic fallbackLat,
    dynamic fallbackLng,
  }) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final lat = _toDouble(map['lat'] ?? map['latitude']);
      final lng = _toDouble(map['lng'] ?? map['longitude']);
      if (lat != null && lng != null) return LatLng(lat, lng);

      final coords = map['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lat2 = _toDouble(coords[1]);
        final lng2 = _toDouble(coords[0]);
        if (lat2 != null && lng2 != null) return LatLng(lat2, lng2);
      }
    }

    if (value is List && value.length >= 2) {
      final a = _toDouble(value[0]);
      final b = _toDouble(value[1]);
      if (a != null && b != null) return LatLng(b, a);
    }

    final lat = _toDouble(fallbackLat);
    final lng = _toDouble(fallbackLng);
    if (lat != null && lng != null) return LatLng(lat, lng);

    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<Map<String, dynamic>?> _fetchArtisanDetails(String artisanId) async {
    if (artisanId.isEmpty || !Get.isRegistered<CustomerRepository>()) {
      return null;
    }
    try {
      final repo = Get.find<CustomerRepository>();
      final res = await repo.api.artisanDetails(artisanId);
      final data =
          res['artisan'] ??
          (res['data'] is Map ? (res['data'] as Map)['artisan'] : null) ??
          res['data'] ??
          res;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }

  String _artisanIdFrom(Map<String, dynamic> details) {
    final raw =
        details['artisan'] ?? details['artisanId'] ?? details['artisan_id'];
    if (raw is Map) {
      return (raw['_id'] ?? raw['id'] ?? raw['artisanId'])?.toString() ?? '';
    }
    return raw?.toString() ?? '';
  }
}




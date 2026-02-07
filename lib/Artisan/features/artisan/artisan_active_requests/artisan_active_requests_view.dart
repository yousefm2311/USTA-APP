// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanActiveRequestsView extends StatelessWidget {
  ArtisanActiveRequestsView({super.key});

  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();

  // Theme-ish colors (matching your dark style)
  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);

  final Map<String, String> _statusLabel = const {
    'assigned': 'تم تعيين الحرفي',
    'awaiting_customer_price_confirm': 'بانتظار موافقة العميل على السعر',
    'accepted': 'تم قبول الطلب',
    'priced': 'بانتظار موافقة العميل على السعر',
    'awaiting_payment': 'تمت موافقة السعر',
    'on_the_way': 'في الطريق',
    'price_rejected': 'تم رفض السعر من قبل العميل',
    'arrived': 'وصل',
    'work_started': 'بدأ العمل',
    'in_progress': 'جارٍ العمل',
    'working': 'جارٍ العمل',
    'awaiting_confirmation': 'بانتظار تأكيد العميل',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
    'rejected': 'مرفوض',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "الطلبات الحالية",
            style: AppTextStyles.body(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Obx(() {
          final loading = controller.loadingActive.value;
          final items = controller.activeRequests;

          if (loading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: controller.fetchActiveRequests,
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Icon(Icons.inbox_outlined, size: 54),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'لا توجد طلبات حالية',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'اسحب لتحديث القائمة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final request = items[index];
                      final id = (request['id'] ?? request['_id'] ?? '')
                          .toString();
                      final title = (request['code'] ?? '#${index + 1}')
                          .toString();
                      final service =
                          (request['serviceType'] ??
                                  (request['service'] is Map
                                      ? (request['service']['name'] ?? '')
                                      : '') ??
                                  'خدمة غير معروفة')
                              .toString();
                      final customer =
                          ((request['customer'] is Map
                                      ? request['customer']['name']
                                      : request['customerName']) ??
                                  'عميل غير معروف')
                              .toString();
                      final location = _formatLocation(
                        request['location'],
                        request['address'],
                      );
                      final rawStatus = _effectiveStatusFromRequest(request);
                      final statusText = _statusLabel[rawStatus] ?? rawStatus;
                      final progress = _progressFromStatus(rawStatus);
                      return _activeRequestCard(
                        context: context,
                        title: title,
                        service: service,
                        customer: customer,
                        location: location,
                        statusText: statusText,
                        rawStatus: rawStatus,
                        progress: progress,
                        onDetails: () async {
                          if (id.isEmpty) return;
                          await Get.toNamed(
                            AppRoutes.artisanRequestDetailsView,
                            arguments: {'requestId': id, 'request': request},
                          );
                          // Refresh after returning so status updates.
                          await controller.fetchActiveRequests();
                        },
                      );
                    },
                  ),
          );
        }),
      ),
    );
  }

  double _progressFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 0.15;
      case 'accepted':
        return 0.30;
      case 'awaiting_customer_price_confirm':
      case 'priced':
      case 'awaiting_payment':
        return 0.45;
      case 'on_the_way':
        return 0.60;
      case 'arrived':
        return 0.70;
      case 'work_started':
        return 0.78;
      case 'in_progress':
      case 'ongoing':
      case 'working':
        return 0.85;
      case 'awaiting_confirmation':
        return 0.92;
      case 'completed':
        return 1.0;
      case 'cancelled':
      case 'rejected':
        return 1.0;
      default:
        return 0.50;
    }
  }

  Color _chipColor(String status) {
    switch (status) {
      case 'assigned':
        return const Color(0xFF60A5FA);
      case 'accepted':
        return const Color(0xFF22C55E);
      case 'awaiting_customer_price_confirm':
      case 'priced':
      case 'awaiting_payment':
        return const Color(0xFFF59E0B);
      case 'on_the_way':
        return const Color(0xFF38BDF8);
      case 'arrived':
      case 'work_started':
      case 'in_progress':
      case 'working':
        return const Color(0xFF14B8A6);
      case 'awaiting_confirmation':
        return const Color(0xFFA78BFA);
      case 'completed':
        return const Color(0xFF22C55E);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _leadingIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'accepted':
        return Icons.verified_outlined;
      case 'awaiting_customer_price_confirm':
      case 'priced':
      case 'awaiting_payment':
        return Icons.price_change_outlined;
      case 'on_the_way':
        return Icons.directions_run_outlined;
      case 'arrived':
        return Icons.place_outlined;
      case 'work_started':
        return Icons.build_circle_outlined;
      case 'in_progress':
      case 'working':
        return Icons.handyman_outlined;
      case 'awaiting_confirmation':
        return Icons.hourglass_bottom_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _effectiveStatusFromRequest(Map<String, dynamic> request) {
    // 1) Ù„Ùˆ ÙÙŠÙ‡ timeline (Ø£ÙØ¶Ù„ Ù…ØµØ¯Ø±)
    final timeline = request['timeline'];
    if (timeline is List && timeline.isNotEmpty) {
      final items = timeline
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      items.sort((a, b) {
        final da = DateTime.tryParse((a['createdAt'] ?? '').toString());
        final db = DateTime.tryParse((b['createdAt'] ?? '').toString());
        if (da == null && db == null) return 0;
        if (da == null) return -1;
        if (db == null) return 1;
        return da.compareTo(db);
      });

      final lastStatus = (items.last['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (lastStatus.isNotEmpty) return lastStatus;
    }

    // 2) Ù„Ùˆ ÙÙŠÙ‡ timelineStatuses
    final statuses = request['timelineStatuses'];
    if (statuses is List && statuses.isNotEmpty) {
      final last = statuses.last.toString().trim().toLowerCase();
      if (last.isNotEmpty) return last;
    }

    // 3) fallback: status Ø§Ù„Ø¹Ø§Ø¯ÙŠ
    return (request['status'] ?? '').toString().trim().toLowerCase();
  }

  Widget _activeRequestCard({
    required BuildContext context,
    required String title,
    required String service,
    required String customer,
    required String location,
    required String statusText,
    required String rawStatus,
    required double progress,
    required VoidCallback onDetails,
  }) {
    final chip = _chipColor(rawStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: chip.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: chip.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: chip.withOpacity(0.25)),
                ),
                child: Icon(_leadingIcon(rawStatus), color: chip, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chip.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: chip.withOpacity(0.25)),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, customer, context),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, location,context),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white60,
              valueColor: AlwaysStoppedAnimation(primaryBlue),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                "عرض التفاصيل",
                style: TextStyle(
                  fontFamily: "Cairo",
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatLocation(dynamic location, dynamic address) {
    if (address is String && address.isNotEmpty) return address;
    if (location is String && location.isNotEmpty) return location;

    if (location is Map && location['coordinates'] is List) {
      final coords = (location['coordinates'] as List);
      if (coords.length >= 2) {
        final lat = coords[1];
        final lng = coords[0];
        if (lat != null && lng != null) return '$lat, $lng';
      }
    }
    return 'موقع غير متوفر';
  }
}


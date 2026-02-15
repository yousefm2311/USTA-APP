// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/core/utils/widgets/timeline_widget/animated_timeline_dot.dart';
import 'package:usta/Artisan/core/utils/widgets/timeline_widget/animated_timeline_line.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanRequestDetailsFromCompletedView extends StatefulWidget {
  const ArtisanRequestDetailsFromCompletedView({super.key});

  @override
  State<ArtisanRequestDetailsFromCompletedView> createState() =>
      _ArtisanRequestDetailsFromCompletedViewState();
}

class _ArtisanRequestDetailsFromCompletedViewState
    extends State<ArtisanRequestDetailsFromCompletedView> {
  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();

  // ===== Theme-ish colors (match your dark style) =====
  final Color bg = const Color(0xFF050816);
  final Color card = const Color(0xFF0B1020);
  final Color primaryBlue = const Color(0xFF2563EB);

  Map<String, dynamic> request = {};
  String requestId = '';
  bool loading = true;
  List<Map<String, dynamic>> timelineData = [];

  final Map<String, String> _statusLabel = const {
    'assigned': 'تم الإسناد',
    'accepted': 'تم القبول',
    'priced': 'تم تحديد السعر',
    'awaiting_customer_price_confirm': 'بانتظار موافقة العميل على السعر',
    'awaiting_payment': 'بانتظار الدفع',
    'price_accepted': 'تمت موافقة السعر',
    'price_rejected': 'تم رفض السعر',
    'payment_intent_created': 'تم إنشاء عملية الدفع',
    'on_the_way': 'في الطريق',
    'arrived': 'وصل',
    'work_started': 'بدأ العمل',
    'in_progress': 'جاري العمل',
    'working': 'جاري العمل',
    'awaiting_confirmation': 'بانتظار تأكيد العميل',
    'completed': 'تم الانتهاء',
    'cancelled': 'تم الإلغاء',
    'rejected': 'مرفوض',
    'closed': 'مغلق',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final args = Get.arguments is Map
        ? Get.arguments as Map
        : <String, dynamic>{};

    request =
        (args['request'] as Map?)?.cast<String, dynamic>() ??
        args.cast<String, dynamic>();
    requestId = (args['requestId'] ?? request['_id'] ?? request['id'] ?? '')
        .toString();

    if (requestId.isNotEmpty) {
      try {
        final details = await controller.fetchRequestDetails(requestId);
        if (details != null) {
          request =
              (details['request'] as Map?)?.cast<String, dynamic>() ?? details;
          _hydrateTimeline(details['timeline']);
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.show(
            AppStrings.error.tr,
            e.toString(),
            type: SnackBarType.error,
          );
        }
      }
    }

    if (mounted) setState(() => loading = false);
  }

  void _hydrateTimeline(dynamic list) {
    if (list is List) {
      timelineData = list
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      // ✅ sort by createdAt asc (so it looks like a real timeline)
      timelineData.sort((a, b) {
        final da = DateTime.tryParse((a['createdAt'] ?? '').toString());
        final db = DateTime.tryParse((b['createdAt'] ?? '').toString());
        if (da == null && db == null) return 0;
        if (da == null) return -1;
        if (db == null) return 1;
        return da.compareTo(db);
      });
    }
  }

  String get _effectiveStatus {
    final status = (request['status'] ?? '').toString().toLowerCase().trim();
    return status.isEmpty ? 'completed' : status;
  }

  @override
  Widget build(BuildContext context) {
    final service = _serviceText(request);
    final customer = _customerText(request);

    final customerMap = request['customer'] is Map
        ? (request['customer'] as Map).cast<String, dynamic>()
        : null;
    final phone =
        (customerMap?['phone'] ?? request['customerPhone'])?.toString() ?? '';

    final location = _formatLocation(request['location'], request['address']);
    final description = (request['description'] ?? '').toString().trim();

    final price =
        (request['agreedPrice'] ?? request['paidAmount'] ?? request['price'])
            ?.toString() ??
        '';

    final code = (request['code'] ?? request['_id'] ?? request['id'] ?? '')
        .toString();
    final createdAt = _formatDate(request['createdAt']);
    final updatedAt = _formatDate(request['updatedAt']);
    final statusText = _statusLabel[_effectiveStatus] ?? _effectiveStatus;
    final note = (request['note'] ?? '').toString().trim();
    final images = _imagesList(request['images']);

    final statusColor = _statusColor(_effectiveStatus);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تفاصيل الطلب المنتهي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Header Card =====
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.08),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.25),
                                  ),
                                ),
                                child: Icon(
                                  _statusIcon(_effectiveStatus),
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'كود: $code',
                                      style: AppTextStyles.body(context)
                                          .copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      service,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body(
                                        context,
                                      ).copyWith(fontSize: 12),
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
                                  color: statusColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.25),
                                  ),
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: Text(
                                    statusText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body(context).copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _miniInfoRow(Icons.person_outline, customer),
                          const SizedBox(height: 6),
                          _miniInfoRow(Icons.location_on_outlined, location),
                          if (price.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _miniInfoRow(
                              Icons.payments_outlined,
                              'السعر: $price',
                            ),
                          ],
                          if (createdAt.isNotEmpty || updatedAt.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (createdAt.isNotEmpty)
                                  _datePill(
                                    Icons.calendar_today,
                                    'إنشاء: $createdAt',
                                  ),
                                if (updatedAt.isNotEmpty)
                                  _datePill(Icons.update, 'تحديث: $updatedAt'),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: phone.isEmpty
                                      ? null
                                      : () => _callPhone(phone),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: Get.isDarkMode
                                          ? Colors.white12
                                          : Colors.grey.shade400,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.call_outlined),
                                  label: const Text(
                                    'اتصال',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _hasCoordinates(request['location'])
                                      ? () => _openMap(request['location'])
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    disabledBackgroundColor: Colors.white10,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'الخريطة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,

                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ===== Note / Description Cards =====
                    if (note.isNotEmpty)
                      _sectionCard(
                        title: 'ملاحظة',
                        icon: Icons.note_outlined,
                        child: Text(
                          note,
                          style: AppTextStyles.body(
                            context,
                          ).copyWith(height: 1.6),
                        ),
                      ),

                    if (note.isNotEmpty) const SizedBox(height: 12),

                    if (description.isNotEmpty)
                      _sectionCard(
                        title: 'وصف الطلب',
                        icon: Icons.subject_outlined,
                        child: Text(
                          description,
                          style: AppTextStyles.body(
                            context,
                          ).copyWith(height: 1.7),
                        ),
                      ),

                    if (description.isNotEmpty) const SizedBox(height: 12),

                    // ===== Timeline =====
                    _timelineSection(),

                    const SizedBox(height: 16),

                    // ===== Images =====
                    if (images.isNotEmpty) _imagesSection(context, images),
                  ],
                ),
              ),
      ),
    );
  }

  // =========================
  // UI Helpers
  // =========================
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _miniInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(
              context,
            ).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _datePill(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(minWidth: 0), // مهم مع Wrap
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: AppTextStyles.body(
                context,
              ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineSection() {
    if (timelineData.isEmpty) {
      return _sectionCard(
        title: 'الخط الزمني',
        icon: Icons.timeline,
        child: Text(
          'لا توجد بيانات للخط الزمني',
          style: AppTextStyles.body(context).copyWith(),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 18),
              const SizedBox(width: 8),
              Text(
                'الخط الزمني',
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...List.generate(timelineData.length, (i) {
            final item = timelineData[i];
            final isLast = i == timelineData.length - 1;

            final key = (item['status'] ?? '').toString().toLowerCase().trim();
            final title =
                _statusLabel[key] ?? (key.isEmpty ? 'حالة غير معروفة' : key);
            final note = (item['note'] ?? '').toString().trim();
            final date = _formatDate(item['createdAt']);
            final color = _statusColor(key);
            final icon = _statusIcon(key);

            return _timelineTile(
              title: title,
              subtitle: date,
              note: note,
              color: color,
              icon: icon,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _timelineTile({
    required String title,
    required String subtitle,
    required String note,
    required Color color,
    required IconData icon,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left rail (dot + line)
        SizedBox(
          width: 34,
          child: Column(
            children: [
              AnimatedTimelineDot(color: color, size: 14),
              if (!isLast)
                AnimatedTimelineLine(color: color, height: 64, width: 3),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? Theme.of(context).colorScheme.surface
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(height: 1.5, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagesSection(BuildContext context, List<String> images) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'صور الطلب',
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: images.length,
              itemBuilder: (_, i) {
                final url = images[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 140,
                    color: Colors.white10,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image)),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Status lookups
  // =========================
  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'closed':
        return const Color(0xFF22C55E); // green
      case 'cancelled':
      case 'rejected':
      case 'price_rejected':
        return const Color(0xFFEF4444); // red
      case 'awaiting_confirmation':
        return const Color(0xFFA78BFA); // violet
      case 'awaiting_customer_price_confirm':
      case 'awaiting_payment':
      case 'priced':
      case 'price_accepted':
      case 'payment_intent_created':
        return const Color(0xFFF59E0B); // amber
      case 'on_the_way':
        return const Color(0xFF38BDF8); // sky
      case 'arrived':
      case 'work_started':
      case 'in_progress':
      case 'working':
        return const Color(0xFF14B8A6); // teal
      case 'accepted':
        return const Color(0xFF60A5FA); // blue-400
      case 'assigned':
        return const Color(0xFF94A3B8); // slate
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
      case 'closed':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;

      case 'awaiting_customer_price_confirm':
      case 'awaiting_payment':
      case 'priced':
      case 'price_accepted':
      case 'payment_intent_created':
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
      case 'accepted':
        return Icons.verified_outlined;
      case 'assigned':
        return Icons.assignment_ind_outlined;
      default:
        return Icons.timeline;
    }
  }

  // =========================
  // Actions
  // =========================
  Future<void> _callPhone(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // =========================
  // Data helpers
  // =========================
  List<String> _imagesList(dynamic images) {
    if (images is List) {
      return images
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .map(_resolveImageUrl)
          .toList();
    }
    return const [];
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    final base = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;
    final baseNoApi = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    if (url.startsWith('/')) return '$baseNoApi$url';
    return '$baseNoApi/$url';
  }

  String _serviceText(Map<String, dynamic> req) {
    return (req['serviceName'] ??
            (req['service'] is Map ? (req['service']['name'] ?? '') : null) ??
            req['serviceType'] ??
            'خدمة غير معروفة')
        .toString();
  }

  String _customerText(Map<String, dynamic> req) {
    return ((req['customer'] is Map
                ? req['customer']['name']
                : req['customerName']) ??
            'عميل غير معروف')
        .toString();
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

  bool _hasCoordinates(dynamic location) {
    return location is Map &&
        location['coordinates'] is List &&
        (location['coordinates'] as List).length >= 2;
  }

  Future<void> _openMap(dynamic location) async {
    if (!_hasCoordinates(location)) return;
    final coords = (location['coordinates'] as List);
    final lat = coords[1];
    final lng = coords[0];
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final parsed = DateTime.tryParse(date.toString());
    if (parsed == null) return '';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} - ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}


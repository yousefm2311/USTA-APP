import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/timeline_widget/animated_timeline_dot.dart';
import 'package:usta/Artisan/core/utils/widgets/timeline_widget/animated_timeline_line.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanRequestDetailsView extends StatefulWidget {
  const ArtisanRequestDetailsView({super.key});

  @override
  State<ArtisanRequestDetailsView> createState() =>
      _ArtisanRequestDetailsViewState();
}

class _ArtisanRequestDetailsViewState extends State<ArtisanRequestDetailsView> {
  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();

  Map<String, dynamic> request = {};
  String requestId = '';
  bool loading = true;
  bool updatingStatus = false;

  int currentStep = 0;
  List<String> timelineStatuses = [];
  List<Map<String, dynamic>> timelineData = [];

  // ===== UI Colors =====
  final Color bg = const Color(0xFF050816);
  final Color card = const Color(0xFF0B1020);
  final Color primaryBlue = const Color(0xFF2563EB);

  final List<String> _statusOrder = [
    'assigned',
    'accepted',
    'priced',
    'on_the_way',
    'arrived',
    'work_started',
    'in_progress',
    'awaiting_confirmation',
    'completed',
  ];

  final Set<String> _timelineUpdateStatuses = {
    'on_the_way',
    'arrived',
    'work_started',
    'in_progress',
    'completed',
  };

  final Map<String, String> _statusLabel = {
    'assigned': 'تم تعيين الحرفي',
    'accepted': 'تم قبول الطلب',

    'priced': 'بانتظار موافقة العميل على السعر',
    'awaiting_customer_price_confirm': 'بانتظار موافقة العميل على السعر',

    'awaiting_payment': 'تمت موافقة السعر',
    'price_accepted': 'تمت موافقة السعر',
    'price_rejected': 'تم رفض السعر من قبل العميل',
    'payment_intent_created': 'تمت موافقة السعر',

    'on_the_way': 'في الطريق',
    'arrived': 'تم الوصول',
    'work_started': 'بدأ العمل',
    'in_progress': 'جارٍ العمل',
    'working': 'جارٍ العمل',

    'awaiting_confirmation': 'بانتظار تأكيد العميل',
    'completed': 'مكتمل',

    'cancelled': 'ملغي',
    'rejected': 'مرفوض',
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
      final details = await controller.fetchRequestDetails(requestId);
      if (details != null) {
        request =
            (details['request'] as Map?)?.cast<String, dynamic>() ?? details;
        _hydrateTimeline(details['timeline']);
      }

      final timelineOnly = await controller.fetchRequestTimeline(requestId);
      if (timelineOnly.isNotEmpty) _hydrateTimeline(timelineOnly);
    }

    _syncStepFromStatus();
    if (mounted) setState(() => loading = false);
  }

  void _hydrateTimeline(dynamic list) {
    if (list is List) {
      final items = list
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      // رتّب حسب createdAt لو موجود
      items.sort((a, b) {
        final da = DateTime.tryParse((a['createdAt'] ?? '').toString());
        final db = DateTime.tryParse((b['createdAt'] ?? '').toString());
        if (da == null && db == null) return 0;
        if (da == null) return -1;
        if (db == null) return 1;
        return da.compareTo(db);
      });

      timelineData = items;
      timelineStatuses = items
          .map((e) => (e['status'] ?? '').toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
  }

  String get _effectiveStatus {
    if (timelineStatuses.isNotEmpty) {
      final last = timelineStatuses.last.toLowerCase();
      if (last == 'awaiting_customer_price_confirm') return 'priced';
      if (last == 'awaiting_payment') return 'priced';
      if (_statusOrder.contains(last)) return last;
    }

    final status = (request['status'] ?? '').toString().toLowerCase();
    if (status == 'awaiting_customer_price_confirm') return 'priced';
    if (status == 'awaiting_payment') return 'priced';
    if (_statusOrder.contains(status)) return status;

    return _statusOrder.first;
  }

  bool get _priceApproved {
    final statuses = timelineStatuses.map((e) => e.toLowerCase());
    if (statuses.contains('price_accepted')) return true;

    final status = (request['status'] ?? '').toString().toLowerCase();
    if (status == 'price_accepted' || status == 'awaiting_payment') {
      return true;
    }

    final pricing = request['pricing'];
    if (pricing is Map) {
      final decision = (pricing['customerDecision'] ?? '')
          .toString()
          .toLowerCase();
      if (decision == 'accepted') return true;
    }

    return false;
  }

  bool get _canUpdateTimeline {
    final status = _effectiveStatus;
    if (status.isEmpty) return false;
    if (_priceApproved) {
      return ![
        'awaiting_confirmation',
        'completed',
        'cancelled',
        'rejected',
        'expired',
      ].contains(status);
    }
    return ![
      'priced',
      'awaiting_payment',
      'awaiting_confirmation',
      'completed',
      'cancelled',
      'rejected',
      'expired',
    ].contains(status);
  }

  void _syncStepFromStatus() {
    currentStep = _statusOrder.indexOf(_effectiveStatus);
    if (_priceApproved) {
      final pricedIndex = _statusOrder.indexOf('priced');
      if (pricedIndex > currentStep) currentStep = pricedIndex;
    }

    if (currentStep < 0) currentStep = 0;
  }

  Future<void> _updateStatus(String status) async {
    if (requestId.isEmpty) return;
    if (_effectiveStatus == 'awaiting_confirmation' ||
        _effectiveStatus == 'completed')
      return;

    setState(() => updatingStatus = true);

    await controller.updateTimeline(requestId, status);

    final details = await controller.fetchRequestDetails(requestId);
    if (details != null) {
      request =
          (details['request'] as Map?)?.cast<String, dynamic>() ?? details;
      _hydrateTimeline(details['timeline']);
    }

    final timelineOnly = await controller.fetchRequestTimeline(requestId);
    if (timelineOnly.isNotEmpty) _hydrateTimeline(timelineOnly);

    _syncStepFromStatus();
    if (mounted) setState(() => updatingStatus = false);
  }

  // =========================
  // UI Helpers (Design)
  // =========================
  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return const Color(0xFF60A5FA);
      case 'accepted':
        return const Color(0xFF22C55E);

      case 'priced':
      case 'awaiting_customer_price_confirm':
        return const Color(0xFFF59E0B);

      case 'awaiting_payment':
      case 'price_accepted':
      case 'payment_intent_created':
        return const Color(0xFF22C55E);

      case 'price_rejected':
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFEF4444);

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

      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'accepted':
        return Icons.verified_outlined;

      case 'priced':
      case 'awaiting_customer_price_confirm':
        return Icons.price_change_outlined;

      case 'awaiting_payment':
      case 'price_accepted':
      case 'payment_intent_created':
        return Icons.payments_outlined;

      case 'price_rejected':
        return Icons.highlight_off_outlined;

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
        return Icons.info_outline;
    }
  }

  Widget _pill({required String text, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
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
    final description = (request['description'] ?? '').toString();
    final images = _imagesList(request['images']);

    final eff = _effectiveStatus;
    final effColor = _statusColor(eff);

    final statusText = _priceApproved
        ? (_statusLabel['price_accepted'] ?? 'تمت موافقة السعر')
        : (_statusLabel[eff] ?? eff);

    final price =
        request['agreedPrice']?.toString() ??
        request['price']?.toString() ??
        request['budget']?.toString() ??
        '';

    final code = (request['code'] ?? request['_id'] ?? request['id'] ?? '')
        .toString();
    final createdAt = _formatDate(request['createdAt']);
    final note = (request['note'] ?? '').toString();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تفاصيل الطلب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                setState(() => loading = true);
                await _bootstrap();
              },
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: effColor.withOpacity(0.06),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: effColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: effColor.withOpacity(0.25),
                            ),
                          ),
                          child: Icon(_statusIcon(eff), color: effColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'كود الطلب: $code',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _pill(
                                    text: statusText,
                                    color: effColor,
                                    icon: Icons.info_outline,
                                  ),
                                  if (price.isNotEmpty)
                                    _pill(
                                      text: 'السعر: $price',
                                      color: const Color(0xFF22C55E),
                                      icon: Icons.payments_outlined,
                                    ),
                                  if (createdAt.isNotEmpty)
                                    _pill(
                                      text: createdAt,
                                      color: const Color(0xFF94A3B8),
                                      icon: Icons.access_time,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('بيانات الطلب'),
                  _infoTile(
                    Icons.home_repair_service_outlined,
                    'الخدمة',
                    service,
                  ),
                  _infoTile(Icons.person_outline, 'العميل', customer),
                  if (phone.isNotEmpty)
                    _infoTile(Icons.phone_outlined, 'الهاتف', phone),
                  _infoTile(Icons.location_on_outlined, 'الموقع', location),
                  if (note.isNotEmpty)
                    _infoTile(Icons.note_outlined, 'ملاحظة', note),
                  const SizedBox(height: 16),
                  if (description.isNotEmpty) ...[
                    _sectionTitle('وصف الطلب'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        description,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(height: 1.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle('تحديث الحالة'),
                  _stepper(),
                  const SizedBox(height: 16),
                  _sectionTitle('خطوات التنفيذ'),
                  _timelineNice(),
                  const SizedBox(height: 16),
                  if (images.isNotEmpty) ...[
                    _sectionTitle('صور الطلب'),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            images[i],
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _hasCoordinates(request['location'])
                          ? _openMapScreen
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text(
                        'عرض الموقع على الخريطة',
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
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryBlue.withOpacity(0.22)),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper() {
    final disabled =
        !_canUpdateTimeline ||
        _effectiveStatus == 'awaiting_confirmation' ||
        _effectiveStatus == 'completed';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (updatingStatus) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(primaryBlue),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (disabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.25)),
              ),
              child: Text(
                _effectiveStatus == 'awaiting_confirmation'
                    ? 'بانتظار تأكيد العميل'
                    : _effectiveStatus == 'priced'
                    ? 'بانتظار موافقة العميل على السعر'
                    : 'لا يمكن تحديث الحالة الآن',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (disabled) const SizedBox(height: 12),
          ...List.generate(_statusOrder.length, (index) {
            final statusKey = _statusOrder[index];
            final label = _statusLabel[statusKey] ?? statusKey;
            final reached = index <= currentStep;
            final afterPriced = index > _statusOrder.indexOf('priced');
            final lockedByPrice = !_priceApproved && afterPriced;
            final tappable =
                !disabled &&
                !updatingStatus &&
                statusKey != _effectiveStatus &&
                _timelineUpdateStatuses.contains(statusKey) &&
                index > currentStep &&
                !lockedByPrice;
            final c = reached ? primaryBlue : Colors.white24;
            return InkWell(
              onTap: tappable ? () => _updateStatus(statusKey) : null,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      reached
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: Get.isDarkMode
                          ? c
                          : (reached ? primaryBlue : Colors.black26),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (lockedByPrice)
                      const Icon(Icons.lock_outline, size: 18)
                    else if (tappable)
                      const Icon(Icons.touch_app_outlined, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _timelineNice() {
    if (timelineData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'لا يوجد بيانات في الخط الزمني حتى الآن',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: List.generate(timelineData.length, (i) {
          final item = timelineData[i];
          final statusKey = (item['status'] ?? '').toString().toLowerCase();
          final statusText = _statusLabel[statusKey] ?? statusKey;
          final note = (item['note'] ?? '').toString();
          final date = _formatDate(item['createdAt']);

          final isLast = i == timelineData.length - 1;
          final c = _statusColor(statusKey);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    AnimatedTimelineDot(color: c, size: 14),
                    if (!isLast)
                      AnimatedTimelineLine(color: c, height: 64, width: 3),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Get.isDarkMode
                        ? Theme.of(context).colorScheme.surface
                        : Colors.grey.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_statusIcon(statusKey), size: 18, color: c),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          note,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
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
    return 'موقع غير معروف';
  }

  bool _hasCoordinates(dynamic location) {
    return location is Map &&
        location['coordinates'] is List &&
        (location['coordinates'] as List).length >= 2;
  }

  Future<void> _openMapScreen() async {
    await Get.toNamed(
      AppRoutes.artisanRequestMapView,
      arguments: {'request': request, 'requestId': requestId},
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final parsed = DateTime.tryParse(date.toString());
    if (parsed == null) return '';

    final d = parsed.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy • $hh:$mi';
  }
}


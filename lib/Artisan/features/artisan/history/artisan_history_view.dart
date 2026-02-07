import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/formatters.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanHistoryView extends StatefulWidget {
  const ArtisanHistoryView({super.key});

  @override
  State<ArtisanHistoryView> createState() => _ArtisanHistoryViewState();
}

class _ArtisanHistoryViewState extends State<ArtisanHistoryView> {
  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();

  // Dark theme colors (same vibe as your other screens)
  final Color bg = const Color(0xFF050816);
  final Color card = const Color(0xFF0B1020);
  final Color primaryBlue = const Color(0xFF2563EB);

  String _filter = 'all'; // all/completed/rejected/cancelled/pending

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "سجل الطلبات",
            style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
          ),
        ),
        body: Obx(() {
          final loading = controller.loadingHistory.value;
          final all = controller.historyRequests;

          if (loading && all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _applyFilter(all);
          final grouped = _groupByDate(filtered);

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: controller.fetchHistoryRequests,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _filtersBar(all),

                const SizedBox(height: 14),
                if (filtered.isEmpty) ...[
                  const SizedBox(height: 80),
                  Icon(Icons.inbox_outlined, size: 54),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'لا يوجد طلبات في هذا القسم',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'اسحب لتحديث القائمة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ),
                ] else ...[
                  ...grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dateHeader(entry.key),
                        const SizedBox(height: 10),
                        ...entry.value.map((req) => _requestCard(context, req)),
                        const SizedBox(height: 6),
                      ],
                    );
                  }),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // =========================
  // Filters
  // =========================
  Widget _filtersBar(List<Map<String, dynamic>> all) {
    final counts = _counts(all);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('الكل', 'all', counts['all'] ?? 0),
            _filterChip('مكتملة', 'completed', counts['completed'] ?? 0),
            _filterChip('مرفوضة', 'rejected', counts['rejected'] ?? 0),
            _filterChip('ملغاة', 'cancelled', counts['cancelled'] ?? 0),
            _filterChip('قيد المراجعة', 'pending', counts['pending'] ?? 0),
          ],
        ),
      ),
    );
  }

  Map<String, int> _counts(List<Map<String, dynamic>> items) {
    int countOf(String filter) => _applyFilter(items, forced: filter).length;

    return {
      'all': items.length,
      'completed': countOf('completed'),
      'rejected': countOf('rejected'),
      'cancelled': countOf('cancelled'),
      'pending': countOf('pending'),
    };
  }

  Widget _filterChip(String label, String value, int count) {
    final selected = _filter == value;
    final chipColor = selected ? primaryBlue : _statusColor(value);

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        avatar: Icon(
          _statusIcon(value),
          color: selected ? primaryBlue : chipColor,
          size: 18,
        ),
        label: Text('$label ($count)'),
        selected: selected,
        selectedColor: primaryBlue.withOpacity(0.18),
        backgroundColor: Get.isDarkMode ? Colors.white10 : Colors.grey.shade300,
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.white12,
        ),
        labelStyle: AppTextStyles.body(context).copyWith(
          color: Get.isDarkMode
              ? selected
                    ? primaryBlue
                    : Colors.white
              : selected
              ? primaryBlue
              : Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  IconData _statusIcon(String value) {
    switch (value) {
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      case 'pending':
        return Icons.hourglass_bottom;
      default:
        return Icons.list_alt;
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'completed':
        return const Color(0xFF22C55E);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'cancelled':
        return const Color(0xFFF59E0B);
      case 'pending':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  // =========================
  // Cards
  // =========================
  Widget _requestCard(BuildContext context, Map<String, dynamic> request) {
    final id = (request['id'] ?? request['_id'] ?? '').toString();

    final title =
        (request['code'] ??
                '#${request['serviceType'] ?? 'طلب'}-${(request['createdAt'] ?? '').hashCode % 9999}')
            .toString();

    final service =
        (request['serviceName'] ??
                (request['service'] is Map
                    ? (request['service']['name'] ?? '')
                    : null) ??
                request['serviceType'] ??
                'غير محدد')
            .toString();

    final customer =
        ((request['customer'] is Map
                    ? request['customer']['name']
                    : request['customerName']) ??
                'عميل')
            .toString();

    final location = _formatLocation(request['location'], request['address']);
    final statusRaw = (request['status'] ?? '').toString();
    final statusKey = statusRaw.toLowerCase();

    final category = _categoryFromStatus(
      statusKey,
    ); // completed/cancelled/rejected/pending
    final statusText = _statusLabel(statusKey);

    final statusColor = _categoryColor(category);
    final statusIcon = _categoryIcon(category);

    final dt = _bestDate(request);
    final dateText = dt == null ? '' : Formatters.formatDateTime(dt.toLocal());

    final isFinished =
        category == 'completed' ||
        category == 'cancelled' ||
        category == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 8),
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
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _infoRow(Icons.person_outline, customer),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, location),

          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.access_time, dateText, muted: true),
          ],

          const SizedBox(height: 12),

          // Action / Timeline
          if (isFinished)
            _timelineBlock(context, request, category)
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (id.isEmpty) return;
                  pushNamedRoute(
                    AppRoutes.artisanRequestDetailsView,
                    arguments: {'requestId': id, 'request': request},
                  );
                },
                icon: Icon(Icons.open_in_new, color: primaryBlue, size: 18),
                label: Text(
                  'عرض التفاصيل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryBlue.withOpacity(0.9)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool muted = false}) {
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

  // =========================
  // Timeline block
  // =========================
  Widget _timelineBlock(
    BuildContext context,
    Map<String, dynamic> request,
    String category,
  ) {
    final rawTimeline =
        (request['timeline'] as List?) ??
        (request['history'] as List?) ??
        const [];
    final steps = _normalizeTimeline(rawTimeline);

    final color = _categoryColor(category);

    // لو مفيش Timeline من الباك
    final fallbackSteps = _staticTimelineSteps(category);

    final showSteps = steps.isEmpty ? fallbackSteps : steps;

    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          collapsedIconColor: Get.isDarkMode ? Colors.white54 : Colors.black54,
          iconColor: Get.isDarkMode ? Colors.white54 : Colors.black54,
          title: Row(
            children: [
              Icon(Icons.timeline, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الخط الزمني',
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Text(
                  _categoryLabel(category),
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 6),
            ...List.generate(showSteps.length, (i) {
              final isLast = i == showSteps.length - 1;
              final item = showSteps[i];

              final title = item['title'] ?? '';
              final note = item['note'] ?? '';
              final time = item['time'] ?? '';

              String timeText = '';
              final parsed = DateTime.tryParse(time);
              if (parsed != null) {
                timeText = Formatters.formatDateTime(parsed.toLocal());
              }
              final stepKey = (item['key'] ?? '').toString();
              final stepColor = _stepColor(stepKey);

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // timeline rail
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: stepColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 42,
                            color: stepColor.withOpacity(0.45),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stepColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stepColor.withOpacity(0.25),
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (timeText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeText,
                                style: AppTextStyles.body(context).copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                note,
                                style: AppTextStyles.body(context).copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Open details (completed page)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final id = (request['id'] ?? request['_id'] ?? '').toString();
                  if (id.isEmpty) return;

                  pushNamedRoute(
                    AppRoutes.artisanRequestDetailsFromCompletedView,
                    arguments: {'requestId': id, 'request': request},
                  );
                },
                icon: Icon(Icons.open_in_new, size: 18),
                label: Text(
                  'عرض التفاصيل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryBlue.withOpacity(0.9)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Data helpers
  // =========================
  List<Map<String, String>> _normalizeTimeline(List<dynamic> raw) {
    if (raw.isEmpty) return [];

    final List<Map<String, String>> out = [];
    for (final item in raw) {
      if (item is Map) {
        final rawStatus = (item['status'] ?? item['step'] ?? '').toString();
        if (rawStatus.isEmpty) continue;

        final key = rawStatus.toLowerCase();
        final note = (item['note'] ?? item['message'] ?? '').toString();
        final created = (item['createdAt'] ?? item['date'] ?? '').toString();

        out.add({
          'key': key, // ✅ جديد
          'title': _statusLabel(key),
          'note': note,
          'time': created,
        });
      }
    }

    out.sort((a, b) {
      final da = DateTime.tryParse(a['time'] ?? '');
      final db = DateTime.tryParse(b['time'] ?? '');
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db);
    });

    return out;
  }

  List<Map<String, String>> _staticTimelineSteps(String category) {
    final endKey = category == 'completed'
        ? 'completed'
        : category == 'cancelled'
        ? 'cancelled'
        : 'rejected';

    final endTitle = category == 'completed'
        ? 'مكتمل'
        : category == 'cancelled'
        ? 'ملغى'
        : 'مرفوض';

    return [
      {'key': 'created', 'title': 'تم إنشاء الطلب', 'note': '', 'time': ''},
      {'key': 'assigned', 'title': 'تم الإسناد', 'note': '', 'time': ''},
      {
        'key': 'in_progress',
        'title': 'تمت معالجة الطلب',
        'note': '',
        'time': '',
      },
      {'key': endKey, 'title': endTitle, 'note': '', 'time': ''},
    ];
  }

  Color _stepColor(String key) {
    final s = key.toLowerCase();

    if (s.contains('assigned')) return const Color(0xFF60A5FA); // blue
    if (s.contains('accepted')) return const Color(0xFF22C55E); // green

    if (s.contains('awaiting_customer_price_confirm') ||
        s.contains('priced') ||
        s.contains('awaiting_payment')) {
      return const Color(0xFFF59E0B); // amber
    }

    if (s.contains('on_the_way') ||
        s.contains('onroute') ||
        s.contains('on_route')) {
      return const Color(0xFF38BDF8); // sky
    }

    if (s.contains('arrived')) return const Color(0xFF14B8A6); // teal
    if (s.contains('work_started')) return const Color(0xFF6366F1); // indigo
    if (s.contains('in_progress') || s.contains('working'))
      return const Color(0xFF06B6D4); // cyan
    if (s.contains('awaiting_confirmation'))
      return const Color(0xFFA78BFA); // violet

    if (s.contains('completed')) return const Color(0xFF22C55E); // green
    if (s.contains('cancel')) return const Color(0xFFF97316); // orange
    if (s.contains('reject')) return const Color(0xFFEF4444); // red

    if (s.contains('created')) return const Color(0xFF94A3B8); // slate

    return const Color(0xFF94A3B8);
  }

  DateTime? _bestDate(Map<String, dynamic> req) {
    final raw = (req['updatedAt'] ?? req['createdAt'] ?? '').toString();
    final dt = DateTime.tryParse(raw);
    return dt;
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
    return 'لا يوجد عنوان';
  }

  // =========================
  // Status mapping
  // =========================
  String _categoryFromStatus(String s) {
    // completed
    if (s.contains('completed')) return 'completed';

    // cancelled
    if (s.contains('cancel')) return 'cancelled';

    // rejected
    if (s.contains('reject')) return 'rejected';

    // closed treated as completed-ish
    if (s.contains('closed')) return 'completed';

    // pending-ish (review / priced / awaiting / assigned / accepted / in_progress)
    return 'pending';
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'completed':
        return const Color(0xFF22C55E);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'cancelled':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF60A5FA);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.hourglass_bottom_outlined;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'completed':
        return 'مكتمل';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغى';
      default:
        return 'قيد المراجعة';
    }
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();

    if (s.contains('pending') || s.contains('review')) return 'قيد المراجعة';
    if (s.contains('assigned')) return 'تم الإسناد';
    if (s.contains('accepted')) return 'تم القبول';

    if (s.contains('awaiting_customer_price_confirm') ||
        s.contains('priced') ||
        s.contains('awaiting_payment')) {
      return 'بانتظار موافقة العميل على السعر';
    }

    if (s.contains('on_route') ||
        s.contains('onroute') ||
        s.contains('on_the_way'))
      return 'في الطريق';
    if (s.contains('arrived')) return 'تم الوصول';
    if (s.contains('work_started')) return 'بدأ العمل';
    if (s.contains('in_progress') || s.contains('working')) return 'العمل جارٍ';

    if (s.contains('completed')) return 'مكتمل';
    if (s.contains('cancel')) return 'ملغى';
    if (s.contains('reject')) return 'مرفوض';
    if (s.contains('closed')) return 'مغلق';

    return status;
  }

  // =========================
  // Filtering + grouping
  // =========================
  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> items, {
    String? forced,
  }) {
    final f = forced ?? _filter;

    bool matches(Map<String, dynamic> req) {
      final s = (req['status'] ?? '').toString().toLowerCase();
      final cat = _categoryFromStatus(s);

      if (f == 'all') return true;
      return cat == f;
    }

    final out = items.where(matches).toList();

    // sort newest first
    out.sort((a, b) {
      final db = _bestDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final da = _bestDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    return out;
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> items,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in items) {
      final dt = _bestDate(item) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final label = _dateLabel(dt);
      grouped.putIfAbsent(label, () => []).add(item);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final da = a.value.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : (_bestDate(a.value.first) ??
                  DateTime.fromMillisecondsSinceEpoch(0));
        final db = b.value.isEmpty
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : (_bestDate(b.value.first) ??
                  DateTime.fromMillisecondsSinceEpoch(0));
        return db.compareTo(da);
      });

    return {for (final e in entries) e.key: e.value};
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(thatDay).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';

    return '${thatDay.day.toString().padLeft(2, '0')}/${thatDay.month.toString().padLeft(2, '0')}/${thatDay.year}';
  }

  Widget _dateHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}


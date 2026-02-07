import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanCompletedRequestsView extends StatelessWidget {
  ArtisanCompletedRequestsView({super.key});

  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();

  // Dark style (matching your app)
  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);
  Color get green => const Color(0xFF22C55E);

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
            "الطلبات المنتهية",
            style: AppTextStyles.body(context).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Obx(() {
          final loading = controller.loadingHistory.value;
          final list = controller.historyRequests;

          if (loading && list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = [...list]
            ..sort((a, b) {
              final bDate = _parseDate(b['updatedAt'] ?? b['createdAt']);
              final aDate = _parseDate(a['updatedAt'] ?? a['createdAt']);
              return bDate.compareTo(aDate);
            });

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: controller.fetchHistoryRequests,
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Icon(
                        Icons.inbox_outlined,
                        size: 54,
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'لا توجد طلبات منتهية بعد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'اسحب لتحديث القائمة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
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
                          (request['serviceName'] ??
                                  (request['service'] is Map
                                      ? (request['service']['name'] ?? '')
                                      : null) ??
                                  request['serviceType'] ??
                                  'خدمة')
                              .toString();

                      final customer =
                          ((request['customer'] is Map
                                      ? request['customer']['name']
                                      : request['customerName']) ??
                                  'عميل')
                              .toString();

                      final location = _formatLocation(
                        request['location'],
                        request['address'],
                      );

                      final lastUpdate = _parseDate(
                        request['updatedAt'] ?? request['createdAt'],
                      );
                      final lastUpdateText = _formatDate(lastUpdate);

                      return _completedCard(
                        context: context,
                        title: title,
                        service: service,
                        customer: customer,
                        location: location,
                        lastUpdate: lastUpdateText,
                        onDetails: () {
                          if (id.isEmpty) return;

                          // ✅ important: send both requestId + request
                          pushNamedRoute(
                            AppRoutes.artisanRequestDetailsFromCompletedView,
                            arguments: {'requestId': id, 'request': request},
                          );
                        },
                      );
                    },
                  ),
          );
        }),
      ),
    );
  }

  Widget _completedCard({
    required BuildContext context,
    required String title,
    required String service,
    required String customer,
    required String location,
    required String lastUpdate,
    required VoidCallback onDetails,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.06),
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
                  color: green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: green.withOpacity(0.25)),
                ),
                child: Icon(Icons.check_circle_outline, color: green, size: 24),
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
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 12,

                      ),
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
                  color: green.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: green.withOpacity(0.25)),
                ),
                child: Text(
                  'منتهية',
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, customer, context),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, location, context),

          if (lastUpdate.isNotEmpty) ...[
            const SizedBox(height: 10),
            _pill(context,icon: Icons.update, text: 'آخر تحديث: $lastUpdate'),
          ],

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
                'عرض التفاصيل',
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

  Widget _pill(context,{required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:Get.isDarkMode? Colors.white10 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
    return 'غير متوفر';
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}


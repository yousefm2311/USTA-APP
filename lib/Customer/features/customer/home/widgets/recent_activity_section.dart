import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/formatters.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/favorites/views/customer_history_view.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';
import 'package:usta/Customer/features/customer/home/widgets/section_header.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';

class RecentActivitySection extends StatelessWidget {
  final CustomerRequestsController requestsCtrl;
  const RecentActivitySection({super.key, required this.requestsCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: "نشاط حديث".tr),
        const SizedBox(height: 12),
        Obx(() {
          if (requestsCtrl.loadingHistory.value) {
            return Column(
              children: List.generate(
                2,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerSkeletons.listTile(height: 86),
                ),
              ),
            );
          }

          final combined = <Map<String, dynamic>>[];
          final seenIds = <String>{};

          void addItem(Map<String, dynamic> item) {
            final id = (item['_id'] ?? item['id'])?.toString();
            if (id == null || id.isEmpty || seenIds.contains(id)) return;
            seenIds.add(id);
            combined.add(item);
          }

          for (final item in requestsCtrl.activeRequests) {
            addItem(item);
          }
          for (final item in requestsCtrl.historyRequests) {
            addItem(item);
          }

          combined.sort((a, b) {
            final aTime =
                safeParseDate(a['updatedAt']) ??
                safeParseDate(a['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                safeParseDate(b['updatedAt']) ??
                safeParseDate(b['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          if (combined.isEmpty) {
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                'لا يوجد نشاط حديث'.tr,
                style: const TextStyle(
                  fontFamily: AppText.font,
                ),
              ),
            );
          }

          final recent = combined.take(2).toList();
          final showViewAll = combined.length > 2;

          return Column(
            children: [
              ...recent.map((req) => _RecentActivityTile(req: req)),
              if (showViewAll)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Get.to(() => CustomerHistoryView()),
                    child: Text(
                      'عرض الكل'.tr,
                      style: const TextStyle(fontFamily: AppText.font),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  final Map<String, dynamic> req;
  const _RecentActivityTile({required this.req});

  @override
  Widget build(BuildContext context) {
    final status = (req['status'] ?? '').toString();
    final address = (req['address'] ?? '').toString();
    final service = (req['serviceType'] ?? req['category'] ?? '').toString();
    final timeValue = req['createdAt'] ?? req['updatedAt'];
    final time = safeParseDate(timeValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        radius: 14,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.isNotEmpty ? service : 'غير معروف'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppText.font,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [address, status].where((e) => e.isNotEmpty).join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppText.font,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDate(time),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppText.font,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime? safeParseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String && v.trim().isNotEmpty) {
    return DateTime.tryParse(v);
  }
  return null;
}


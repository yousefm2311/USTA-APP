import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/favorites/views/widgets/history_status_chip.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_request_details_view.dart';

class HistoryRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const HistoryRequestCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final service =
        item['serviceType'] ?? item['service'] ?? item['category'] ?? '';
    final desc = item['description'] ?? item['details'] ?? '';
    final status = (item['status'] ?? '').toString().toLowerCase();

    final address = item['address'] ?? item['location'] ?? '';
    final createdAtRaw = item['createdAt'] ?? item['updatedAt'] ?? '';

    final artisan = item['artisan'] is Map<String, dynamic>
        ? item['artisan'] as Map<String, dynamic>
        : null;
    final artisanName = artisan?['name'] ?? artisan?['artisanName'] ?? '';

    final id =
        (item['_id'] ?? item['id'] ?? item['requestId'])?.toString() ?? '';

    return InkWell(
      onTap: () {
        if (id.isEmpty) return;
        Get.to(() => CustomerRequestDetailsView(requestId: id));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: Icon(Icons.history, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.toString().trim().isNotEmpty
                              ? service.toString()
                              : 'طلب خدمة'.tr,
                          style: TextStyle(
                            fontFamily: "Cairo",
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (status.isNotEmpty) HistoryStatusChip(status: status),
                    ],
                  ),
                  if (desc.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      desc.toString(),
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.78),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (address.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address.toString(),
                            style: TextStyle(
                              fontFamily: "Cairo",
                              fontSize: 11.5,
                              color: scheme.onSurface.withOpacity(0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (artisanName.toString().trim().isNotEmpty) ...[
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            artisanName.toString(),
                            style: TextStyle(
                              fontFamily: "Cairo",
                              fontSize: 11.5,
                              color: scheme.onSurface.withOpacity(0.75),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (artisanName.toString().trim().isNotEmpty &&
                          createdAtRaw.toString().trim().isNotEmpty)
                        const SizedBox(width: 10),
                      if (createdAtRaw.toString().trim().isNotEmpty) ...[
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatDate(createdAtRaw.toString()),
                            style: TextStyle(
                              fontFamily: "Cairo",
                              fontSize: 11.5,
                              color: scheme.onSurface.withOpacity(0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "اضغط لعرض التفاصيل".tr,
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';

    final dt = DateTime.tryParse(v);
    if (dt != null) {
      final d = dt.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
    }

    return v;
  }
}


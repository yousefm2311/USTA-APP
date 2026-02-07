import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/formatters.dart';
import 'package:usta/Customer/features/customer/complaints/views/customer_complaint_detail_view.dart';

Widget itemcomplaint(BuildContext context, Map<String, dynamic> complaint) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final title = complaint['issue']?.toString() ?? 'شكوى'.tr;
  final status =
      complaint['statusLabel']?.toString() ??
      complaint['status']?.toString() ??
      'مفتوحة'.tr;
  final id = complaint['_id']?.toString() ?? complaint['id']?.toString() ?? '';
  final date = complaint['createdAt']?.toString() ?? '';
  final DateTime parsedDate = DateTime.parse(date);
  final border = scheme.outlineVariant.withOpacity(0.55);
  final isDark = theme.brightness == Brightness.dark;
  final chipBg = scheme.onSurface.withOpacity(isDark ? 0.12 : 0.06);
  final chipFg = scheme.onSurface.withOpacity(isDark ? 0.85 : 0.78);

  return InkWell(
    onTap: id.isEmpty
        ? null
        : () => Get.to(() => CustomerComplaintDetailView(complaintId: id)),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: "Cairo",
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: chipFg,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  Formatters.formatDate(parsedDate),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


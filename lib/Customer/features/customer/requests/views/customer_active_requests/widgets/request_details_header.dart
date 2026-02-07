import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_section_card.dart';

class RequestDetailsHeader extends StatelessWidget {
  const RequestDetailsHeader({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.updatedAtText,
  });

  final String statusLabel;
  final Color statusColor;
  final String updatedAtText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RequestSectionCard(
      child: Row(
        children: [
          Icon(Icons.timelapse, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخر تحديث'.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  updatedAtText.isEmpty ? 'غير متاح'.tr : updatedAtText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: statusColor.withOpacity(isDark ? 0.35 : 0.25),
              ),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/animated_timeline_dot.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/animated_timeline_line.dart';

class RequestTimelineSection extends StatelessWidget {
  const RequestTimelineSection({
    super.key,
    required this.items,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.formatDate,
  });

  final List<Map<String, dynamic>> items;
  final Color Function(String status) statusColor;
  final String Function(String status) statusLabel;
  final IconData Function(String status) statusIcon;
  final String Function(dynamic value) formatDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'لا يوجد تاريخ حتى الآن'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          final st = (item['status'] ?? '').toString();
          final note = item['note']?.toString() ?? '';
          final date = formatDate(item['createdAt']);
          final color = statusColor(st);
          final label = statusLabel(st);
          final icon = statusIcon(st);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedTimelineDot(
                    color: color,
                    icon: icon,
                    size: 18,
                  ),
                  if (!isLast)
                    AnimatedTimelineLine(color: color, height: 64, width: 2),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: color, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (date.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: scheme.onSurface.withOpacity(0.75),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(0.75),
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (note.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          note,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            height: 1.5,
                            color: scheme.onSurface.withOpacity(0.85),
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
}


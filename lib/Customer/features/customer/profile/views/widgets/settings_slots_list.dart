import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsSlotsList extends StatelessWidget {
  final List<Map<String, dynamic>> slots;
  final ValueChanged<int> onRemove;

  const SettingsSlotsList({
    super.key,
    required this.slots,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'لا توجد مواعيد محددة'.tr,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: scheme.onSurface.withOpacity(0.75),
          ),
        ),
      );
    }

    return Column(
      children: slots.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatSlot(value),
                  style:
                      TextStyle(fontFamily: 'Cairo', color: scheme.onSurface),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: scheme.error),
                onPressed: () => onRemove(index),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatSlot(Map<String, dynamic> slot) {
    final day = (slot['day']?.toString() ?? 'يوم').tr;
    final from = slot['from']?.toString() ?? '';
    final to = slot['to']?.toString() ?? '';
    return '$day: $from - $to';
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsUnavailablePicker extends StatelessWidget {
  final String text;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const SettingsUnavailablePicker({
    super.key,
    required this.text,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            'غير متاح حتى'.tr,
            style: TextStyle(fontFamily: 'Cairo', color: scheme.onSurface),
          ),
          const Spacer(),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: scheme.onSurface.withOpacity(0.85),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_calendar,
              color: scheme.onSurface.withOpacity(0.85),
            ),
            onPressed: onPick,
          ),
          IconButton(
            icon: Icon(Icons.clear, color: scheme.error),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

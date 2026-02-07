import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActiveRequestsEmptyState extends StatelessWidget {
  const ActiveRequestsEmptyState({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: scheme.onSurface),
            const SizedBox(height: 10),
            Text(
              'لا يوجد طلبات نشطة حالياً'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اسحب لتحديث القائمة أو جرّب مرة أخرى.'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(
                'تحديث'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

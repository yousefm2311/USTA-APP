import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateRequestActionButton extends StatelessWidget {
  const CreateRequestActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Get.isDarkMode ? Colors.white : Colors.black),
          const SizedBox(width: 8),
          if (loading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'جاري جلب الموقع...'.tr,
                style: const TextStyle(fontFamily: "Cairo",fontSize: 14),
                overflow: TextOverflow.ellipsis,
                
              ),
            ),
          ] else
            Flexible(
              child: Text(
                label.tr,
                style: TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 16,
                  color: Get.isDarkMode ? Colors.white : Colors.black54,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

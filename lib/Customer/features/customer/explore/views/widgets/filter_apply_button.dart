import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExploreFilterApplyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;

  const ExploreFilterApplyButton({
    super.key,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Text(
        "تطبيق".tr,
        style: const TextStyle(fontFamily: "Cairo"),
      ),
    );
  }
}

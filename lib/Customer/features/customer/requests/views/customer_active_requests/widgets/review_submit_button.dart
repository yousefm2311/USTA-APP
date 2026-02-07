import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewSubmitButton extends StatelessWidget {
  const ReviewSubmitButton({
    super.key,
    required this.submitting,
    required this.onPressed,
    required this.color,
  });

  final bool submitting;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: submitting ? null : onPressed,
        child: Text(
          submitting ? "جارٍ الإرسال...".tr : "إرسال التقييم".tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

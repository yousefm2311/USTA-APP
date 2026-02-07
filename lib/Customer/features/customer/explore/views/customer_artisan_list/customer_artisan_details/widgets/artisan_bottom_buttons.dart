import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ArtisanBottomButtons extends StatelessWidget {
  final VoidCallback onRequest;
  final VoidCallback onShowMap;
  final Color primaryColor;

  const ArtisanBottomButtons({
    super.key,
    required this.onRequest,
    required this.onShowMap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "طلب خدمة".tr,
              style: const TextStyle(fontFamily: "Cairo"),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onShowMap,
            icon: const Icon(Icons.location_on_outlined),
            label: Text(
              "عرض على الخريطة".tr,
              style: const TextStyle(fontFamily: "Cairo"),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

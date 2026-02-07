import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';

class SearchField extends StatelessWidget {
  final VoidCallback onTap;
  const SearchField({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 10),
            Text(
              "ابحث عن أي خدمة...".tr,
              style: const TextStyle(
                fontFamily: AppText.font,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


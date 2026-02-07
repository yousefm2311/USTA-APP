import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/constants/app_assets.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border(context);
    return AppCard(
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              AssetsData.logo,
              scale: 1,
              color: Get.isDarkMode
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "جاهز لطلب خدمة".tr,
                  style: TextStyle(
                    fontFamily: AppText.font,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "ابدأ الآن واختر أقرب حرفي".tr,
                  style: TextStyle(fontFamily: AppText.font, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(.16),
              borderRadius: BorderRadius.circular(999),
              // border: Border.all(color: border),
            ),
            child: Text(
              "متصل".tr,
              style: const TextStyle(
                fontFamily: AppText.font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


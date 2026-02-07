import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/rate_app_widgets.dart';

class CustomerRateAppView extends StatefulWidget {
  const CustomerRateAppView({super.key});

  @override
  State<CustomerRateAppView> createState() => _CustomerRateAppViewState();
}

class _CustomerRateAppViewState extends State<CustomerRateAppView> {
  int rating = 0;

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  final reviewCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          "تقييم التطبيق".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "ما تقييمك لتطبيق USTA؟".tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),

          RateAppStarRow(
            rating: rating,
            onSelect: (v) => setState(() => rating = v),
          ),
          const SizedBox(height: 30),

          RateAppReviewBox(
            controller: reviewCtrl,
            cardColor: card,
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              "إرسال".tr,
              style: const TextStyle(fontFamily: "Cairo"),
            ),
          ),

          TextButton(
            onPressed: () {},
            child: Text(
              "تقييم التطبيق على المتجر".tr,
              style: const TextStyle(color: Colors.white54, fontFamily: "Cairo"),
            ),
          ),
        ],
      ),
    );
  }

}


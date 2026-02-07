import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerCardAddedSuccessView extends StatelessWidget {
  final String last4;

  const CustomerCardAddedSuccessView({super.key, required this.last4});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: blue.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "تم إضافة البطاقة بنجاح".tr,
                style: const TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "**** **** **** $last4",
                style: const TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "استخدام البطاقة".tr,
                    style: const TextStyle(fontFamily: "Cairo"),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "رجوع".tr,
                  style: const TextStyle(fontFamily: "Cairo"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

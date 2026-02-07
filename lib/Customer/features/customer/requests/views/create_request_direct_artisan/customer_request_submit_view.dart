import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerRequestSubmitView extends StatelessWidget {
  const CustomerRequestSubmitView({super.key});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);
  Color get green => const Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: green, size: 90),
                const SizedBox(height: 25),
                Text(
                  "تم إرسال طلبك بنجاح!".tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: "Cairo",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "سيقوم الحرفي بمراجعة الطلب والرد عليك قريباً.".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontFamily: "Cairo",
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
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
                      "الرجوع للرئيسية".tr,
                      style: const TextStyle(fontFamily: "Cairo", fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/contact_info_item.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/contact_input_field.dart';

class CustomerContactUsView extends StatelessWidget {
  const CustomerContactUsView({super.key});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          "تواصل معنا".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ContactInfoItem(
            label: "البريد الإلكتروني".tr,
            value: "support@usta.com",
          ),
          ContactInfoItem(
            label: "رقم الواتساب".tr,
            value: "+201000000000",
          ),
          const SizedBox(height: 20),

          ContactInputField(
            label: "الاسم".tr,
            controller: nameCtrl,
            cardColor: card,
          ),
          ContactInputField(
            label: "البريد".tr,
            controller: emailCtrl,
            cardColor: card,
          ),
          ContactInputField(
            label: "الرسالة".tr,
            controller: msgCtrl,
            maxLines: 5,
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
        ],
      ),
    );
  }
}


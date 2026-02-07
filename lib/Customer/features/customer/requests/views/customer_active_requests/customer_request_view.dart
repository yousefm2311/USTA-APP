import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/views/customer_create_request_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_service_grid.dart';

class CustomerRequestView extends StatelessWidget {
  const CustomerRequestView({super.key});

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        title: Text(
          "إنشاء طلب جديد".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "اختر نوع الخدمة".tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          RequestServiceGrid(
            primaryColor: primaryBlue,
            cardColor: cardDark,
            onServiceTap: () => Get.to(() => const CustomerCreateRequestView()),
          ),
        ],
      ),
    );
  }
}


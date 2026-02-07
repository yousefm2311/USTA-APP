import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerPaymentReceiptView extends StatelessWidget {
  const CustomerPaymentReceiptView({super.key});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "الإيصال".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:  Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: blue, size: 60),

              const SizedBox(height: 20),

              Text(
                "تمت العملية بنجاح".tr,
                style: const TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20),

              const Divider(color: Colors.white12),

              const SizedBox(height: 10),

              _row("المبلغ".tr, "450 جنيه".tr),
              _row("رقم العملية".tr, "#982741"),
              _row("التاريخ".tr, "24 ديسمبر 2025".tr),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "تم".tr,
                    style: const TextStyle(fontFamily: "Cairo", fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle( fontFamily: "Cairo"),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle( fontFamily: "Cairo"),
          ),
        ],
      ),
    );
  }
}

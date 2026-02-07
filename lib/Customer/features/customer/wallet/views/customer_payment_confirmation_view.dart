import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_payment_receipt_view.dart';

class CustomerPaymentConfirmationView extends StatelessWidget {
  const CustomerPaymentConfirmationView({super.key});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "تأكيد الدفع".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Text(
                    "المبلغ".tr,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "450 جنيه".tr,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerPaymentReceiptView(),
                    ),
                  );
                },
                
                style: ElevatedButton.styleFrom(
                
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  
                  shape: RoundedRectangleBorder(
                    
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "دفع".tr,
                  style: const TextStyle(fontFamily: "Cairo", fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


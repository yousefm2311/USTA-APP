import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/wallet/controllers/customer_wallet_controller.dart';

class CustomerWalletRechargeView extends StatefulWidget {
  const CustomerWalletRechargeView({super.key});

  @override
  State<CustomerWalletRechargeView> createState() =>
      _CustomerWalletRechargeViewState();
}

class _CustomerWalletRechargeViewState
    extends State<CustomerWalletRechargeView> {
  final TextEditingController amountCtrl = TextEditingController();
  final controller = Get.find<CustomerWalletController>();

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(
          "شحن المحفظة".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:  Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: "Cairo",
                ),
                decoration: InputDecoration(
                  labelText: "المبلغ".tr,
                  labelStyle: const TextStyle(
                    fontFamily: "Cairo",
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Spacer(),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.recharging.value
                      ? null
                      : () async {
                          final parsed =
                              num.tryParse(amountCtrl.text.trim()) ?? 0;
                          if (parsed <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'أدخل مبلغ صالح للشحن'.tr,
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            );
                            return;
                          }
                          await controller.recharge(parsed);
                          if (mounted) Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    controller.recharging.value
                        ? "جاري الشحن...".tr
                        : "تأكيد الشحن".tr,
                    style: const TextStyle(fontFamily: "Cairo", fontSize: 16,color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


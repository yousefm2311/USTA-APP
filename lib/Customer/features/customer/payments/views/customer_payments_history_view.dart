import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/payments/controllers/customer_payments_controller.dart';
import 'package:usta/Customer/features/customer/payments/views/customer_payment_receipt_view.dart';

class CustomerPaymentsHistoryView extends StatelessWidget {
  CustomerPaymentsHistoryView({super.key});

  final CustomerPaymentsController controller =
      Get.isRegistered<CustomerPaymentsController>()
      ? Get.find<CustomerPaymentsController>()
      : Get.put(CustomerPaymentsController());

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get green => const Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "سجل المدفوعات".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.payments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.payments.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchPayments,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(height: 80),
                Center(
                  child: Text(
                    'لا توجد مدفوعات حتى الآن'.tr,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchPayments,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.payments.length,
            itemBuilder: (_, i) => _item(controller.payments[i]),
          ),
        );
      }),
    );
  }

  Widget _item(Map<String, dynamic> payment) {
    final title =
        payment['title']?.toString() ??
        payment['type']?.toString() ??
        'عملية'.tr;
    final credit = _asNum(payment['credit']) ?? 0;
    final debit = _asNum(payment['debit']) ?? 0;
    final amountRaw =
        _asNum(payment['amount']) ??
        _asNum(payment['total']) ??
        (credit - debit);
    final amount = amountRaw;
    final currency = 'ج.م'.tr;
    final date =
        payment['createdAt']?.toString() ?? payment['date']?.toString() ?? '';
    final id =
        payment['_id']?.toString() ??
        payment['id']?.toString() ??
        payment['paymentId']?.toString() ??
        '';

    return InkWell(
      onTap: id.isEmpty
          ? null
          : () => Get.to(() => CustomerPaymentReceiptView(paymentId: id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.receipt_long, color: green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontFamily: "Cairo", fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              "@amount @currency".trParams({
                'amount': amount.toStringAsFixed(2),
                'currency': currency,
              }),
              style: const TextStyle(
                fontFamily: "Cairo",
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }
}

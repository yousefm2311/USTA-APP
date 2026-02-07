import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/payments/controllers/customer_payments_controller.dart';

class CustomerPaymentReceiptView extends StatelessWidget {
  const CustomerPaymentReceiptView({super.key, required this.paymentId});

  final String paymentId;

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerPaymentsController>();

    if (paymentId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "إيصال الدفع".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: Center(
          child: Text(
            'لا يوجد معرف إيصال صالح'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: Text(
          "إيصال الدفع".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: controller.fetchReceipt(paymentId),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style:
                    const TextStyle( fontFamily: 'Cairo'),
              ),
            );
          }
          final receipt = snapshot.data ?? {};
          final credit = _asNum(receipt['credit']) ?? 0;
          final debit = _asNum(receipt['debit']) ?? 0;
          final amount = _asNum(receipt['amount']) ??
              _asNum(receipt['total']) ??
              (credit - debit);
          final currency = 'ج.م'.tr;
          final meta = receipt['meta'] is Map ? receipt['meta'] as Map : {};
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row(
                    "معرّف الطلب",
                    receipt['requestId'] ?? receipt['request'] ?? '-',
                  ),
                  _row(
                    "المبلغ",
                    "@amount @currency".trParams(
                      {
                        'amount': amount.toStringAsFixed(2),
                        'currency': currency,
                      },
                    ),
                  ),
                  _row(
                    "طريقة الدفع",
                    receipt['method'] ?? receipt['paymentMethod'] ?? '-',
                  ),
                  _row("الحالة", receipt['status'] ?? '-'),
                  _row(
                    "التاريخ",
                    receipt['createdAt'] ?? receipt['date'] ?? '-',
                  ),
                  _row("إئتمان", credit.toStringAsFixed(2)),
                  _row("خصم", debit.toStringAsFixed(2)),
                  if (meta['note'] != null) _row("ملاحظة", meta['note']),
                  if (meta['fees'] != null)
                    _row("الرسوم", meta['fees'].toString()),
                  if (meta['vat'] != null)
                    _row("الضريبة", meta['vat'].toString()),
                  if (receipt['transactionId'] != null)
                    _row("معرّف المعاملة", receipt['transactionId']),
                  if (receipt['_id'] != null)
                    _row("رقم الإيصال", receipt['_id']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "${label.tr}:",
            style: const TextStyle(
              fontFamily: "Cairo",
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: TextStyle(
                fontFamily: "Cairo",
              ),
            ),
          ),
        ],
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


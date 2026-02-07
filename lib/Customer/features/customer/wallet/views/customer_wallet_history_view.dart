import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/wallet/controllers/customer_wallet_controller.dart';

class CustomerWalletHistoryView extends StatelessWidget {
  CustomerWalletHistoryView({super.key});

  final controller = Get.find<CustomerWalletController>();

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "سجل الحركات".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Obx(() {
        if (controller.loadingHistory.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.history.isEmpty) {
          return Center(
            child: Text(
              'لا يوجد حركات'.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchHistory,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.history.length,
            itemBuilder: (_, i) => _historyItem(controller.history[i]),
          ),
        );
      }),
    );
  }

  Widget _historyItem(Map<String, dynamic> item) {
    final credit = _asNum(item['credit']) ?? 0;
    final debit = _asNum(item['debit']) ?? 0;
    final rawAmount = _asNum(item['amount']) ?? _asNum(item['value']) ?? (credit - debit);
    final amount = rawAmount ?? 0;
    final isIncome = amount >= 0;
    final title =
        item['title'] ??
        item['type'] ??
        (isIncome ? 'إيداع'.tr : 'خصم'.tr);
    final date = item['createdAt'] ?? item['date'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: blue.withOpacity(.12),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.toString(),
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "@amount ج.م".trParams({'amount': amount.toStringAsFixed(2)}),
            style: TextStyle(
              fontFamily: "Cairo",
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/payments/views/customer_payments_history_view.dart';
import 'package:usta/Customer/features/customer/wallet/controllers/customer_wallet_controller.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_wallet_recharge_view.dart';

class CustomerWalletView extends StatelessWidget {
  CustomerWalletView({super.key});

  final CustomerWalletController controller =
      Get.isRegistered<CustomerWalletController>()
      ? Get.find<CustomerWalletController>()
      : Get.put(CustomerWalletController());

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text("المحفظة".tr, style: const TextStyle(fontFamily: "Cairo")),
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _balanceCard(),
            const SizedBox(height: 25),
            _sectionTitle("إجراءات"),
            const SizedBox(height: 14),
            _actionButton("شحن المحفظة", Icons.add_circle, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerWalletRechargeView(),
                ),
              );
            }),
            _actionButton("سجل الحركات", Icons.history, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerPaymentsHistoryView(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {
    final balanceText = controller.balance.value?.toStringAsFixed(2) ?? '--';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [blue.withOpacity(.9), blue.withOpacity(.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "الرصيد الحالي".tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "@amount ج.م".trParams({'amount': balanceText}),
            style: const TextStyle(
              fontFamily: "Cairo",
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.loadingBalance.value
                ? "يتم التحديث...".tr
                : "آخر تحديث".tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.tr,
      style: const TextStyle(
        fontFamily: "Cairo",
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _actionButton(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: blue),
        title: Text(title.tr, style: const TextStyle(fontFamily: "Cairo")),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/dashboard/controllers/customer_dashboard_controller.dart';
import 'package:usta/Customer/features/customer/dashboard/views/widgets/stats_card.dart';
Color get blue => const Color(0xFF2563EB);
Color get bg => const Color(0xFF050816);
Color get card => const Color(0xFF0B1020);
Color get green => const Color(0xFF22C55E);
Color get yellow => const Color(0xFFFACC15);
Color get teal => const Color(0xFF14B8A6);

String _formatNum(num? n) {
  if (n == null) return '0';
  if (n % 1 == 0) return n.toStringAsFixed(0);
  return n.toStringAsFixed(1);
}
Widget statsGrid(
  CustomerDashboardController controller,
  bool loading,
  context,
) {
  return GridView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      mainAxisExtent: 150,
    ),
    children: [
      statCard(
        "إجمالي الطلبات".tr,
        _formatNum(controller.totalRequests),
        Icons.list_alt,
        blue,
        loading,
        context,
      ),
      statCard(
        "الطلبات المكتملة".tr,
        _formatNum(controller.completedRequests),
        Icons.verified,
        green,
        loading,
        context,
      ),
      statCard(
        "الطلبات الجارية".tr,
        _formatNum(controller.pendingRequests),
        Icons.timelapse,
        yellow,
        loading,
        context,
      ),
      statCard(
        "إجمالي المدفوعات (ج م)".tr,
        _formatNum(controller.revenue),
        Icons.payments,
        teal,
        loading,
        context,
      ),
    ],
  );
}


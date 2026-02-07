import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/dashboard/controllers/customer_dashboard_controller.dart';
import 'package:usta/Customer/features/customer/dashboard/views/widgets/chart_label.dart';
import 'package:usta/Customer/features/customer/dashboard/views/widgets/customer_monthly_chart.dart';
import 'package:usta/Customer/features/customer/dashboard/views/widgets/extra_info.dart';
import 'package:usta/Customer/features/customer/dashboard/views/widgets/stats_grid.dart';

class CustomerDashboardView extends StatelessWidget {
  const CustomerDashboardView({super.key});

  Color get blue => const Color(0xFF2563EB);

  CustomerDashboardController _ctrl() {
    if (Get.isRegistered<CustomerDashboardController>()) {
      return Get.find<CustomerDashboardController>();
    }
    return Get.put(CustomerDashboardController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _ctrl();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "لوحة التحكم".tr,
            style: const TextStyle(fontFamily: "Cairo", fontSize: 17),
          ),
        ),
        body: Obx(() {
          final loadingAll =
              controller.loadingDashboard.value &&
              controller.dashboard.isEmpty &&
              controller.loadingStats.value;

          if (loadingAll) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = controller.error.value;
          final values = controller.monthValues;
          final labels = chartLabels(values.length, controller.monthLabels);

          return RefreshIndicator(
            color: blue,
            onRefresh: () async => controller.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontFamily: "Cairo",
                      ),
                    ),
                  ),
                statsGrid(controller, controller.loadingDashboard.value,context),
                const SizedBox(height: 28),
                _section("الرسوم البيانية"),
                const SizedBox(height: 14),
                CustomerMonthlyChart(
                  values: values,
                  labels: labels,
                  loading: controller.loadingStats.value,
                ),
                const SizedBox(height: 28),
                _section("معلومات إضافية"),
                const SizedBox(height: 14),
                extraInfo(controller,context),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title.tr,
      style: const TextStyle(
        fontFamily: "Cairo",
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
    );
  }
}


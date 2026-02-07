import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/complaints/controllers/customer_complaints_controller.dart';
import 'package:usta/Customer/features/customer/complaints/views/customer_complaint_create_view.dart';
import 'package:usta/Customer/features/customer/complaints/views/widgets/customer_complaints_items.dart';

class CustomerComplaintsView extends StatelessWidget {
  CustomerComplaintsView({super.key});
  final controller = Get.put(CustomerComplaintsController());
  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Color borderColor() => scheme.outlineVariant.withOpacity(0.55);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
        title: Text(
          "الدعم والشكاوى".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => CustomerComplaintCreateView()),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.complaints.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.complaints.isEmpty) {
          return RefreshIndicator(
            color: scheme.primary,
            backgroundColor: scheme.surface,
            onRefresh: controller.fetchComplaints,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'لا توجد شكاوى حالياً'.tr,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: scheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: scheme.primary,
          backgroundColor: scheme.surface,
          onRefresh: controller.fetchComplaints,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.complaints.length,
            itemBuilder: (_, i) => itemcomplaint(context, controller.complaints[i]),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        onPressed: () => Get.to(() => CustomerComplaintCreateView()),
        label: Text(
          "إنشاء شكوى".tr,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
        ),
        icon: const Icon(Icons.add,color: Colors.white,),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/active_request_card.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/active_requests_empty_state.dart';

class CustomerActiveRequestsView extends StatelessWidget {
  const CustomerActiveRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerRequestsController>();
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: scheme.surface,
          title: Text(
            "الطلبات النشطة".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: Obx(() {
          final isLoading = controller.loadingActive.value;
          final items = controller.activeRequests;

          if (isLoading && items.isEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => ShimmerSkeletons.listTile(height: 96),
            );
          }

          if (items.isEmpty) {
            return ActiveRequestsEmptyState(
              onRefresh: () => controller.fetchActiveRequests(force: true),
            );
          }

          return RefreshIndicator(
            color: scheme.primary,
            backgroundColor: scheme.surface,
            onRefresh: () => controller.fetchActiveRequests(force: true),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final req = Map<String, dynamic>.from(items[i]);
                return ActiveRequestCard(
                  request: req,
                  controller: controller,
                );
              },
            ),
          );
        }),
      ),
    );
  }
}


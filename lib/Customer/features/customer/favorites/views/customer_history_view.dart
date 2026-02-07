import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/favorites/views/widgets/history_request_card.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';

class CustomerHistoryView extends StatefulWidget {
  const CustomerHistoryView({super.key});

  @override
  State<CustomerHistoryView> createState() => _CustomerHistoryViewState();
}

class _CustomerHistoryViewState extends State<CustomerHistoryView> {
  final controller = Get.find<CustomerRequestsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHistoryRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: scheme.surface,
          title: Text(
            "النشاط الأخير".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: Obx(() {
          if (controller.loadingHistory.value &&
              controller.historyRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final combined = <Map<String, dynamic>>[];
          final seenIds = <String>{};

          void addItem(Map<String, dynamic> item) {
            final id = (item['_id'] ?? item['id'] ?? item['requestId'])
                ?.toString();
            if (id == null || id.isEmpty || seenIds.contains(id)) return;
            seenIds.add(id);
            combined.add(item);
          }

          for (final item in controller.activeRequests) {
            addItem(item);
          }
          for (final item in controller.historyRequests) {
            addItem(item);
          }

          DateTime? parseDate(dynamic v) {
            if (v is DateTime) return v;
            if (v is String && v.trim().isNotEmpty) {
              return DateTime.tryParse(v);
            }
            return null;
          }

          combined.sort((a, b) {
            final aTime =
                parseDate(a['updatedAt']) ??
                parseDate(a['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                parseDate(b['updatedAt']) ??
                parseDate(b['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          if (combined.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد نشاط حديث حتى الآن'.tr,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: scheme.onSurface.withOpacity(0.75),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: scheme.primary,
            onRefresh: () async {
              await controller.fetchActiveRequests(force: true);
              await controller.fetchHistoryRequests(force: true);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: combined.length,
              itemBuilder: (_, i) => HistoryRequestCard(item: combined[i]),
            ),
          );
        }),
      ),
    );
  }
}


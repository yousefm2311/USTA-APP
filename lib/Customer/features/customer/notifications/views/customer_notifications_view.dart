import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';

import 'customer_notification_details_view.dart';

class CustomerNotificationsView extends StatefulWidget {
  const CustomerNotificationsView({super.key});

  @override
  State<CustomerNotificationsView> createState() =>
      _CustomerNotificationsViewState();
}

class _CustomerNotificationsViewState extends State<CustomerNotificationsView> {
  final Color bg = const Color(0xFF050816);
  final Color card = const Color(0xFF0B1020);
  final Color blue = const Color(0xFF2563EB);

  late final CustomerNotificationsController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<CustomerNotificationsController>()
        ? Get.find<CustomerNotificationsController>()
        : Get.put(CustomerNotificationsController(), permanent: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "الإشعارات".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.loading.value && controller.notifications.isEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => ShimmerSkeletons.listTile(),
            );
          }

          if (controller.notifications.isEmpty) {
            return Center(
              child: Text(
                'لا توجد إشعارات حالياً'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }

          return RefreshIndicator(
            color: blue,
            onRefresh: () => controller.fetchNotifications(force: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.notifications.length,
              itemBuilder: (_, i) =>
                  _notificationItem(context, controller.notifications[i]),
            ),
          );
        }),
      ),
    );
  }

  Widget _notificationItem(BuildContext context, Map<String, dynamic> item) {
    final id = (item['_id'] ?? item['id'])?.toString() ?? '';
    final title = (item['title'] ?? 'إشعار'.tr).toString();
    final body = (item['body'] ?? '').toString();
    final read = item['read'] == true;
    final createdAt = _formatDate(item['createdAt']);
    final type = item['type']?.toString() ?? 'general';

    return InkWell(
      onTap: () {
        if (id.isNotEmpty) controller.markRead(id);

        Get.to(
          () => CustomerNotificationDetailsView(
            title: title,
            body: body,
            time: createdAt,
            type: type,
            notification: item,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: read ? Colors.white12 : blue.withOpacity(.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: blue.withOpacity(0.15),
              child: const Icon(Icons.notifications, color: Colors.blueAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    createdAt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: "Cairo",
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      if (id.isEmpty) return;
                      _confirmDelete(id);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child:  Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        IconBroken.Delete,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'حذف الإشعار'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا الإشعار؟'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          TextButton(
            onPressed: () {
              controller.remove(id);
              Get.back();
            },
            child: Text(
              'حذف'.tr,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}\n$hh:$mm';
    } catch (_) {
      return value.toString();
    }
  }
}


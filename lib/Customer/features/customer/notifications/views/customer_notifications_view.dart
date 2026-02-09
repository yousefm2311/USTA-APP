import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/core/widgets/shimmer_skeletons.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_list_view.dart';

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

          final list = _groupedNotifications(controller.notifications);
          return RefreshIndicator(
            color: blue,
            onRefresh: () => controller.fetchNotifications(force: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _notificationItem(context, list[i]),
            ),
          );
        }),
      ),
    );
  }

  Widget _notificationItem(BuildContext context, Map<String, dynamic> item) {
    final isGroup = item['__groupType'] == 'chat_group';
    final groupItems = isGroup
        ? (item['__groupItems'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList()
        : const <Map<String, dynamic>>[];
    final groupCount =
        (item['__groupCount'] is int) ? item['__groupCount'] as int : 0;
    final groupUnread =
        (item['__groupUnread'] is int) ? item['__groupUnread'] as int : 0;

    final id = (item['_id'] ?? item['id'])?.toString() ?? '';
    final title = isGroup
        ? 'محادثات'.tr + (groupCount > 0 ? ' ($groupCount)' : '')
        : (item['title'] ?? 'إشعار'.tr).toString();
    final body = isGroup
        ? ((item['body'] ?? '').toString())
        : (item['body'] ?? '').toString();
    final read = isGroup ? groupUnread == 0 : item['read'] == true;
    final createdAt = _formatDate(item['createdAt']);
    final type = isGroup ? 'chat' : (item['type']?.toString() ?? 'general');

    return InkWell(
      onTap: () {
        if (isGroup) {
          _markChatGroupRead(groupItems);
          Get.to(() => const CustomerChatListView());
          return;
        }
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
                  if (isGroup && groupUnread > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'غير مقروء: $groupUnread'.tr,
                      style: const TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
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
                      if (isGroup) {
                        _confirmDeleteChatGroup(groupItems);
                        return;
                      }
                      if (id.isEmpty) return;
                      _confirmDelete(id);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
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

  void _confirmDeleteChatGroup(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'حذف إشعارات المحادثات'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          'سيتم حذف جميع إشعارات المحادثات. هل أنت متأكد؟'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _deleteChatGroup(items);
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

  Future<void> _deleteChatGroup(List<Map<String, dynamic>> items) async {
    for (final n in items) {
      final id = (n['_id'] ?? n['id'])?.toString() ?? '';
      if (id.isNotEmpty) {
        await controller.remove(id);
      }
    }
  }

  Future<void> _markChatGroupRead(List<Map<String, dynamic>> items) async {
    for (final n in items) {
      if (_isRead(n)) continue;
      final id = (n['_id'] ?? n['id'])?.toString() ?? '';
      if (id.isNotEmpty) {
        await controller.markRead(id);
      }
    }
  }

  List<Map<String, dynamic>> _groupedNotifications(
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return const [];
    final chatItems = <Map<String, dynamic>>[];
    final otherItems = <Map<String, dynamic>>[];
    for (final item in items) {
      if (_isChatNotification(item)) {
        chatItems.add(item);
      } else {
        otherItems.add(item);
      }
    }
    if (chatItems.isEmpty) return otherItems;
    chatItems.sort((a, b) => _compareByDateDesc(a, b));
    final latest = chatItems.first;
    final unread = chatItems.where((n) => !_isRead(n)).length;
    final group = <String, dynamic>{
      '__groupType': 'chat_group',
      '__groupCount': chatItems.length,
      '__groupUnread': unread,
      '__groupItems': chatItems,
      'title': 'محادثات'.tr,
      'body': latest['body'] ?? latest['message'] ?? latest['title'] ?? '',
      'createdAt': latest['createdAt'],
      'type': 'chat',
    };
    final combined = <Map<String, dynamic>>[
      ...otherItems,
      group,
    ];
    combined.sort((a, b) => _compareByDateDesc(a, b));
    return combined;
  }

  int _compareByDateDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
    final da = _parseDate(a['createdAt']);
    final db = _parseDate(b['createdAt']);
    return db.compareTo(da);
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (raw is DateTime) return raw;
    final text = raw.toString();
    if (text.isEmpty || text == 'null') {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(text) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isRead(Map<String, dynamic> item) => item['read'] == true;

  bool _isChatNotification(Map<String, dynamic> item) {
    final payload = _normalizedPayload(item);
    final type = _normalizeType(
      _pick(payload, [
            'type',
            'category',
            'kind',
            'module',
            'event',
            'notificationType',
            'topic',
          ]) ??
          (item['type']?.toString() ?? ''),
    );
    if (type.contains('chat') || type.contains('message')) return true;
    if (_pick(payload, ['chatId', 'conversationId', 'messageId']) != null) {
      return true;
    }
    if (payload['direct'] != null || payload['isDirect'] != null) return true;
    return false;
  }

  String _normalizeType(String raw) => raw.trim().toLowerCase();

  String? _pick(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final val = payload[key];
      if (val == null) continue;
      final text = val.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  Map<String, dynamic> _normalizedPayload(Map<String, dynamic> base) {
    final merged = <String, dynamic>{};
    void add(dynamic value) {
      final map = _asMap(value);
      if (map != null) merged.addAll(map);
    }

    add(base);
    add(base['data']);
    add(base['payload']);
    add(base['meta']);
    add(base['extra']);
    return merged;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
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

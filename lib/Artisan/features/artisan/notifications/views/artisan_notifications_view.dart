// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/artisan/notifications/controllers/notifications_controller.dart';
import 'package:usta/Artisan/features/artisan/notifications/views/artisan_notification_details_view.dart';
import 'package:usta/Artisan/features/artisan/notifications/views/artisan_notifications_settings_view.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';
import 'package:usta/Artisan/features/artisan/chat/views/artisan_chat_list_view.dart';

class ArtisanNotificationsView extends StatefulWidget {
  const ArtisanNotificationsView({super.key});

  @override
  State<ArtisanNotificationsView> createState() =>
      _ArtisanNotificationsViewState();
}

class _ArtisanNotificationsViewState extends State<ArtisanNotificationsView> {
  Color get primaryBlue => const Color(0xFF2563EB);

  final NotificationsController controller =
      Get.find<NotificationsController>();
  final ArtisanRequestsController requestsController =
      Get.isRegistered<ArtisanRequestsController>()
          ? Get.find<ArtisanRequestsController>()
          : Get.put(ArtisanRequestsController(), permanent: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.notifications.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const ArtisanNotificationsSettingsView()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = _groupedNotifications(controller.notifications);
        if (list.isEmpty) {
          return Center(child: Text(AppStrings.noData.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final n = list[index];
            final isGroup = n['__groupType'] == 'chat_group';
            final groupItems = isGroup
                ? (n['__groupItems'] as List? ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .toList()
                : const <Map<String, dynamic>>[];
            final groupCount =
                (n['__groupCount'] is int) ? n['__groupCount'] as int : 0;
            final groupUnread =
                (n['__groupUnread'] is int) ? n['__groupUnread'] as int : 0;
            final title = n['title']?.toString() ?? '';
            final body = n['body']?.toString() ?? n['message']?.toString() ?? '';
            final date = _formatDate(n['createdAt']);
            final read = isGroup
                ? groupUnread == 0
                : (n['read'] == true || (n['isRead'] == true));
            final id = (n['id'] ?? n['_id'] ?? '').toString();

            return Dismissible(
              key: Key(isGroup ? 'chat_group' : (id.isNotEmpty ? id : '$index')),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              onDismissed: (_) async {
                if (isGroup) {
                  await _dismissChatGroup(groupItems);
                  return;
                }
                await controller.dismissNotification(n);
              },
              child: _notificationItem(
                title: isGroup
                    ? AppStrings.notifications.tr +
                        (groupCount > 0 ? ' ($groupCount)' : '')
                    : title,
                message: isGroup ? body : body,
                time: date,
                read: read,
                onTap: () {
                  if (isGroup) {
                    _markChatGroupRead(groupItems);
                    Get.to(() => const ArtisanChatListView());
                    return;
                  }
                  _handleTap(n, markRead: !read, id: id);
                },
              ),
            );
          },
        );
      }),
    );
  }

  Widget _notificationItem({
    required String title,
    required String message,
    required String time,
    required bool read,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: read ? Colors.white10 : primaryBlue,
            width: read ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: read ? Colors.white12 : primaryBlue.withOpacity(0.2),
              ),
              child: Icon(
                read ? Icons.notifications_none : Icons.notifications_active,
                color: read ? Colors.grey.shade500 : primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 15,
                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!read)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(
    Map<String, dynamic> notification, {
    required bool markRead,
    required String id,
  }) async {
    if (markRead && id.isNotEmpty) {
      await controller.markAsRead(id);
    }
    final baseMeta = _extractRequestMeta(notification);
    final isRequestType =
        (notification['type']?.toString().toLowerCase() ?? '').contains('request');
    _RequestMeta meta = baseMeta;
    if (meta.requestId.isEmpty && isRequestType) {
      meta = await _fallbackRequestMetaFromLists() ?? baseMeta;
    }
    final hasRequest = meta.requestId.isNotEmpty;
    if (!hasRequest) {
      _openDetails(notification, enableOpenButton: isRequestType);
      return;
    }

    Map<String, dynamic> request = meta.request;
    String status = meta.status;

    if (request.isEmpty) {
      final details =
          await requestsController.fetchRequestDetails(meta.requestId) ?? {};
      request = (details['request'] as Map?)?.cast<String, dynamic>() ??
          (details is Map<String, dynamic>
              ? details
              : <String, dynamic>{});
      status = status.isEmpty
          ? (request['status']?.toString() ?? meta.status)
          : status;
    }

    final args = {'requestId': meta.requestId, 'request': request};
    if (_isCompleted(status)) {
      Get.toNamed(AppRoutes.artisanRequestDetailsFromCompletedView,
          arguments: args);
    } else if (_isPending(status)) {
      Get.toNamed(AppRoutes.artisanAcceptRequestView, arguments: args);
    } else {
      Get.toNamed(AppRoutes.artisanRequestDetailsView, arguments: args);
    }
  }

  Future<void> _dismissChatGroup(List<Map<String, dynamic>> items) async {
    for (final n in items) {
      await controller.dismissNotification(n);
    }
  }

  Future<void> _markChatGroupRead(List<Map<String, dynamic>> items) async {
    for (final n in items) {
      if (_isRead(n)) continue;
      final id = (n['id'] ?? n['_id'] ?? '').toString();
      if (id.isNotEmpty) {
        await controller.markAsRead(id);
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
      'title': AppStrings.notifications.tr,
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

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = value is DateTime
          ? value
          : DateTime.parse(value.toString()).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}\n$hh:$mm';
    } catch (_) {
      return value.toString();
    }
  }

  bool _isRead(Map<String, dynamic> item) =>
      item['read'] == true || item['isRead'] == true;

  bool _isChatNotification(Map<String, dynamic> item) {
    final type = _normalizeType(
      (item['type'] ?? item['category'] ?? item['kind'] ?? '').toString(),
    );
    if (type.contains('chat') || type.contains('message')) return true;
    final payload = _normalizedPayload(item);
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

  void _openDetails(Map<String, dynamic> notification,
      {required bool enableOpenButton}) {
    final title = notification['title']?.toString() ?? '';
    final body = notification['body']?.toString() ??
        notification['message']?.toString() ??
        '';
    final date = notification['createdAt']?.toString() ?? '';
    final type = notification['type']?.toString() ?? '';
    Get.to(
      () => ArtisanNotificationDetailsView(
        title: title,
        body: body,
        date: date,
        type: type,
        onOpenRequest: enableOpenButton
            ? () => _handleOpenFromDetails(notification)
            : null,
      ),
    );
  }

  Future<void> _handleOpenFromDetails(Map<String, dynamic> notification) async {
    final meta = _extractRequestMeta(notification);
    final resolved = meta.requestId.isNotEmpty
        ? meta
        : (await _fallbackRequestMetaFromLists()) ?? meta;
    if (resolved.requestId.isEmpty) {
      AppSnackBar.show(
        AppStrings.error.tr,
        AppStrings.notificationsLoadFailed.tr,
        type: SnackBarType.error,
      );
      return;
    }
    await _handleTap(
      notification,
      markRead: false,
      id: (notification['id'] ?? notification['_id'] ?? '').toString(),
    );
  }

  Future<_RequestMeta?> _fallbackRequestMetaFromLists() async {
    try {
      await requestsController.fetchNewRequests();
      await requestsController.fetchActiveRequests();
      await requestsController.fetchHistoryRequests();
      Map<String, dynamic>? pick;
      String status = '';
      if (requestsController.newRequests.isNotEmpty) {
        pick = requestsController.newRequests.first;
        status = pick['status']?.toString() ?? 'new';
      } else if (requestsController.activeRequests.isNotEmpty) {
        pick = requestsController.activeRequests.first;
        status = pick['status']?.toString() ?? 'active';
      } else if (requestsController.historyRequests.isNotEmpty) {
        pick = requestsController.historyRequests.first;
        status = pick['status']?.toString() ?? 'history';
      }
      if (pick == null) return null;
      final rid =
          (pick['_id'] ?? pick['id'] ?? pick['requestId'] ?? '').toString();
      if (rid.isEmpty) return null;
      return _RequestMeta(
        requestId: rid,
        status: status,
        request: pick,
      );
    } catch (_) {
      return null;
    }
  }

  _RequestMeta _extractRequestMeta(Map<String, dynamic> n) {
    Map<String, dynamic> normalize(dynamic v) =>
        v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

    final requestMap = normalize(
      n['request'] ??
          n['data'] ??
          n['meta'] ??
          (n['payload'] is Map ? n['payload'] : null),
    );

    String pickId() {
      final candidates = [
        n['requestId'],
        n['request_id'],
        n['request'],
        n['requestID'],
        requestMap['requestId'],
        requestMap['_id'],
        requestMap['id'],
        requestMap['request_id'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString();
        if (s.isNotEmpty && s.length >= 4) return s;
      }
      return '';
    }

    String pickStatus() {
      final candidates = [
        n['status'],
        n['requestStatus'],
        requestMap['status'],
        requestMap['state'],
        requestMap['requestStatus'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    return _RequestMeta(
      requestId: pickId(),
      status: pickStatus(),
      request: requestMap,
    );
  }

  bool _isCompleted(String status) {
    final s = status.toLowerCase();
    return ['completed', 'done', 'closed', 'cancelled', 'canceled', 'rejected']
        .contains(s);
  }

  bool _isPending(String status) {
    final s = status.toLowerCase();
    return s.isEmpty || s == 'new' || s == 'assigned' || s == 'pending';
  }
}

class _RequestMeta {
  final String requestId;
  final String status;
  final Map<String, dynamic> request;
  const _RequestMeta({
    required this.requestId,
    required this.status,
    required this.request,
  });
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_list_view.dart';
import 'package:usta/Customer/features/customer/chat/views/customer_chat_room_view.dart';
import 'package:usta/Customer/features/customer/payments/views/customer_payment_receipt_view.dart';
import 'package:usta/Customer/features/customer/payments/views/customer_payments_history_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_active_requests_view.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_request_details_view.dart';
import 'package:usta/Customer/features/customer/wallet/views/customer_wallet_view.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerNotificationDetailsView extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final String type;
  final Map<String, dynamic>? notification;

  const CustomerNotificationDetailsView({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.notification,
  });

  Color get darkBg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            "تفاصيل الإشعار".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
          actions: [
            IconButton(
              tooltip: "نسخ".tr,
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () async {
                final text = '$title\n\n$body\n\n$time';
                await Clipboard.setData(ClipboardData(text: text));
                AppSnackBar.show(
                  'تم النسخ'.tr,
                  'تم نسخ تفاصيل الإشعار'.tr,
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: blue.withOpacity(0.15),
                      child: Icon(
                        _iconForType(_normalizeType(type)),
                        size: 28,
                        color: blue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: "Cairo",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _typeChip(type),
                const SizedBox(height: 18),
                SelectableText(
                  body.isNotEmpty ? body : "—",
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (_hasAction())
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _actionLabel(),
                        style: TextStyle(
                          fontFamily: "Cairo",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    final label = _labelForType(_normalizeType(type));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: "Cairo",
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'request':
      case 'requests':
      case 'order':
      case 'orders':
        return 'طلبات'.tr;
      case 'payment':
      case 'payments':
        return 'مدفوعات'.tr;
      case 'wallet':
        return 'محفظة'.tr;
      case 'chat':
        return 'محادثات'.tr;
      case 'system':
        return 'النظام'.tr;
      default:
        return 'عام'.tr;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'request':
      case 'requests':
      case 'order':
      case 'orders':
        return Icons.assignment;
      case 'payment':
      case 'payments':
        return Icons.payments;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'chat':
        return IconBroken.Chat;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }
  bool _hasAction() {
    final payload = _normalizedPayload();
    final route = _pick(payload, ['route', 'screen', 'path', 'deepLink']) ?? '';
    if (route.isNotEmpty) return true;

    final normalizedType = _normalizeType(_pick(payload, ['type']) ?? type);
    switch (normalizedType) {
      case 'request':
      case 'requests':
      case 'order':
      case 'orders':
      case 'chat':
      case 'payment':
      case 'payments':
      case 'wallet':
        return true;
      default:
        return false;
    }
  }

  String _actionLabel() {
    final payload = _normalizedPayload();
    final normalizedType = _normalizeType(_pick(payload, ['type']) ?? type);
    final hasRequestId = _requestIdFrom(payload).isNotEmpty;
    final hasPaymentId = _paymentIdFrom(payload).isNotEmpty;
    final hasChatTarget = _chatTargetFrom(payload).isNotEmpty;

    switch (normalizedType) {
      case 'request':
      case 'requests':
      case 'order':
      case 'orders':
        return hasRequestId ? 'فتح الطلب'.tr : 'الطلبات النشطة'.tr;
      case 'chat':
        return hasChatTarget ? 'فتح المحادثة'.tr : 'قائمة المحادثات'.tr;
      case 'payment':
      case 'payments':
        return hasPaymentId ? 'عرض الإيصال'.tr : 'سجل المدفوعات'.tr;
      case 'wallet':
        return 'فتح المحفظة'.tr;
      default:
        return 'فتح التفاصيل'.tr;
    }
  }

  void _handleAction() {
    final payload = _normalizedPayload();
    final route = _pick(payload, ['route', 'screen', 'path', 'deepLink']) ?? '';
    final id = _pick(payload, [
      'id',
      'requestId',
      'request',
      'orderId',
      'paymentId',
      'chatId',
      'conversationId',
      'artisanId',
    ]) ??
    '';

    if (route.isNotEmpty) {
      try {
        Get.toNamed(route, arguments: {'id': id, 'data': payload});
        return;
      } catch (_) {
      }
    }

    final normalizedType = _normalizeType(_pick(payload, ['type']) ?? type);
    switch (normalizedType) {
      case 'request':
      case 'requests':
      case 'order':
      case 'orders':
        final requestId = _requestIdFrom(payload);
        if (requestId.isNotEmpty) {
          Get.to(() => CustomerRequestDetailsView(requestId: requestId));
        } else {
          Get.to(() => const CustomerActiveRequestsView());
        }
        return;

      case 'chat':
        final direct = _isDirectChat(payload);
        final name =
            _pick(payload, ['name', 'artisanName', 'customerName', 'title']) ??
            'محادثة'.tr;
        final requestId = _requestIdFrom(payload);
        final artisanId = _artisanIdFrom(payload);
        if (direct && artisanId.isNotEmpty) {
          Get.to(
            () => CustomerChatRoomView(
              requestId: '',
              customerId: artisanId,
              customerName: name,
              isDirect: true,
            ),
          );
          return;
        }
        if (requestId.isNotEmpty) {
          Get.to(
            () => CustomerChatRoomView(
              requestId: requestId,
              customerName: name,
            ),
          );
          return;
        }
        Get.to(() => const CustomerChatListView());
        return;

      case 'payment':
      case 'payments':
        final paymentId = _paymentIdFrom(payload);
        if (paymentId.isNotEmpty) {
          Get.to(() => CustomerPaymentReceiptView(paymentId: paymentId));
        } else {
          Get.to(() => CustomerPaymentsHistoryView());
        }
        return;

      case 'wallet':
        Get.to(() => CustomerWalletView());
        return;

      default:
        AppSnackBar.show('تنبيه'.tr, 'لا يوجد رابط لهذا الإشعار'.tr);
        return;
    }
  }

  String _normalizeType(String raw) => raw.trim().toLowerCase();

  String _requestIdFrom(Map<String, dynamic> payload) =>
      _pick(payload, ['requestId', 'request_id', 'request', 'orderId']) ?? '';

  String _paymentIdFrom(Map<String, dynamic> payload) =>
      _pick(payload, ['paymentId', 'payment_id', 'receiptId', 'transactionId']) ??
      '';

  String _chatTargetFrom(Map<String, dynamic> payload) =>
      _pick(payload, ['chatId', 'conversationId', 'requestId', 'artisanId']) ?? '';

  String _artisanIdFrom(Map<String, dynamic> payload) =>
      _pick(payload, ['artisanId', 'artisan_id', 'otherId', 'customerId']) ?? '';

  bool _isDirectChat(Map<String, dynamic> payload) {
    final v = payload['isDirect'] ?? payload['direct'] ?? payload['chatType'];
    if (v is bool) return v;
    return v?.toString().toLowerCase() == 'direct';
  }

  String? _pick(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final val = payload[key];
      if (val == null) continue;
      final text = val.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  Map<String, dynamic> _normalizedPayload() {
    final merged = <String, dynamic>{};
    void add(dynamic value) {
      final map = _asMap(value);
      if (map != null) merged.addAll(map);
    }

    add(notification);
    if (notification != null) {
      add(notification!['data']);
      add(notification!['payload']);
      add(notification!['meta']);
      add(notification!['extra']);
    }

    return merged;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return null;
  }
}



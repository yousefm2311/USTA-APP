import 'package:flutter/material.dart';
import 'package:get/get.dart';

Color get blue => const Color(0xFF2563EB);

String _formatTime(String? value) {
  if (value == null) return '';
  final dt = DateTime.tryParse(value);
  if (dt == null) return value;
  String two(int v) => v.toString().padLeft(2, '0');
  return "${two(dt.hour)}:${two(dt.minute)}";
}

Widget messageBubbleDetailsView(Map<String, dynamic> msg) {
  final text = msg['message']?.toString() ?? msg['text']?.toString() ?? '';
  final senderType =
      msg['senderType']?.toString() ?? msg['from']?.toString() ?? '';
  final senderLabel = senderType == 'admin'
      ? 'الدعم'.tr
      : senderType == 'customer'
      ? 'أنت'.tr
      : 'غير معروف'.tr;
  final isMe = senderType == 'customer';
  final createdAtRaw = msg['createdAt']?.toString();
  final createdAt = _formatTime(createdAtRaw);

  return Align(
    alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? blue.withOpacity(0.15)
            : Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontFamily: "Cairo")),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                senderLabel,
                style: const TextStyle(fontFamily: "Cairo", fontSize: 12),
              ),
              const Spacer(),
              Text(
                createdAt,
                style: const TextStyle(fontFamily: "Cairo", fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

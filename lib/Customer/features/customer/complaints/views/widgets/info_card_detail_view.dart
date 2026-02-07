import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget infoCardDetailsView(BuildContext context,Map<String, dynamic> complaint) {
  final issue = complaint['issue']?.toString() ?? '';
  final status =
      (complaint['statusLabel']?.toString() ??
              complaint['status']?.toString() ??
              'غير معروف')
          .tr;
  final artisan = complaint['artisan'] ?? complaint['artisanId'];
  final request = complaint['request'] ?? complaint['requestId'];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          issue,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Chip(
              label: Text(status, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.white10,
              labelStyle: const TextStyle(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (artisan != null)
                    Text(
                      'الحرفي: @name'.trParams({'name': artisan.toString()}),
                      style: const TextStyle(fontFamily: 'Cairo'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (request != null)
                    Text(
                      'الطلب: @id'.trParams({'id': request.toString()}),
                      style: const TextStyle(fontFamily: 'Cairo'),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

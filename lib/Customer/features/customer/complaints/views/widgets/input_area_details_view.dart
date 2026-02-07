import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget inputAreaDetailsView(
  BuildContext context,
  msgCtrl,
  complaintId,
  controller,
  blue,
) {
  Future<void> _send() async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;
    await controller.sendMessage(complaintId, text);
    msgCtrl.clear();
  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(top: BorderSide(color: Colors.white12)),
    ),
    child: SafeArea(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: msgCtrl,
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: "اكتب رسالتك...".tr,
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => IconButton(
              onPressed: controller.sending.value ? null : _send,
              icon: controller.sending.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send, color: blue),
            ),
          ),
        ],
      ),
    ),
  );
}

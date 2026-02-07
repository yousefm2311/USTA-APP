import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePasswordField extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const ProfilePasswordField({
    super.key,
    required this.title,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'هذا الحقل مطلوب'.tr;
              if (v.trim().length < 6) return 'الحد الأدنى 6 حروف'.tr;
              return null;
            },
            style: const TextStyle(fontFamily: "Cairo"),
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

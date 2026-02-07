import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerPrivacyPolicyView extends StatelessWidget {
  const CustomerPrivacyPolicyView({super.key});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  static const String _policyKey = 'privacy_policy_text';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          "سياسة الخصوصية".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          _policyKey.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            color: Colors.white70,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

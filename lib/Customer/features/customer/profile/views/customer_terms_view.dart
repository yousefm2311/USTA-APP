import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerTermsView extends StatelessWidget {
  const CustomerTermsView({super.key});

  Color get bg => const Color(0xFF050816);
  static const String _termsKey = 'terms_text';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          "الشروط والأحكام".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          _termsKey.tr,
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

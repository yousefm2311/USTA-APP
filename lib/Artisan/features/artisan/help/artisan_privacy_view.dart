import 'package:flutter/material.dart';

class ArtisanPrivacyView extends StatelessWidget {
  const ArtisanPrivacyView({super.key});

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "سياسة الخصوصية",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Text(
            "يتم احترام جميع بيانات المستخدمين..."
            "\n\n- لن نشارك بياناتك مع أي طرف خارجي."
            "\n- نستخدم معلوماتك لتحسين الخدمة فقط."
            "\n- تقدر تطلب حذف حسابك في أي وقت.",
            style: TextStyle(
              fontFamily: "Cairo",
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

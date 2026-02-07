import 'package:flutter/material.dart';

class ArtisanTermsView extends StatelessWidget {
  const ArtisanTermsView({super.key});

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "الشروط والأحكام",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Text(
            "باستخدام التطبيق فأنت توافق على:"
            "\n\n- التعامل باحتراف واحترام مع العملاء."
            "\n- الالتزام بالسعر المتفق عليه."
            "\n- تقديم الخدمة بجودة عالية.",
            style: TextStyle(
              fontFamily: "Cairo",
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

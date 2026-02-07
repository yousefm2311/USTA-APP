import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class ArtisanAboutView extends StatelessWidget {
  const ArtisanAboutView({super.key});

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "عن التطبيق",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child:  Text(
            "Usta – تطبيق لربط العملاء بالحرفيين بسهولة وسرعة.\n\n"
            "الإصدار: 1.0.0\n"
            "تطوير: يوسف ♥",
            textAlign: TextAlign.center,
            style:  AppTextStyles.body(context)
          ),
        ),
      ),
    );
  }
}


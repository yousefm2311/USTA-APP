import 'package:flutter/material.dart';

class ArtisanAboutView extends StatelessWidget {
  const ArtisanAboutView({super.key});

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "عن التطبيق",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Icon(Icons.handyman, size: 60, color: primaryBlue),
              const SizedBox(height: 20),

              const Text(
                "USTA - منصة تربط بين العملاء وأفضل الحرفيين بسهولة وأمان.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Cairo",
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "الإصدار 1.0.0",
                style: TextStyle(fontFamily: "Cairo", color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class ArtisanPrivacyView extends StatelessWidget {
  ArtisanPrivacyView({super.key});

  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "الخصوصية وكلمة المرور",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _input("كلمة المرور الحالية", currentPassword, context),
          const SizedBox(height: 16),
          _input("كلمة المرور الجديدة", newPassword, context),
          const SizedBox(height: 16),
          _input("تأكيد كلمة المرور", confirmPassword, context),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child:  Text(
              "تغيير كلمة المرور",
              style: AppTextStyles.body(context).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, context) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.body(context),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        border: Theme.of(context).inputDecorationTheme.border,
      ),
    );
  }
}


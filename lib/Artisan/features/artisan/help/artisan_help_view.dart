import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_complaints_view.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_faq_view.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_terms_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_about_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_privacy_view.dart';

class ArtisanHelpView extends StatelessWidget {
  const ArtisanHelpView({super.key});

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "المساعدة والدعم",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _helpItem(
            Icons.help_center,
            "الأسئلة الشائعة",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtisanFAQView()),
            ),
            context,
          ),
          _helpItem(
            Icons.support_agent,
            "الشكاوى والتواصل مع الدعم",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtisanComplaintsView()),
            ),
            context,
          ),
          _helpItem(
            Icons.privacy_tip,
            "سياسة الخصوصية",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ArtisanPrivacyView()),
            ),
            context,
          ),
          _helpItem(
            Icons.article,
            "الشروط والأحكام",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtisanTermsView()),
            ),
            context,
          ),
          _helpItem(
            Icons.info,
            "من نحن",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtisanAboutView()),
            ),
            context,
          ),
        ],
      ),
    );
  }

  Widget _helpItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: primaryBlue, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body(context),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}


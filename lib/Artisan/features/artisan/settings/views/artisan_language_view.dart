import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/locale_controller.dart';

class ArtisanLanguageView extends StatelessWidget {
  ArtisanLanguageView({super.key});

  final LocaleController controller = Get.find<LocaleController>(tag: 'artisan');

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.language.tr,
          style: AppTextStyles.title(context),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final selected = controller.locale.value.languageCode;
        return Column(
          children: [
            _langItem(AppStrings.ar_lang.tr, "ar", selected, context),
            _langItem(AppStrings.en_lang.tr, "en", selected, context),
          ],
        );
      }),
    );
  }

  Widget _langItem(String title, String code, String selected, context) {
    return InkWell(
      onTap: () => controller.changeLocale(Locale(code)),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected == code ? primaryBlue : Colors.white12,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.body(context),
          ),
        ),
      ),
    );
  }
}


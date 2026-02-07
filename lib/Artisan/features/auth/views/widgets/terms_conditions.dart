import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/text_button.dart';

class TermsConditions extends StatelessWidget {
  const TermsConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          AppStrings.termsandconditions.tr,
          style: const TextStyle(fontSize: 12),
        ),
        CustomTextButton(
          text: AppStrings.terms.tr,
          onPressed: () {},
          fontSize: 12,
          textColor: Colors.lightBlue,
          fontWeight: FontWeight.w400,
        ),
        Text(
          ' ${AppStrings.and.tr} ',
          style: const TextStyle(fontSize: 12),
        ),
        CustomTextButton(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          text: AppStrings.conditions.tr,
          onPressed: () {},
          fontSize: 12,
          textColor: Colors.lightBlue,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }
}


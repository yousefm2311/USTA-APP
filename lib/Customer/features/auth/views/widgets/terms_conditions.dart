import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/widgets/text_button.dart';

import 'package:usta/Customer/features/auth/views/legal/privacy_policy_view.dart';
import 'package:usta/Customer/features/auth/views/legal/terms_conditions_view.dart';

class TermsConditions extends StatelessWidget {
  const TermsConditions({
    super.key,
    this.alignment = WrapAlignment.center,
    this.crossAxisAlignment = WrapCrossAlignment.center,
    this.showPrefix = true,
  });

  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final bool showPrefix;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (showPrefix)
          Text(
            AppStrings.termsandconditions.tr,
            style: const TextStyle(fontSize: 12),
          ),
        if (showPrefix) const SizedBox(width: 4),
        CustomTextButton(
          padding: EdgeInsets.zero,
          text: AppStrings.terms.tr,
          onPressed: () {
            Get.to(const TermsConditionsView());
          },
          fontSize: 12,
          textColor: Colors.lightBlue,
          fontWeight: FontWeight.w400,
        ),
        Text(
          ' ${AppStrings.and.tr} ',
          style: const TextStyle(fontSize: 12),
        ),
        CustomTextButton(
          padding: EdgeInsets.zero,
          text: AppStrings.conditions.tr,
          onPressed: () {
            Get.to(const PrivacyPolicyView());
          },
          fontSize: 12,
          textColor: Colors.lightBlue,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }
}


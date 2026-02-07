// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class OnBoardingPageViewItems extends StatelessWidget {
  const OnBoardingPageViewItems({
    super.key,
    required this.index,
    required this.model,
  });

  final int index;
  final model;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          model.image,
          height: MediaQuery.sizeOf(context).height * .4,

        ),
        const SizedBox(height: 20.0),
        Text(
          model.title,
          textAlign: TextAlign.center,
          style: AppTextStyles.title(context),
        ),
        const SizedBox(height: 20.0),
        Text(
          model.description,
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


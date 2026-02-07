import 'package:flutter/material.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';

class TextPartition extends StatelessWidget {
  const TextPartition({super.key, required this.title, required this.subtitle, required this.userText});

  final String title;
  final String subtitle;
  final String userText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.headline.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            Text(
              userText,
              style: AppTextStyles.headline.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(children: [Text(subtitle, style: AppTextStyles.body)]),
      ],
    );
  }
}


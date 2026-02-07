import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class TextPartition extends StatelessWidget {
  const TextPartition({super.key, required this.title, required this.subtitle, required this.artisnaText});

  final String title;
  final String subtitle;
  final String artisnaText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.headline(context).copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            Text(
              artisnaText,
              style: AppTextStyles.headline(
                context,
              ).copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(children: [Text(subtitle, style: AppTextStyles.body(context))]),
      ],
    );
  }
}


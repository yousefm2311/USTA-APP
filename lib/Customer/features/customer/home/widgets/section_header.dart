import 'package:flutter/material.dart';
import 'package:usta/Customer/features/customer/home/theme/home_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(title, style: AppText.section);
    return Row(
      children: [
        Expanded(
          child: onTap == null
              ? text
              : InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: text,
                  ),
                ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class HeaderActionPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const HeaderActionPill({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontFamily: AppText.font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


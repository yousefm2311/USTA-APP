import 'package:flutter/material.dart';

class AppColors {
  static const darkBg = Color(0xFF050816);
  static const cardDark = Color(0xFF0B1020);
  static const primaryBlue = Color(0xFF2563EB);
  static const accentGreen = Color(0xFF22C55E);

  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6);

  static Color subtle(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}

class AppText {
  static const String font = "Cairo";

  static const title = TextStyle(
    fontFamily: font,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const subtitle = TextStyle(
    fontFamily: font,
    fontSize: 13,
    height: 1.2,
  );

  static const section = TextStyle(
    fontFamily: font,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    fontFamily: font,
    fontSize: 12,
    height: 1.2,
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.border(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
      ),
      child: child,
    );
  }
}

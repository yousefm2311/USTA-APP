import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle headline(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.3,
        letterSpacing: 0.5,
        fontFamily: 'Cairo',
      );

  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        fontFamily: 'Cairo',
      );



  static TextStyle body(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(fontSize: 16, height: 1.5, fontFamily: 'Cairo');

  static TextStyle small(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall!
      .copyWith(fontSize: 14, height: 1.4, fontFamily: 'Cairo');

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
        fontSize: 12,
        height: 1.3,
        fontFamily: 'Cairo',
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      );

  static TextStyle primary(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color ?? Theme.of(context).colorScheme.primary,
        fontFamily: 'Cairo',
      );

  static TextStyle whiteBold(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium!
      .copyWith(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo');

  static TextStyle italic(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium!
      .copyWith(fontSize: 16, fontStyle: FontStyle.italic, fontFamily: 'Cairo');

  static TextStyle underline(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 16,
        decoration: TextDecoration.underline,
        color: Theme.of(context).colorScheme.primary,
        fontFamily: 'Cairo',
      );
}

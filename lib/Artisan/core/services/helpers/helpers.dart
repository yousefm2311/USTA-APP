import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';

class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color background = Colors.black,
  }) {
    AppSnackBar.show(
      '',
      message,
      backgroundColor: background,
      colorText: Colors.white,
    );
  }
}


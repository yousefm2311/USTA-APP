import 'package:flutter/material.dart';

class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color background = Colors.black,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: background,
      ),
    );
  }
}

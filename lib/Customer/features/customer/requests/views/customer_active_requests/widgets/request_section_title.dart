import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestSectionTitle extends StatelessWidget {
  const RequestSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.tr,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

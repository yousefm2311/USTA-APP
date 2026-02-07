import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExploreFilterSectionTitle extends StatelessWidget {
  final String text;
  const ExploreFilterSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.tr,
      style: const TextStyle(
        fontFamily: "Cairo",
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

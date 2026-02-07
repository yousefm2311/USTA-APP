import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ArtisanSectionTitle extends StatelessWidget {
  final String title;
  const ArtisanSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.tr,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

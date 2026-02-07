import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExploreSectionTitle extends StatelessWidget {
  final String title;
  const ExploreSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.tr,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RateAppStarRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onSelect;

  const RateAppStarRow({
    super.key,
    required this.rating,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => IconButton(
          onPressed: () => onSelect(i + 1),
          icon: Icon(
            Icons.star,
            size: 40,
            color: (i < rating) ? Colors.amber : Colors.white24,
          ),
        ),
      ),
    );
  }
}

class RateAppReviewBox extends StatelessWidget {
  final TextEditingController controller;
  final Color cardColor;

  const RateAppReviewBox({
    super.key,
    required this.controller,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "أخبرنا بتجربتك...".tr,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}

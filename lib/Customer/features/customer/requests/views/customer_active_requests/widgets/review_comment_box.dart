import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewCommentBox extends StatelessWidget {
  const ReviewCommentBox({
    super.key,
    required this.controller,
    required this.cardColor,
  });

  final TextEditingController controller;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: const TextStyle(color: Colors.white, fontFamily: "Cairo"),
        decoration: InputDecoration(
          hintText: "اكتب تعليقك...".tr,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontFamily: "Cairo",
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

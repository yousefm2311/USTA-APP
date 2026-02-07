import 'package:flutter/material.dart';

class ContactInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final Color cardColor;

  const ContactInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.cardColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: "Cairo", color: Colors.white70),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontFamily: "Cairo"),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

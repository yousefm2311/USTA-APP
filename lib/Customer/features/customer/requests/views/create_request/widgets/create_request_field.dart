import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateRequestField extends StatelessWidget {
  const CreateRequestField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboard,
        style: const TextStyle(fontFamily: "Cairo"),
        validator: validator,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          labelText: label.tr,
          labelStyle: const TextStyle(),
          hintText: hint.tr,
          hintStyle: const TextStyle(),
          border: InputBorder.none,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

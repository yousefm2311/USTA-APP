import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DeleteAccountWarningCard extends StatelessWidget {
  final Color borderColor;

  const DeleteAccountWarningCard({super.key, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تنبيه هام'.tr,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم حذف حسابك نهائيًا وجميع بياناتك المرتبطة به.\n'
                    'لا يمكن التراجع عن هذا الإجراء بأي شكل.\n\n'
                    'لتأكيد الحذف، اكتب كلمة DELETE في الحقل بالأسفل.'
                .tr,
            style: const TextStyle(
              fontFamily: 'Cairo',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteAccountConfirmField extends StatelessWidget {
  final TextEditingController controller;
  final Color focusColor;

  const DeleteAccountConfirmField({
    super.key,
    required this.controller,
    required this.focusColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
      ],
      style: const TextStyle(
        fontFamily: 'Cairo',
        letterSpacing: 1.5,
      ),
      decoration: InputDecoration(
        hintText: 'اكتب DELETE لتأكيد الحذف'.tr,
        hintStyle: const TextStyle(
          fontFamily: 'Cairo',
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: focusColor),
        ),
      ),
    );
  }
}

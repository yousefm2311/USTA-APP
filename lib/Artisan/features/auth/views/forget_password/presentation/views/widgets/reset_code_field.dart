import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class ResetCodeField extends StatelessWidget {
  final ValueChanged<String>? onSubmit;
  final ValueChanged<String>? onChanged;
  final Color? borderColor;
  const ResetCodeField({
    super.key,
    this.onSubmit,
    this.onChanged,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return OtpTextField(
      numberOfFields: 6,
      fieldWidth: 42,
      borderColor: borderColor ?? const Color(0xFF512DA8),
      showFieldAsBox: true,
      onCodeChanged: onChanged,
      onSubmit: onSubmit,
    );
  }
}

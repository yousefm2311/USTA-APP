import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:usta/Customer/core/utils/constants/app_colors.dart';

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
    final resolvedBorder = borderColor ?? AppColors.primary;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: OtpTextField(
        numberOfFields: 6,
        fieldWidth: 42,
        borderColor: resolvedBorder,
        enabledBorderColor: resolvedBorder,
        focusedBorderColor: resolvedBorder,
        showFieldAsBox: true,
        onCodeChanged: onChanged,
        onSubmit: onSubmit,
      ),
    );
  }
}


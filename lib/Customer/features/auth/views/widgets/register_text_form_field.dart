import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:usta/Customer/core/services/validators.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:get/get.dart';

import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/core/utils/widgets/text_form_field.dart';

// ignore: must_be_immutable
class RegisterTextFormField extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  const RegisterTextFormField({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
  });

  @override
  State<RegisterTextFormField> createState() => _RegisterTextFormFieldState();
}

class _RegisterTextFormFieldState extends State<RegisterTextFormField> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: CustomTextField(
            label: '',
            controller: widget.nameController,
            validator: (value) => Validators.name(value),
            hint: AppStrings.name.tr,
            prefixIcon: IconBroken.Profile,
            keyboardType: TextInputType.text,
            fillColor: const Color(0x0ff7f7f7),
          ),
        ),
        FadeInUp(
          duration: const Duration(milliseconds: 450),
          delay: const Duration(milliseconds: 50),
          child: CustomTextField(
            label: '',
            controller: widget.emailController,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              return Validators.email(value);
            },
            hint: AppStrings.email.tr,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            fillColor: const Color(0x0ff7f7f7),
          ),
        ),
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 200),
          child: CustomTextField(
            label: '',
            controller: widget.phoneController,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              return Validators.phone(value);
            },
            hint: AppStrings.phone.tr,
            prefixIcon: IconBroken.Call,
            keyboardType: TextInputType.phone,
            fillColor: const Color(0x0ff7f7f7),
          ),
        ),
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 300),
          child: CustomTextField(
            label: '',
            controller: widget.passwordController,
            validator: (value) => Validators.strongPassword(value),
            hint: AppStrings.password.tr,
            prefixIcon: IconBroken.Lock,
            keyboardType: TextInputType.visiblePassword,
            fillColor: const Color(0x0ff7f7f7),
            suffixIcon: _isVisible ? Icons.visibility : Icons.visibility_off,
            obscureText: _isVisible,
            onSuffixTap: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
          ),
        ),
      ],
    );
  }
}


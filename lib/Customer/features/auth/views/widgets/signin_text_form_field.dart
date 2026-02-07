import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/validators.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/core/utils/widgets/text_form_field.dart';

// ignore: must_be_immutable
class SignInTextFormField extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool showPhone;
  const SignInTextFormField({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    this.showPhone = true,
  });

  @override
  State<SignInTextFormField> createState() => _SignInTextFormFieldState();
}

class _SignInTextFormFieldState extends State<SignInTextFormField> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: CustomTextField(
            label: '',
            controller: widget.emailController,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              return Validators.email(value);
            },
            hint: AppStrings.email.tr,
            prefixIcon: IconBroken.Profile,
            keyboardType: TextInputType.emailAddress,
            fillColor: const Color(0x0ff7f7f7),
          ),
        ),
        // if (widget.showPhone) ...[
        //   const SizedBox(height: 12),
        //   FadeInUp(
        //     duration: const Duration(milliseconds: 550),
        //     delay: const Duration(milliseconds: 80),
        //     child: CustomTextField(
        //       label: '',
        //       controller: widget.phoneController,
        //       validator: (value) {
        //         if (value == null || value.isEmpty) return null;
        //         return Validators.phone(value);
        //       },
        //       hint: AppStrings.phone.tr,
        //       prefixIcon: IconBroken.Call,
        //       keyboardType: TextInputType.phone,
        //       fillColor: const Color(0x0ff7f7f7),
        //     ),
        //   ),
        // ],

        FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 150),
          child: CustomTextField(
            label: '',
            controller: widget.passwordController,
            validator: (value) => Validators.password(value),
            fillColor: const Color(0x0ff7f7f7),
            hint: AppStrings.password.tr,
            prefixIcon: IconBroken.Lock,
            keyboardType: TextInputType.visiblePassword,
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


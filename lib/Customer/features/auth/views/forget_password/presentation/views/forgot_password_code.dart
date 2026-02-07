import 'dart:async';

import 'package:flutter/material.dart';
import 'package:usta/Customer/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Customer/core/services/functions/navigator.dart';
import 'package:usta/Customer/core/utils/constants/app_colors.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';

import 'package:usta/Customer/core/utils/routes/routes.dart';

import 'package:usta/Customer/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Customer/core/utils/widgets/text_button.dart';
import 'package:usta/Customer/features/auth/views/forget_password/presentation/views/widgets/reset_code_field.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';


class ForgotPasswordCode extends StatefulWidget {
  const ForgotPasswordCode({super.key});

  @override
  State<ForgotPasswordCode> createState() => _ForgotPasswordCodeState();
}

class _ForgotPasswordCodeState extends State<ForgotPasswordCode> {
  final formKey = GlobalKey<FormState>();
  final authController = Get.find<AuthController>(tag: 'customer');
  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;
  Color _codeBorderColor = AppColors.border;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsRemaining = seconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsRemaining = 0;
        });
      } else {
        setState(() {
          _resendSecondsRemaining -= 1;
        });
      }
    });
  }

  Future<void> _handleResend() async {
    if (_resendSecondsRemaining > 0 ||
        authController.isRequestInFlight.value) {
      return;
    }
    final sent =
        await authController.sendForgotPassword(navigateToCode: false);
    if (!mounted) return;
    if (sent) {
      _startResendCooldown();
    }
  }

  Future<void> _handleVerify() async {
    if (authController.codeCtrl.text.trim().isEmpty ||
        authController.isRequestInFlight.value ||
        _isNavigating) {
      return;
    }
    if (!authController.validateForgotPasswordCode()) {
      if (!mounted) return;
      setState(() => _codeBorderColor = AppColors.error);
      return;
    }
    final success = await authController.verifyForgotPasswordCode();
    if (!mounted) return;
    setState(() {
      _codeBorderColor = success ? AppColors.success : AppColors.error;
    });
    if (!success) return;
    _isNavigating = true;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    pushNamedRoute(AppRoutes.setnewPassword);
  }

  @override
  Widget build(BuildContext context) {
    final size = AppMediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.checkemail.tr, style: AppTextStyles.title),
                const SizedBox(height: 20),
                Text(AppStrings.checkemailbody.tr, style: AppTextStyles.small),
                const SizedBox(height: 20),
                ResetCodeField(
                  onSubmit: (code) => authController.codeCtrl.text = code,
                  onChanged: (code) {
                    authController.codeCtrl.text = code;
                    if (_codeBorderColor != AppColors.border) {
                      setState(() {
                        _codeBorderColor = AppColors.border;
                      });
                    }
                  },
                  borderColor: _codeBorderColor,
                ),
                const SizedBox(height: 20),
                Obx(
                  () => CustomMaterialButton(
                    width: double.infinity,
                    text: authController.isRequestInFlight.value
                        ? AppStrings.verifyingCode.tr
                        : AppStrings.confirm.tr,
                    onPressed: authController.isRequestInFlight.value
                        ? () {}
                        : _handleVerify,
                  ),
                ),
                const SizedBox(height: 30),
                Obx(() {
                  final requestInFlight =
                      authController.isRequestInFlight.value;
                  final isLocked =
                      _resendSecondsRemaining > 0 || requestInFlight;
                  final resendText = _resendSecondsRemaining > 0
                      ? '${AppStrings.resend.tr} (${_resendSecondsRemaining}s)'
                      : AppStrings.resend.tr;
                  final resendColor =
                      isLocked ? AppColors.textSecondary : AppColors.primary;
                  return Row(
                    children: [
                      Text(AppStrings.resendCode.tr, style: AppTextStyles.body),
                      Opacity(
                        opacity: isLocked ? 0.6 : 1,
                        child: IgnorePointer(
                          ignoring: isLocked,
                          child: CustomTextButton(
                            text: resendText,
                            onPressed: _handleResend,
                            textColor: resendColor,
                          ),
                        ),
                      )
                    ],
                  );
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}





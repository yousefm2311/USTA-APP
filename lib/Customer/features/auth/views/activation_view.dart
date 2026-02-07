import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/helpers/app_mediaquery.dart';

import 'package:usta/Customer/core/utils/constants/app_colors.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';
import 'package:usta/Customer/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Customer/core/utils/widgets/text_button.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/features/auth/views/forget_password/presentation/views/widgets/reset_code_field.dart';

class ActivationView extends StatefulWidget {
  const ActivationView({super.key});

  @override
  State<ActivationView> createState() => _ActivationViewState();
}

class _ActivationViewState extends State<ActivationView> {
  final authController = Get.find<AuthController>(tag: 'customer');
  Color _borderColor = AppColors.border;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      authController.codeCtrl.clear();
      final args = Get.arguments as Map<String, dynamic>?;
      final emailArg = (args?['email'] as String?)?.trim();
      if (emailArg?.isNotEmpty == true) {
        authController.emailCtrl.text = emailArg!;
      }
    });
  }

  void _resetBorderOnEdit(String value) {
    authController.codeCtrl.text = value;
    if (_borderColor != AppColors.border) {
      setState(() => _borderColor = AppColors.border);
    }
  }

  Future<void> _activateAccount() async {
    if (_isVerifying) return;
    final code = authController.codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _borderColor = AppColors.error);
      return;
    }
    setState(() => _isVerifying = true);
    final success = await authController.verifyEmail();
    setState(() {
      _isVerifying = false;
      _borderColor = success ? AppColors.success : AppColors.error;
    });
    if (!success) return;
    authController.codeCtrl.clear();
    await Future.delayed(const Duration(milliseconds: 350));
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _resendCode() async {
    await authController.resendVerification();
    setState(() => _borderColor = AppColors.border);
  }

  @override
  Widget build(BuildContext context) {
    final size = AppMediaQuery.of(context).size;
    final email = authController.emailCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.activateAccount.tr,
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.activateAccountBody.tr,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 10),
                Text(
                  email.isNotEmpty ? email : AppStrings.email.tr,
                  style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 26),
                ResetCodeField(
                  borderColor: _borderColor,
                  onChanged: _resetBorderOnEdit,
                  onSubmit: _resetBorderOnEdit,
                ),
                const SizedBox(height: 24),
                CustomMaterialButton(
                  width: double.infinity,
                  text: _isVerifying
                      ? '${AppStrings.activateAccountButton.tr}...'
                      : AppStrings.activateAccountButton.tr,
                  onPressed: _isVerifying ? () {} : _activateAccount,
                  color: AppColors.primary,
                  textColor: AppColors.white,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      AppStrings.resendCode.tr,
                      style: AppTextStyles.small,
                    ),
                    const SizedBox(width: 6),
                    CustomTextButton(
                      text: AppStrings.resend.tr,
                      onPressed: _resendCode,
                      textColor: AppColors.primary,
                      hasBorder: false,
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.checkemailbody.tr,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Artisan/core/utils/widgets/text_button.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';
import 'package:usta/Artisan/features/auth/views/forget_password/presentation/views/widgets/reset_code_field.dart';


class ForgotPasswordCode extends StatefulWidget {
  const ForgotPasswordCode({super.key});

  @override
  State<ForgotPasswordCode> createState() => _ForgotPasswordCodeState();
}

class _ForgotPasswordCodeState extends State<ForgotPasswordCode> {
  final formKey = GlobalKey<FormState>();
  final authController = Get.find<AuthController>(tag: 'artisan');

  @override
  Widget build(BuildContext context) {
    final size = AppMediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.checkemail.tr, style: AppTextStyles.title(context)),
              const SizedBox(height: 20),
              Text(AppStrings.checkemailbody.tr, style: AppTextStyles.small(context)),
              const SizedBox(height: 20),
              ResetCodeField(
                onSubmit: (code) => authController.codeCtrl.text = code,
                onChanged: (code) => authController.codeCtrl.text = code,
              ),
              const SizedBox(height: 20),
              Obx(
                () => CustomMaterialButton(
                  width: double.infinity,
                  text: authController.isCodeVerifying.value
                      ? AppStrings.verifyingCode.tr
                      : AppStrings.confirm.tr,
                  onPressed: authController.isCodeVerifying.value
                      ? () {}
                      : () async {
                          if (authController.codeCtrl.text.trim().isEmpty) return;
                          final success =
                              await authController.verifyForgotPasswordCode();
                          if (success) {
                            pushNamedRoute(AppRoutes.setnewPassword);
                          }
                        },
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Text(AppStrings.resendCode.tr, style: AppTextStyles.body(context)),
                  CustomTextButton(
                    text: AppStrings.resend.tr,
                    onPressed: () {
                      authController.sendForgotPassword();
                    },
                    textColor: AppColors.primary,
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}



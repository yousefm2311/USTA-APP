import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Artisan/core/services/validators.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Artisan/core/utils/widgets/text_form_field.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';

class ForgotPasswordView extends StatelessWidget {
  ForgotPasswordView({super.key});

  final formKey = GlobalKey<FormState>();
  final authController = Get.find<AuthController>(tag: 'artisan');


  @override
  Widget build(BuildContext context) {
    final size = AppMediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.forgotPaswwordText.tr,
                style: AppTextStyles.title(context),
              ),
              SizedBox(height: size.height * 0.01),
               Text(
                AppStrings.forgotPaswwordbody.tr,
                style: AppTextStyles.body(context).copyWith(fontSize: 14),
              ),
              CustomTextField(
                label: '',
                controller: authController.emailCtrl,
                validator: (value) => Validators.email(value),
                hint: AppStrings.email.tr,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                fillColor: const Color(0x0ff7f7f7),
              ),
              const SizedBox(height: 20.0),
              Obx(
                () => CustomMaterialButton(
                  width: double.infinity,
                  text: authController.isForgotPasswordLoading.value
                      ? AppStrings.sendingCode.tr
                      : AppStrings.forgotPasswordButton.tr,
                  onPressed: authController.isForgotPasswordLoading.value
                      ? () {}
                      : () {
                          if (formKey.currentState!.validate()) {
                            authController.sendForgotPassword();
                          }
                        },
                  color: authController.isForgotPasswordLoading.value
                      ? Colors.grey
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



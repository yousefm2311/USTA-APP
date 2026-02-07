import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/services/validators.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Artisan/core/utils/widgets/icon_broken.dart';
import 'package:usta/Artisan/core/utils/widgets/text_form_field.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';

class SetNewPassword extends StatefulWidget {
   const SetNewPassword({super.key});

  @override
  State<SetNewPassword> createState() => _SetNewPasswordState();
}

class _SetNewPasswordState extends State<SetNewPassword> {
  final formKey=GlobalKey<FormState>();

  bool _isVisible = true;
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
                AppStrings.setnewPassword.tr,
                style: AppTextStyles.title(context),
              ),
              Text(
                AppStrings.setnewPasswordbody.tr,
                style: AppTextStyles.body(context),
              ),
              CustomTextField(
                label: '',
                controller: authController.passwordCtrl,
                validator: (value) => Validators.strongPassword(value),
                hint: AppStrings.password.tr,
                prefixIcon: IconBroken.Lock,
                keyboardType: TextInputType.visiblePassword,
                fillColor: const Color(0x0ff7f7f7),
                suffixIcon: _isVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                obscureText: _isVisible,
                onSuffixTap: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
              ),
              CustomTextField(
                label: '',
                controller: authController.newPasswordCtrl,
                validator: (value) => Validators.strongPassword(value),
                hint: AppStrings.passwordConfirm.tr,
                prefixIcon: IconBroken.Lock,
                keyboardType: TextInputType.visiblePassword,
                fillColor: const Color(0x0ff7f7f7),
                suffixIcon: _isVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                obscureText: _isVisible,
                onSuffixTap: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
              ),
              const SizedBox(height: 20.0),
              const SizedBox(height: 20.0),
              Obx(
                () => CustomMaterialButton(
                  width: double.infinity,
                  text: authController.isResetPasswordLoading.value
                      ? AppStrings.updatingPassword.tr
                      : AppStrings.updatePassword.tr,
                  onPressed: authController.isResetPasswordLoading.value
                      ? () {}
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (authController.passwordCtrl.text.trim() !=
                              authController.newPasswordCtrl.text.trim()) {
                            AppSnackBar.show(
                              AppStrings.warning.tr,
                              AppStrings.passwordsMismatch.tr,
                              type: SnackBarType.warning,
                            );
                            return;
                          }
                          final success =
                              await authController.resetPasswordWithCode();
                          if (success) {
                            authController.passwordCtrl.clear();
                            authController.newPasswordCtrl.clear();
                            authController.codeCtrl.clear();
                            pushNamedRoute(AppRoutes.success);
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



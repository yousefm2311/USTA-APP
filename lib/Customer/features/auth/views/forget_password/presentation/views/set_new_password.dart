import 'package:flutter/material.dart';
import 'package:usta/Customer/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Customer/core/services/functions/navigator.dart';
import 'package:usta/Customer/core/services/validators.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';

import 'package:usta/Customer/core/utils/routes/routes.dart';

import 'package:usta/Customer/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Customer/core/utils/widgets/icon_broken.dart';
import 'package:usta/Customer/core/utils/widgets/text_form_field.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class SetNewPassword extends StatefulWidget {
   const SetNewPassword({super.key});

  @override
  State<SetNewPassword> createState() => _SetNewPasswordState();
}

class _SetNewPasswordState extends State<SetNewPassword> {
  final formKey=GlobalKey<FormState>();

  bool _isVisible = true;
  final authController = Get.find<AuthController>(tag: 'customer');

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
                style: AppTextStyles.title,
              ),
              Text(
                AppStrings.setnewPasswordbody.tr,
                style: AppTextStyles.body,
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
                  text: authController.isRequestInFlight.value
                      ? AppStrings.updatingPassword.tr
                      : AppStrings.updatePassword.tr,
                  onPressed: authController.isRequestInFlight.value
                      ? () {}
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (authController.passwordCtrl.text.trim() !=
                              authController.newPasswordCtrl.text.trim()) {
                            AppSnackBar.show(
                              AppStrings.appName.tr,
                              AppStrings.passwordsMismatch.tr,
                              snackPosition: SnackPosition.BOTTOM,
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







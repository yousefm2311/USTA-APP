import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Customer/core/services/validators.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';
import 'package:usta/Customer/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Customer/core/utils/widgets/text_form_field.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class ForgotPasswordView extends StatelessWidget {
  ForgotPasswordView({super.key});

  final formKey = GlobalKey<FormState>();
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
                AppStrings.forgotPaswwordText.tr,
                style: AppTextStyles.title,
              ),
              SizedBox(height: size.height * 0.01),
               Text(
                AppStrings.forgotPaswwordbody.tr,
                style: AppTextStyles.body.copyWith(fontSize: 14),
              ),
              CustomTextField(
                label: '',
                controller: authController.emailCtrl,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  return Validators.email(value);
                },
                hint: AppStrings.email.tr,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                fillColor: const Color(0x0ff7f7f7),
              ),
              const SizedBox(height: 12.0),
              // CustomTextField(
              //   label: '',
              //   controller: authController.phoneCtrl,
              //   validator: (value) {
              //     if (value == null || value.isEmpty) return null;
              //     return Validators.phone(value);
              //   },
              //   hint: AppStrings.phone.tr,
              //   prefixIcon: Icons.phone_outlined,
              //   keyboardType: TextInputType.phone,
              //   fillColor: const Color(0x0ff7f7f7),
              // ),
              const SizedBox(height: 20.0),
              Obx(
                () => CustomMaterialButton(
                  width: double.infinity,
                  text: authController.isRequestInFlight.value
                      ? AppStrings.sendingCode.tr
                      : AppStrings.forgotPasswordButton.tr,
                  onPressed: authController.isRequestInFlight.value
                      ? () {}
                      : () {
                          if (!formKey.currentState!.validate()) return;
                          final email = authController.emailCtrl.text.trim();
                          final phone = authController.phoneCtrl.text.trim();
                          if (email.isEmpty && phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'ادخل الإيميل أو رقم الجوال'.tr,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          authController.sendForgotPassword();
                        },
                  color: authController.isRequestInFlight.value
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






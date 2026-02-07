import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';
import 'package:usta/Artisan/features/auth/views/widgets/register_text_form_field.dart';
import 'package:usta/Artisan/features/auth/views/widgets/terms_conditions.dart';
import 'package:usta/Artisan/features/auth/views/widgets/text_partition.dart';

class RegisterView extends StatelessWidget {
  RegisterView({super.key});

  final formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>(
    tag: 'artisan',
  );
  final RxBool termsAccepted = false.obs;

  @override
  Widget build(BuildContext context) {
    final size = AppMediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: size.height * 0.02),
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        child: TextPartition(
                          title: AppStrings.register.tr,
                          subtitle: AppStrings.register.tr,
                          artisnaText: AppStrings.artisan.tr,
                        ),
                      ),
                      SizedBox(height: size.height * 0.015),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 150),
                        child: RegisterTextFormField(
                          nameController: authController.nameCtrl,
                          emailController: authController.emailCtrl,
                          phoneController: authController.phoneCtrl,
                          passwordController: authController.passwordCtrl,
                          professionController: authController.professionCtrl,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      FadeInUp(
                        duration: const Duration(milliseconds: 650),
                        delay: const Duration(milliseconds: 220),
                        child: Obx(
                          () => Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: termsAccepted.value,
                                onChanged: authController.isLoading.value
                                    ? null
                                    : (value) {
                                        termsAccepted.value = value ?? false;
                                      },
                                activeColor: AppColors.primaryDark,
                              ),
                              Expanded(
                                child: TermsConditions(
                                  alignment: WrapAlignment.start,
                                  showPrefix: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        delay: const Duration(milliseconds: 300),
                        child: Obx(() {
                          final isLoading = authController.isLoading.value;
                          final canSubmit = termsAccepted.value && !isLoading;
                          return AbsorbPointer(
                            absorbing: !canSubmit,
                            child: Opacity(
                              opacity: canSubmit ? 1 : 0.5,
                              child: CustomMaterialButton(
                                text: isLoading
                                    ? '${AppStrings.register.tr}...'
                                    : AppStrings.register.tr,
                                onPressed: isLoading
                                    ? () {}
                                    : () {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        FocusScope.of(context).unfocus();
                                        authController.register();
                                      },
                                elevation: 0,
                                textColor: AppColors.white,
                                width: double.infinity,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: size.height * 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

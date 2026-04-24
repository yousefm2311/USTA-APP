import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Artisan/core/utils/widgets/text_button.dart';
import 'package:get/get.dart';
import 'package:usta/app/app_mode_controller.dart';
import 'package:usta/app/choose_user_type_view.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';
import 'package:usta/Artisan/features/auth/views/widgets/signin_text_form_field.dart';
import 'package:usta/Artisan/features/auth/views/widgets/terms_conditions.dart';
import 'package:usta/Artisan/features/auth/views/widgets/text_partition.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final formKey = GlobalKey<FormState>();
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    authController = Get.isRegistered<AuthController>(tag: 'artisan')
        ? Get.find<AuthController>(tag: 'artisan')
        : Get.put(AuthController(), tag: 'artisan');
  }

  Future<void> _goToChooseUserType() async {
    FocusScope.of(context).unfocus();
    if (Get.isRegistered<AppModeController>()) {
      try {
        await AppModeController.to.resetToChooser();
        return;
      } catch (_) {
        // Fallback to local navigation if global switch fails.
      }
    }
    if (!mounted) return;
    Get.offAll(
      () => const ChooseUserTypeView(fallbackMode: AppUserType.artisan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = AppMediaQuery.of(context).size;

    return Scaffold(
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
                      SizedBox(height: size.height * 0.05),
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        child: TextPartition(
                          title: AppStrings.login.tr,
                          subtitle: AppStrings.bodyLogin.tr,
                          artisnaText: AppStrings.artisan.tr,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 150),
                        child: SignInTextFormField(
                          emailController: authController.emailCtrl,
                          passwordController: authController.passwordCtrl,
                        ),
                      ),
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        delay: const Duration(milliseconds: 300),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: CustomTextButton(
                            text: AppStrings.forgotPaswword.tr,
                            onPressed: () {
                              pushNamedRoute(AppRoutes.forgetpassword);
                            },
                            textColor: AppColors.primaryDark,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      FadeInUp(
                        duration: const Duration(milliseconds: 750),
                        delay: const Duration(milliseconds: 400),
                        child: Obx(
                          () => CustomMaterialButton(
                            text: authController.isLoading.value
                                ? '${AppStrings.login.tr}...'
                                : AppStrings.login.tr,
                            onPressed: authController.isLoading.value
                                ? () {}
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    FocusScope.of(context).unfocus();
                                    authController.login();
                                  },
                            elevation: 0,
                            textColor: AppColors.white,
                            width: double.infinity,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.04),
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: CustomMaterialButton(
                          text: AppStrings.register.tr,
                          onPressed: () {
                            pushNamedRoute(AppRoutes.register);
                          },
                          isOutlined: true,
                          borderColor: AppColors.textLight,
                          elevation: 0,
                          textColor: AppColors.primaryDark,
                          width: double.infinity,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      FadeInUp(
                        duration: const Duration(milliseconds: 820),
                        delay: const Duration(milliseconds: 520),
                        child: CustomMaterialButton(
                          text: 'اختيار نوع الحساب',
                          onPressed: _goToChooseUserType,
                          isOutlined: true,
                          borderColor: AppColors.textLight,
                          elevation: 0,
                          textColor: AppColors.primaryDark,
                          width: double.infinity,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: size.height * 0.2),
                      FadeInUp(
                        duration: const Duration(milliseconds: 850),
                        delay: const Duration(milliseconds: 600),
                        child: const Center(child: TermsConditions()),
                      ),
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

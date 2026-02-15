import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Customer/core/services/functions/navigator.dart';
import 'package:usta/Customer/core/utils/constants/app_colors.dart';
import 'package:usta/Customer/core/utils/constants/app_strings.dart';
import 'package:usta/Customer/core/utils/routes/routes.dart';
import 'package:usta/Customer/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Customer/core/utils/widgets/text_button.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/features/auth/views/widgets/signin_text_form_field.dart';
import 'package:usta/Customer/features/auth/views/widgets/terms_conditions.dart';
import 'package:usta/Customer/features/auth/views/widgets/text_partition.dart';
import 'package:usta/app/app_mode_controller.dart';
import 'package:usta/app/choose_user_type_view.dart';

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
    authController = Get.isRegistered<AuthController>(tag: 'customer')
        ? Get.find<AuthController>(tag: 'customer')
        : Get.put(AuthController(), tag: 'customer');
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
    if (Get.currentRoute != '/ChooseUserTypeView') {
      Get.to(() => const ChooseUserTypeView(fallbackMode: AppUserType.customer));
    }
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
                          userText: AppStrings.user.tr,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 150),
                        child: SignInTextFormField(
                          emailController: authController.emailCtrl,
                          phoneController: authController.phoneCtrl,
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
                                : () {
                                    if (formKey.currentState!.validate()) {
                                      final email = authController
                                          .emailCtrl
                                          .text
                                          .trim();
                                      final phone = authController
                                          .phoneCtrl
                                          .text
                                          .trim();
                                      if (email.isEmpty && phone.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                      FocusScope.of(context).unfocus();
                                      authController.login();
                                    }
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

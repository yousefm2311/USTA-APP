import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/validators.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Artisan/core/utils/widgets/text_form_field.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';

class ArtisanChangePasswordView extends StatefulWidget {
  const ArtisanChangePasswordView({super.key});

  @override
  State<ArtisanChangePasswordView> createState() =>
      _ArtisanChangePasswordViewState();
}

class _ArtisanChangePasswordViewState extends State<ArtisanChangePasswordView> {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final authController = Get.find<AuthController>(tag: 'artisan');
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.changePassword.tr, style: AppTextStyles.title(context)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              CustomTextField(
                label: AppStrings.password.tr,
                controller: currentCtrl,
                hint: AppStrings.password.tr,
                validator: (value) => Validators.strongPassword(value),
                obscureText: _obscureCurrent,
                prefixIcon: Icons.lock_outline,
                suffixIcon:
                    _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                onSuffixTap: () {
                  setState(() {
                    _obscureCurrent = !_obscureCurrent;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStrings.password.tr,
                controller: newCtrl,
                hint: AppStrings.password.tr,
                validator: (value) => Validators.strongPassword(value),
                obscureText: _obscureNew,
                prefixIcon: Icons.lock_outline,
                suffixIcon:
                    _obscureNew ? Icons.visibility : Icons.visibility_off,
                onSuffixTap: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStrings.passwordConfirm.tr,
                controller: confirmCtrl,
                hint: AppStrings.passwordConfirm.tr,
                validator: (value) => Validators.strongPassword(value),
                obscureText: _obscureNew,
                prefixIcon: Icons.lock_outline,
                suffixIcon:
                    _obscureNew ? Icons.visibility : Icons.visibility_off,
                onSuffixTap: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),
              const SizedBox(height: 24),
              Obx(
                () => CustomMaterialButton(
                  width: double.infinity,
                  text: authController.isRequestInFlight.value
                      ? AppStrings.updatingPassword.tr
                      : AppStrings.updatePassword.tr,
                  onPressed: authController.isRequestInFlight.value
                      ? () {}
                      : () {
                          if (!formKey.currentState!.validate()) return;
                          if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
                            AppSnackBar.show(
                              AppStrings.warning.tr,
                              AppStrings.passwordsMismatch.tr,
                              type: SnackBarType.warning,
                            );
                            return;
                          }
                          authController.changePassword(
                            current: currentCtrl.text,
                            next: newCtrl.text,
                          );
                        },
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


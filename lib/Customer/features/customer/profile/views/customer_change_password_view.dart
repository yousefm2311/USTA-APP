import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/Customer/features/customer/profile/controllers/customer_profile_controller.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/profile_password_field.dart';

class CustomerChangePasswordView extends StatefulWidget {
  const CustomerChangePasswordView({super.key});

  @override
  State<CustomerChangePasswordView> createState() =>
      _CustomerChangePasswordViewState();
}

class _CustomerChangePasswordViewState
    extends State<CustomerChangePasswordView> {
  final controller = Get.find<CustomerProfileController>();
  final formKey = GlobalKey<FormState>();
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "تغيير كلمة المرور".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProfilePasswordField(
              title: "كلمة المرور الحالية".tr,
              controller: currentCtrl,
            ),
            ProfilePasswordField(
              title: "كلمة المرور الجديدة".tr,
              controller: newCtrl,
            ),
            ProfilePasswordField(
              title: "تأكيد كلمة المرور الجديدة".tr,
              controller: confirmCtrl,
            ),
            const SizedBox(height: 30),
            Obx(
              () => ElevatedButton(
                onPressed: controller.updatingSettings.value ? null : _change,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  controller.updatingSettings.value
                      ? 'جارٍ التحديث...'.tr
                      : 'حفظ'.tr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _change() async {
    if (!formKey.currentState!.validate()) return;
    if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
      AppSnackBar.show(
        'خطأ'.tr,
        'تأكيد كلمة المرور غير متطابق'.tr,
        backgroundColor: Colors.redAccent,
      );
      return;
    }
    final success = await controller.changePassword(
      current: currentCtrl.text.trim(),
      next: newCtrl.text.trim(),
    );
    if (success && mounted) Get.back();
  }
}


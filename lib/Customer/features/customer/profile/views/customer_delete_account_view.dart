import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/profile/controllers/customer_profile_controller.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/delete_account_widgets.dart';

class CustomerDeleteAccountView extends StatefulWidget {
  const CustomerDeleteAccountView({super.key});

  @override
  State<CustomerDeleteAccountView> createState() =>
      _CustomerDeleteAccountViewState();
}

class _CustomerDeleteAccountViewState extends State<CustomerDeleteAccountView> {
  final CustomerProfileController controller =
      Get.find<CustomerProfileController>();

  final TextEditingController confirmCtrl = TextEditingController();

  bool isDeleting = false;

  Color get red => const Color(0xFFE11D48);

  @override
  void initState() {
    super.initState();
    confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    confirmCtrl.dispose();
    super.dispose();
  }

  bool get canDelete =>
      confirmCtrl.text.trim().toUpperCase() == 'DELETE' && !isDeleting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'حذف الحساب'.tr,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeleteAccountWarningCard(borderColor: red),
            const SizedBox(height: 32),
            Text(
              'تأكيد الحذف'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DeleteAccountConfirmField(
              controller: confirmCtrl,
              focusColor: red,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canDelete ? _deleteAccount : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  disabledBackgroundColor: red.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                  : Text(
                        'حذف الحساب نهائيًا'.tr,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => isDeleting = true);

    try {
      await controller.deleteAccount();
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }
}


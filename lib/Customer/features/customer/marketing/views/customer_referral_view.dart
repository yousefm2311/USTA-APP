import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerReferralView extends StatefulWidget {
  const CustomerReferralView({super.key});

  @override
  State<CustomerReferralView> createState() => _CustomerReferralViewState();
}

class _CustomerReferralViewState extends State<CustomerReferralView> {
  final TextEditingController _codeCtrl = TextEditingController();
  final CustomerMarketingController _marketing =
      Get.find<CustomerMarketingController>();

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(

        appBar: AppBar(
          elevation: 0,
          title: Text(
            "الإحالة".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _myCodeCard(),
            const SizedBox(height: 18),
            _enterCodeCard(),
          ],
        ),
      ),
    );
  }

  Widget _myCodeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "شارك كود إحالتك مع الأصدقاء لتحصل على مزايا إضافية.".tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final fromCtrl = (_marketing.myReferralCode.value).trim();
            final referralCode = fromCtrl.isNotEmpty ? fromCtrl : "USTA-92YF";

            return Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      referralCode,
                      style: TextStyle(
                        color: blue,
                        fontFamily: "Cairo",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _copy(referralCode),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: blue.withOpacity(.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 10),
          Text(
            "اضغط على زر النسخ ثم أرسله في واتساب/تيليجرام.".tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enterCodeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "أدخل كود إحالة".tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle( fontFamily: "Cairo"),
            decoration: InputDecoration(
              hintText: "مثال: USTA-XXXX".tr,
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontFamily: "Cairo",
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: blue),
              ),
              prefixIcon: const Icon(
                Icons.confirmation_number_outlined,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Obx(() {
            final loading = _marketing.sendingReferral.value;
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  loading ? "جاري الإرسال...".tr : "تأكيد".tr,
                  style: const TextStyle(fontFamily: "Cairo"),
                ),
              ),
            );
          }),

          Obx(() {
            final err = _marketing.referralError.value.trim();
            if (err.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                err,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Cairo',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppSnackBar.show(
      'تم النسخ'.tr,
      'تم نسخ كود الإحالة'.tr,
      backgroundColor: Colors.black.withOpacity(.75),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _send() async {
    final code = _codeCtrl.text.trim().toUpperCase();

    if (code.isEmpty) {
      AppSnackBar.show(
        'تنبيه'.tr,
        'الرجاء إدخال الكود'.tr,
        backgroundColor: Colors.black.withOpacity(.75),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final ok = RegExp(r'^[A-Z0-9]{3,10}-[A-Z0-9]{3,10}$').hasMatch(code);
    if (!ok) {
      AppSnackBar.show(
        'تنبيه'.tr,
        'صيغة الكود غير صحيحة'.tr,
        backgroundColor: Colors.black.withOpacity(.75),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      await _marketing.sendReferral(code);
      _codeCtrl.clear();
      AppSnackBar.show(
        'تم'.tr,
        'تم إرسال كود الإحالة'.tr,
        backgroundColor: Colors.green.withOpacity(.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      AppSnackBar.show(
        'خطأ'.tr,
        e.toString(),
        backgroundColor: Colors.redAccent.withOpacity(.85),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}



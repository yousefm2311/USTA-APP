import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerCouponApplyView extends StatefulWidget {
  const CustomerCouponApplyView({super.key});

  @override
  State<CustomerCouponApplyView> createState() =>
      _CustomerCouponApplyViewState();
}

class _CustomerCouponApplyViewState extends State<CustomerCouponApplyView> {
  final TextEditingController _ctrl = TextEditingController();
  final CustomerMarketingController _marketing =
      Get.find<CustomerMarketingController>();

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "تطبيق كوبون".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              style: const TextStyle( fontFamily: "Cairo"),
              decoration: InputDecoration(
                hintText: "أدخل كود الكوبون".tr,
                hintStyle: const TextStyle(
                  fontFamily: "Cairo",
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ElevatedButton(
                onPressed: _marketing.applying.value ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _marketing.applying.value
                      ? "جاري التطبيق...".tr
                      : "تطبيق".tr,
                  style: const TextStyle(fontFamily: "Cairo", fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) {
      AppSnackBar.show('تنبيه'.tr, 'الرجاء إدخال الكود'.tr);
      return;
    }
    try {
      await _marketing.applyCoupon(code);
      Get.back();
      AppSnackBar.show('تم'.tr, 'تم تطبيق الكوبون بنجاح'.tr);
    } catch (e) {
      AppSnackBar.show('خطأ'.tr, _friendlyCouponError(e));
    }
  }

  String _friendlyCouponError(Object e) {
    const fallback = 'تعذر تطبيق الكوبون حالياً. حاول مرة أخرى.';
    if (e is ApiException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('expired')) {
        return 'عذراً، هذا الكوبون منتهي الصلاحية.'.tr;
      }
      if (msg.contains('invalid') ||
          msg.contains('not found') ||
          e.statusCode == 404) {
        return 'الكوبون غير صالح أو غير صحيح.'.tr;
      }
      if (msg.contains('used') || msg.contains('already')) {
        return 'تم استخدام الكوبون من قبل.'.tr;
      }
      if (e.message.isNotEmpty) return e.message;
    }
    final raw = e.toString().toLowerCase();
    if (raw.contains('expired')) {
      return 'عذراً، هذا الكوبون منتهي الصلاحية.'.tr;
    }
    if (raw.contains('invalid') || raw.contains('not found')) {
      return 'الكوبون غير صالح أو غير صحيح.'.tr;
    }
    if (raw.contains('socketexception') || raw.contains('network')) {
      return 'تحقق من اتصال الإنترنت وحاول مرة أخرى.'.tr;
    }
    return fallback.tr;
  }
}



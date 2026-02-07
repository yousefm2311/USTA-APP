import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerAIFeedbackView extends StatefulWidget {
  const CustomerAIFeedbackView({super.key});

  @override
  State<CustomerAIFeedbackView> createState() => _CustomerAIFeedbackViewState();
}

class _CustomerAIFeedbackViewState extends State<CustomerAIFeedbackView> {
  final ctrl = TextEditingController();
  final marketing = Get.find<CustomerMarketingController>();

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  void dispose() {
    ctrl.dispose();
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
            "الرسالة الذكية".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "احصل على ملخص سريع عن حسابك أو اكتب ملاحظة قصيرة ليتم تلخيصها لك."
                    .tr,
                style: const TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: ctrl,
                      minLines: 3,
                      maxLines: 5,
                      style: const TextStyle(
                        fontFamily: "Cairo",
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        hintText: "اكتب ملاحظة (اختياري)...".tr,
                        hintStyle: const TextStyle(
                          fontFamily: "Cairo",
                        ),
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
                      ),
                    ),
                    const SizedBox(height: 12),

                    Obx(
                      () => _responseBox(
                        message: marketing.aiMessage.value,
                        stats: marketing.aiStats,
                        loading: marketing.sendingFeedback.value,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: marketing.sendingFeedback.value ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      marketing.sendingFeedback.value
                          ? "جارٍ الإرسال...".tr
                          : "إرسال".tr,
                      style: const TextStyle(fontFamily: "Cairo", fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      await marketing.sendAiFeedback(ctrl.text.trim());
      AppSnackBar.show('تم'.tr, 'تم تحديث ملخص الاستخدام'.tr);
      ctrl.clear();
    } catch (e) {
      AppSnackBar.show('خطأ'.tr, e.toString());
    }
  }

  Widget _responseBox({
    required String? message,
    required Map<String, dynamic> stats,
    required bool loading,
  }) {
    if (loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (message == null || message.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          'سيظهر هنا ملخص الاستخدام عند طلبه.'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (stats.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: stats.entries.map((e) {
                return Chip(
                  backgroundColor: Colors.white10,
                  label: Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}



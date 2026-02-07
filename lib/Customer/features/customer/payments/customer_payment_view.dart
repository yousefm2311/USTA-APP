import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/features/customer/payments/controllers/customer_payments_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerPaymentView extends StatefulWidget {
  final double amount;
  final String? requestId;
  const CustomerPaymentView({
    super.key,
    required this.amount,
    this.requestId,
  });

  @override
  State<CustomerPaymentView> createState() => _CustomerPaymentViewState();
}

class _CustomerPaymentViewState extends State<CustomerPaymentView> {
  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);
  Color get green => const Color(0xFF22C55E);
  String get currency => 'ج.م'.tr;

  String selectedMethod = "wallet";
  final TextEditingController _requestCtrl = TextEditingController();
  bool _submitting = false;
  late final CustomerPaymentsController paymentsController;

  @override
  void initState() {
    super.initState();
    paymentsController = Get.find<CustomerPaymentsController>();
    if ((widget.requestId ?? '').isNotEmpty) {
      _requestCtrl.text = widget.requestId!;
    }
  }

  @override
  void dispose() {
    _requestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "الدفع".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("المبلغ المطلوب"),
          _amountCard(),
          const SizedBox(height: 25),
          _sectionTitle("اختر وسيلة الدفع"),
          _paymentMethods(),
          const SizedBox(height: 25),
          _sectionTitle("بيانات الدفع"),
          _infoBox(),
          if ((widget.requestId ?? '').isEmpty) ...[
            const SizedBox(height: 14),
            _requestField(),
          ],
          const SizedBox(height: 35),
          _payButton(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.tr,
      style: const TextStyle(
        fontFamily: "Cairo",
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_rounded, color: blue, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "@amount @currency".trParams(
                {
                  'amount': widget.amount.toStringAsFixed(2),
                  'currency': currency,
                },
              ),
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _paymentMethods() {
    return Column(
      children: [
        _method("wallet", "المحفظة", Icons.account_balance_wallet),
        const SizedBox(height: 10),
        _method("visa", "بطاقة بنكية", Icons.credit_card),
        const SizedBox(height: 10),
        _method("vodafone", "فودافون كاش", Icons.phone_iphone),
      ],
    );
  }

  Widget _method(String value, String title, IconData icon) {
    bool selected = selectedMethod == value;

    return InkWell(
      onTap: () => setState(() => selectedMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? blue : Colors.white10,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "Cairo",
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? blue : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        "تأكد من صحة المبلغ ومعرّف الطلب. قد يتم خصم رسوم بسيطة حسب وسيلة الدفع."
            .tr,
        style: const TextStyle(
          fontFamily: "Cairo",
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _requestField() {
    return TextField(
      controller: _requestCtrl,
      decoration: InputDecoration(
        filled: true,
        fillColor: card,
        hintText: "أدخل رقم الطلب".tr,
        hintStyle: const TextStyle(fontFamily: "Cairo"),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: blue),
        ),
      ),
      style: const TextStyle( fontFamily: "Cairo"),
    );
  }

  Widget _payButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : _handlePay,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _submitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Text(
                "تأكيد الدفع".tr,
                style: const TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Future<void> _handlePay() async {
    final reqId = (_requestCtrl.text.isNotEmpty
            ? _requestCtrl.text
            : widget.requestId ??
                '')
        .trim();
    if (reqId.isEmpty) {
      AppSnackBar.show('تنبيه'.tr, 'رقم الطلب مطلوب لإتمام الدفع'.tr);
      return;
    }
    if (widget.amount <= 0) {
      AppSnackBar.show('تنبيه'.tr, 'المبلغ يجب أن يكون أكبر من صفر'.tr);
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await paymentsController.createPaymentIntent(
        requestId: reqId,
      );
      final transactionId = res['transactionId']?.toString();
      final paymentUrl = res['paymentUrl']?.toString();
      final amount = res['amount'] ?? widget.amount;

      AppSnackBar.show(
        'تم'.tr,
        'تم إنشاء عملية الدفع'.tr,
      );

      await Get.dialog(
        AlertDialog(
          backgroundColor: card,
          title: Text(
            'تفاصيل الدفع'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المبلغ: @amount @currency'.trParams(
                  {
                    'amount': amount.toString(),
                    'currency': currency,
                  },
                ),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                ),
              ),
              if (transactionId != null && transactionId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'رقم المعاملة: @id'.trParams({'id': transactionId}),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
              if (paymentUrl != null && paymentUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'الرابط: @url'.trParams({'url': paymentUrl}),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('حسنا'.tr),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409 ||
          e.message.toLowerCase().contains('intent already created')) {
        AppSnackBar.show('تنبيه'.tr, 'تم إنشاء عملية الدفع بالفعل'.tr);
        return;
      }
      AppSnackBar.show(
        'خطأ'.tr,
        e.message.isNotEmpty ? e.message : 'فشل إنشاء الدفع'.tr,
      );
    } catch (e) {
      AppSnackBar.show('خطأ'.tr, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
  String? _extractId(Map<String, dynamic> res) {
    if (res['id'] != null) return res['id'].toString();
    if (res['_id'] != null) return res['_id'].toString();
    if (res['receipt'] is Map && res['receipt']['_id'] != null) {
      return res['receipt']['_id'].toString();
    }
    if (res['data'] is Map && res['data']['_id'] != null) {
      return res['data']['_id'].toString();
    }
    return null;
  }
}






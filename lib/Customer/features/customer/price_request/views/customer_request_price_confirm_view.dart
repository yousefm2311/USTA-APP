import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerRequestPriceConfirmView extends StatefulWidget {
  final double price;

  final String? requestId;

  final Future<void> Function({
    required double price,
    required String notes,
    String? requestId,
  })?
  onAccept;

  final Future<void> Function({
    required double price,
    required String notes,
    String? requestId,
  })?
  onReject;

  const CustomerRequestPriceConfirmView({
    super.key,
    required this.price,
    this.requestId,
    this.onAccept,
    this.onReject,
  });

  @override
  State<CustomerRequestPriceConfirmView> createState() =>
      _CustomerRequestPriceConfirmViewState();
}

class _CustomerRequestPriceConfirmViewState
    extends State<CustomerRequestPriceConfirmView> {
  final notesCtrl = TextEditingController();
  bool loading = false;

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);
  Color get green => const Color(0xFF22C55E);
  Color get red => const Color(0xFFE11D48);

  @override
  void dispose() {
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(widget.price);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "تأكيد السعر".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle("السعر المقترح"),
            _priceBox(priceText),
            const SizedBox(height: 25),
            _sectionTitle("ملاحظات إضافية (اختياري)"),
            const SizedBox(height: 10),
            _notesField(),
            const SizedBox(height: 30),
            _buttons(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.tr,
      style: const TextStyle(
        fontFamily: "Cairo",
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _priceBox(String priceText) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(Icons.price_change, color: blue, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "@price ج.م".trParams({'price': priceText}),
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'نسخ السعر'.tr,
            onPressed: loading
                ? null
                : () {
                    AppSnackBar.show(
                      'تم'.tr,
                      'تم نسخ السعر'.tr,
                    );
                  },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }

  Widget _notesField() {
    return TextField(
      controller: notesCtrl,
      maxLines: 5,
      style: const TextStyle( fontFamily: "Cairo"),
      decoration: InputDecoration(
        hintText: "لو عندك أي ملاحظات إضافية".tr,
        hintStyle: const TextStyle(fontFamily: "Cairo"),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: blue),
        ),
      ),
    );
  }

  Widget _buttons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : _accept,
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    "أوافق على السعر".tr,
                    style: const TextStyle(fontFamily: "Cairo", fontSize: 15),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : _reject,
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "رفض السعر".tr,
              style: const TextStyle(fontFamily: "Cairo", fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    final notes = notesCtrl.text.trim();

    setState(() => loading = true);
    try {
      if (widget.onAccept != null) {
        await widget.onAccept!(
          price: widget.price,
          notes: notes,
          requestId: widget.requestId,
        );
      }
      if (mounted) {
        Get.back(result: {'action': 'accepted'});
      }
    } catch (e) {
      AppSnackBar.show(
        'خطأ'.tr,
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _reject() async {
    final notes = notesCtrl.text.trim();

    final ok =
        await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'رفض السعر'.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            content: Text(
              'هل أنت متأكد من رفض السعر المقترح؟'.tr,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('إلغاء'.tr),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text(
                  'رفض'.tr,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() => loading = true);
    try {
      if (widget.onReject != null) {
        await widget.onReject!(
          price: widget.price,
          notes: notes,
          requestId: widget.requestId,
        );
        if (mounted) Get.back(result: {'action': 'rejected'});
      } else {
        if (mounted) {
          Get.back(
            result: {
              'action': 'rejected',
              'price': widget.price,
              'notes': notes,
              'requestId': widget.requestId,
            },
          );
        }
      }
    } catch (e) {
      AppSnackBar.show(
        'خطأ'.tr,
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _formatPrice(double p) {
    if (p % 1 == 0) return p.toStringAsFixed(0);
    return p.toStringAsFixed(2);
  }
}



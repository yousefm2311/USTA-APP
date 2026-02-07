import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/features/artisan/help/controllers/complaints_controller.dart';

class ArtisanNewComplaintView extends StatefulWidget {
  const ArtisanNewComplaintView({super.key});

  @override
  State<ArtisanNewComplaintView> createState() =>
      _ArtisanNewComplaintViewState();
}

class _ArtisanNewComplaintViewState extends State<ArtisanNewComplaintView> {
  final ComplaintsController controller = Get.find<ComplaintsController>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController issueCtrl = TextEditingController();
  final TextEditingController messageCtrl = TextEditingController();
  final TextEditingController requestIdCtrl = TextEditingController();
  final TextEditingController customerIdCtrl = TextEditingController();
  String type = 'service';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إبلاغ جديد'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: issueCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الشكوى',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'أدخل عنوان الشكوى' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'service', child: Text('خدمة')),
                  DropdownMenuItem(value: 'payment', child: Text('دفع')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                decoration: const InputDecoration(
                  labelText: 'نوع الشكوى',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => type = v ?? 'service'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: requestIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم الطلب (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: customerIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'رقم العميل (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: messageCtrl,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'التفاصيل',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'أدخل تفاصيل الشكوى' : null,
              ),
              const SizedBox(height: 20),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.submitting.value ? null : _submit,
                    child: controller.submitting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('إرسال الشكوى'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, dynamic>{
      'issue': issueCtrl.text.trim(),
      'type': type,
      'message': messageCtrl.text.trim(),
    };
    if (requestIdCtrl.text.trim().isNotEmpty) {
      payload['requestId'] = requestIdCtrl.text.trim();
    }
    if (customerIdCtrl.text.trim().isNotEmpty) {
      payload['customerId'] = customerIdCtrl.text.trim();
    }
    await controller.createComplaint(payload);
    if (mounted) Get.back();
  }
}


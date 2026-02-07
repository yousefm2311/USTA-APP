import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/help/controllers/complaints_controller.dart';

class ArtisanComplaintDetailsView extends StatefulWidget {
  const ArtisanComplaintDetailsView({
    super.key,
    required this.complaintId,
    this.complaint,
  });

  final String complaintId;
  final Map<String, dynamic>? complaint;

  @override
  State<ArtisanComplaintDetailsView> createState() =>
      _ArtisanComplaintDetailsViewState();
}

class _ArtisanComplaintDetailsViewState
    extends State<ArtisanComplaintDetailsView> {
  final ComplaintsController controller = Get.find<ComplaintsController>();
  final TextEditingController messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.complaint != null) {
      controller.selectedComplaint.assignAll(widget.complaint!);
    }
    controller.fetchComplaint(widget.complaintId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الشكوى'),
        centerTitle: true,
      ),
      body: Obx(() {
        final data = controller.selectedComplaint;
        final msgs = controller.messages;
        final loading = controller.loading.value && data.isEmpty;
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _headerCard(data),
            ),
            Expanded(
              child: msgs.isEmpty
                  ? const Center(child: Text('لا توجد رسائل بعد'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final msg = msgs[index];
                        final created = msg['createdAt']?.toString() ?? '';
                        final byArtisan = (msg['senderRole']?.toString() ?? '')
                            .toLowerCase()
                            .contains('artisan');
                        return Align(
                          alignment: byArtisan
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: byArtisan
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(.12)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['message']?.toString() ?? '',
                                  style: AppTextStyles.body(context),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  created,
                                  style: AppTextStyles.body(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            _buildComposer(),
          ],
        );
      }),
    );
  }

  Widget _headerCard(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'open').toString();
    final type = data['type']?.toString() ?? 'service';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['issue']?.toString() ?? 'بدون عنوان',
                  style: AppTextStyles.title(context),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['message']?.toString() ?? '',
            style: AppTextStyles.body(context),
          ),
          const SizedBox(height: 8),
          Text('النوع: $type', style: AppTextStyles.body(context)),
          if (data['requestId'] != null)
            Text('رقم الطلب: ${data['requestId']}', style: AppTextStyles.body(context)),
          if (data['customerId'] != null)
            Text('رقم العميل: ${data['customerId']}', style: AppTextStyles.body(context)),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'اكتب ردك...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => IconButton(
                icon: controller.submitting.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: controller.submitting.value
                    ? null
                    : () {
                        final text = messageCtrl.text.trim();
                        if (text.isEmpty) return;
                        controller.addMessage(widget.complaintId, text);
                        messageCtrl.clear();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'closed':
        color = Colors.green;
        label = 'مغلقة';
        break;
      case 'assigned':
        color = Colors.orange;
        label = 'قيد المعالجة';
        break;
      default:
        color = Colors.blue;
        label = 'مفتوحة';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.body(context).copyWith(color: color),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_complaint_details_view.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_new_complaint_view.dart';
import 'package:usta/Artisan/features/artisan/help/controllers/complaints_controller.dart';

class ArtisanComplaintsView extends StatefulWidget {
  const ArtisanComplaintsView({super.key});

  @override
  State<ArtisanComplaintsView> createState() => _ArtisanComplaintsViewState();
}

class _ArtisanComplaintsViewState extends State<ArtisanComplaintsView> {
  final ComplaintsController controller = Get.find<ComplaintsController>();
  final RxString statusFilter = ''.obs;

  @override
  void initState() {
    super.initState();
    controller.fetchComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشكاوى'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.to(() => const ArtisanNewComplaintView());
          controller.fetchComplaints(status: statusFilter.value.isEmpty ? null : statusFilter.value);
        },
        label: const Text('إبلاغ جديد'),
        icon: const Icon(Icons.add_comment),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.complaints.isEmpty) {
                  return const Center(child: Text('لا توجد شكاوى حالياً'));
                }
                return RefreshIndicator(
                  onRefresh: () => controller.fetchComplaints(
                    status: statusFilter.value.isEmpty ? null : statusFilter.value,
                  ),
                  child: ListView.separated(
                    itemCount: controller.complaints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = controller.complaints[index];
                      final id = item['_id']?.toString() ?? '';
                      final createdAt = item['createdAt']?.toString() ?? '';
                      final status = (item['status'] ?? 'pending').toString();
                      return InkWell(
                        onTap: () => Get.to(
                          () => ArtisanComplaintDetailsView(
                            complaintId: id,
                            complaint: item,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['issue']?.toString() ?? 'بدون عنوان',
                                      style: AppTextStyles.title(context),
                                    ),
                                  ),
                                  _statusChip(status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['message']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(context).copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                createdAt,
                                style: AppTextStyles.body(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      {'label': 'الكل', 'value': ''},
      {'label': 'مفتوحة', 'value': 'open'},
      {'label': 'قيد المعالجة', 'value': 'assigned'},
      {'label': 'مغلقة', 'value': 'closed'},
    ];
    return Obx(
      () => Wrap(
        spacing: 8,
        children: filters
            .map(
              (f) => ChoiceChip(
                label: Text(f['label']!),
                selected: statusFilter.value == f['value'],
                onSelected: (_) {
                  statusFilter.value = f['value']!;
                  controller.fetchComplaints(
                    status: statusFilter.value.isEmpty ? null : statusFilter.value,
                  );
                },
              ),
            )
            .toList(),
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


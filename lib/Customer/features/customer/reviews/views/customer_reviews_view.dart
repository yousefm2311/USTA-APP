import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/reviews/controllers/customer_reviews_controller.dart';

class CustomerReviewsView extends StatelessWidget {
  CustomerReviewsView({super.key});

  final CustomerReviewsController controller =
      Get.isRegistered<CustomerReviewsController>()
      ? Get.find<CustomerReviewsController>()
      : Get.put(CustomerReviewsController());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('تقييماتي'.tr, style: const TextStyle(fontFamily: 'Cairo')),
      ),
      body: Obx(() {
        if (controller.loading.value && controller.reviews.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.reviews.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchReviews,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'لا توجد تقييمات بعد'.tr,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: scheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchReviews,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.reviews.length,
            itemBuilder: (_, i) => _reviewCard(context, controller.reviews[i]),
          ),
        );
      }),
    );
  }

  Widget _reviewCard(BuildContext context, Map<String, dynamic> review) {
    final scheme = Theme.of(context).colorScheme;
    final rating = (review['rating'] is num)
        ? (review['rating'] as num).toInt()
        : int.tryParse((review['rating'] ?? '').toString()) ?? 0;
    final comment = (review['comment'] ?? '').toString();
    final reply = (review['reply'] ?? '').toString();
    final artisanName = (review['artisanName'] ?? '').toString();
    final id = (review['_id'] ?? review['id'])?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  artisanName.isNotEmpty ? artisanName : 'الحرفي'.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _stars(rating),
            ],
          ),
          const SizedBox(height: 8),
          if (comment.isNotEmpty)
            Text(
              comment,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
          if (comment.isEmpty)
            Text(
              'بدون تعليق'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.primary.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.reply, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reply,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: id.isEmpty
                      ? null
                      : () => _openEdit(context, review),
                  child: Text(
                    comment.isEmpty ? 'إضافة تعليق'.tr : 'تعديل التقييم'.tr,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: id.isEmpty
                      ? null
                      : () => _confirmDelete(context, id),
                  child: Text(
                    'حذف'.tr,
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          Icons.star,
          size: 18,
          color: i < rating ? Colors.amber : Colors.white30,
        ),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    Map<String, dynamic> review,
  ) async {
    final id = (review['_id'] ?? review['id'])?.toString() ?? '';
    if (id.isEmpty) return;
    final initialRating = (review['rating'] is num)
        ? (review['rating'] as num).toInt()
        : int.tryParse((review['rating'] ?? '').toString()) ?? 0;
    final ctrl = TextEditingController(
      text: (review['comment'] ?? '').toString(),
    );
    int rating = initialRating;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعديل التقييم'.tr,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        onPressed: () => setModalState(() => rating = i + 1),
                        icon: Icon(
                          Icons.star,
                          color: i < rating ? Colors.amber : Colors.white30,
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقك...'.tr,
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'حفظ'.tr,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == true) {
      await controller.updateReview(
        id: id,
        rating: rating == 0 ? 1 : rating,
        comment: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
      );
      await controller.fetchReviews();
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            'حذف التقييم؟'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          content: Text(
            'هل أنت متأكد أنك تريد حذف التقييم؟'.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'حذف'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await controller.deleteReview(id);
    }
  }
}

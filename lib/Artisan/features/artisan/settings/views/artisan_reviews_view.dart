// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/artisan_reviews_controller.dart';

class ArtisanReviewsView extends StatelessWidget {
  const ArtisanReviewsView({super.key});

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ArtisanReviewsController());
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.artisanReviewsTitle.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.reviews.isEmpty) {
          return Center(child: Text(AppStrings.reviewBodyPlaceholder.tr));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ratingHeader(
              context,
              controller.average.value,
              controller.totalReviews.value,
            ),
            const SizedBox(height: 25),
            ...controller.reviews.map(
              (review) => _reviewItem(context, review, controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _ratingHeader(BuildContext context, double avg, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.ratingSummary.tr,
            style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            avg > 0 ? avg.toStringAsFixed(1) : AppStrings.ratingAverage.tr,
            style: AppTextStyles.body(context).copyWith(
              fontSize: 45,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => const Icon(Icons.star, color: Colors.amber, size: 26),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total > 0
                ? '$total ${AppStrings.reviewCountSuffix.tr}'
                : AppStrings.ratingCount.tr,
            style: AppTextStyles.body(context),
          ),
        ],
      ),
    );
  }

  Widget _reviewItem(
    BuildContext context,
    Map<String, dynamic> review,
    ArtisanReviewsController controller,
  ) {
    final customer = review['customer'] is Map<String, dynamic>
        ? (review['customer'] as Map<String, dynamic>)
        : null;
    final name = customer != null
        ? (customer['name'] ??
              customer['customerName'] ??
              AppStrings.reviewerNamePlaceholder.tr)
        : review['reviewerName'] ??
              review['customerName'] ??
              AppStrings.reviewerNamePlaceholder.tr;
    final body =
        review['comment'] ??
        review['message'] ??
        AppStrings.reviewBodyPlaceholder.tr;
    final rawDate = review['repliedAt'] ?? review['createdAt'];
    final dateLabel = _formatDate(rawDate?.toString());
    final rating = (review['rating'] ?? review['score'] ?? 0).toDouble();
    final reply = review['reply'];
    final phone = ((customer?['phone'] ?? review['phone'])?.toString() ?? '')
        .trim();
    final email = ((customer?['email'] ?? review['email'])?.toString() ?? '')
        .trim();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryBlue.withOpacity(0.3),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    color: i < rating.round() ? Colors.amber : Colors.white24,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: AppTextStyles.body(context)),
          if (email.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (phone.isNotEmpty) _contactBadge(Icons.phone, phone, context),
                if (email.isNotEmpty) _contactBadge(Icons.email, email, context),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            dateLabel,
            style: const TextStyle(
              fontFamily: "Cairo",
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          if (reply != null && reply.toString().isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 24),
            Text(
              reply.toString(),
              style: AppTextStyles.body(context).copyWith(color: Colors.greenAccent),
            ),
          ],
          const SizedBox(height: 10),
          CustomMaterialButton(
            width: double.infinity,
            text: AppStrings.replyReview.tr,
            onPressed: () => _showReplyDialog(context, review, controller),
            // color: Colors.grey.withOpacity(0.3),
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(
    BuildContext context,
    Map<String, dynamic> review,
    ArtisanReviewsController controller,
  ) {
    final replyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.replyReview.tr,
                style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppStrings.replyHint.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final busy = controller.replying.value;
                      return CustomMaterialButton(
                        text: busy
                            ? AppStrings.sendingCode.tr
                            : AppStrings.send.tr,
                        width: double.infinity,
                        onPressed: busy
                            ? () {}
                            : () async {
                                final reply = replyCtrl.text.trim();
                                if (reply.isEmpty) return;
                                final reviewId = (review['_id'] ?? review['id'])
                                    ?.toString();
                                if (reviewId == null || reviewId.isEmpty)
                                  return;
                                final success = await controller.replyToReview(
                                  reviewId,
                                  reply,
                                );
                                if (success) {
                                  Navigator.pop(ctx);
                                }
                              },
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return AppStrings.reviewDatePlaceholder.tr;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final localeCode =
        Get.locale?.languageCode ?? Get.deviceLocale?.languageCode ?? 'en';
    final formatted = DateFormat.yMMMd(
      localeCode,
    ).add_jm().format(parsed.toLocal());
    return formatted;
  }

  Widget _contactBadge(IconData icon, String text, context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.caption(context)),
        ],
      ),
    );
  }
}


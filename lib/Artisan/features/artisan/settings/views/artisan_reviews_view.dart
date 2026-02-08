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
  Color get primaryBlueDark => const Color(0xFF1D4ED8);

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
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.update.tr,
            onPressed: controller.fetchReviews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        final loading = controller.loading.value;
        final allReviews = controller.reviews.toList();
        final filtered = controller.filteredReviews;
        if (loading && allReviews.isEmpty) {
          return _loadingState(context, controller);
        }

        final counts = _ratingCounts(allReviews);

        return RefreshIndicator(
          onRefresh: controller.fetchReviews,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _ratingHeader(
                context,
                controller.average.value,
                controller.totalReviews.value,
                counts,
              ),
              const SizedBox(height: 16),
              if (allReviews.isNotEmpty) _filtersRow(context, controller),
              if (allReviews.isNotEmpty) const SizedBox(height: 12),
              if (filtered.isEmpty)
                _emptyState(context)
              else
                ...filtered.map(
                  (review) => _reviewItem(context, review, controller),
                ),
              if (loading) _inlineLoading(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _loadingState(
    BuildContext context,
    ArtisanReviewsController controller,
  ) {
    return RefreshIndicator(
      onRefresh: controller.fetchReviews,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _inlineLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          minHeight: 4,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.15),
        ),
      ),
    );
  }

  Map<int, int> _ratingCounts(List<Map<String, dynamic>> reviews) {
    final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      final rating = _ratingInt(review['rating']);
      if (rating >= 1 && rating <= 5) {
        counts[rating] = (counts[rating] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _filtersRow(
    BuildContext context,
    ArtisanReviewsController controller,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final filters = <int>[0, 5, 4, 3, 2, 1];

    return Obx(() {
      final selected = controller.ratingFilter.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((value) {
          final isAll = value == 0;
          return ChoiceChip(
            selected: selected == value,
            onSelected: (_) => controller.setRatingFilter(value),
            side: BorderSide(
              color: selected == value
                  ? scheme.primary
                  : scheme.outline.withOpacity(0.2),
            ),
            selectedColor: scheme.primary.withOpacity(0.12),
            backgroundColor: scheme.surface,
            label: isAll
                ? Text('الكل'.tr, style: const TextStyle(fontFamily: 'Cairo'))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                    ],
                  ),
          );
        }).toList(),
      );
    });
  }

  Widget _ratingHeader(
    BuildContext context,
    double avg,
    int total,
    Map<int, int> counts,
  ) {
    final totalCount = total > 0
        ? total
        : counts.values.fold(0, (sum, value) => sum + value);
    final averageLabel = avg > 0 ? avg.toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.ratingSummary.tr,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      averageLabel,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStars(
                      avg,
                      size: 18,
                      color: Colors.amber,
                      emptyColor: Colors.white24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalCount > 0
                          ? '$totalCount ${AppStrings.reviewCountSuffix.tr}'
                          : AppStrings.noData.tr,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Text(
                      totalCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.reviews.tr,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...[5, 4, 3, 2, 1].map(
            (star) => _ratingBar(
              context,
              star,
              counts[star] ?? 0,
              totalCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(
    BuildContext context,
    int stars,
    int count,
    int total,
  ) {
    final value = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            stars.toString(),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 62,
            color: scheme.onSurface.withOpacity(0.35),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.reviewsEmptyTitle.tr,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.reviewsEmptySubtitle.tr,
            style: AppTextStyles.caption(context),
            textAlign: TextAlign.center,
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
    final scheme = Theme.of(context).colorScheme;
    final customer = review['customer'] is Map<String, dynamic>
        ? (review['customer'] as Map<String, dynamic>)
        : null;
    final name = (review['customerName'] ??
            review['reviewerName'] ??
            review['customerName'] ??
            customer?['name'] ??
            customer?['fullName'] ??
            AppStrings.reviewerNamePlaceholder.tr)
        .toString();
    final body = (review['comment'] ??
            review['message'] ??
            review['text'] ??
            '')
        .toString()
        .trim();
    final rawDate = review['createdAt'] ?? review['repliedAt'];
    final dateLabel = _formatDate(rawDate);
    final ratingValue = _ratingValue(
      review['rating'] ??
          review['score'] ??
          review['stars'] ??
          review['value'],
    );
    final reply = (review['reply'] ?? review['artisanReply'] ?? '')
        .toString()
        .trim();
    final phone = ((customer?['phone'] ?? review['phone'])?.toString() ?? '')
        .trim();
    final email = ((customer?['email'] ?? review['email'])?.toString() ?? '')
        .trim();
    final hasReply = reply.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryBlue.withOpacity(0.16),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStars(
                    ratingValue,
                    size: 16,
                    color: Colors.amber,
                    emptyColor: Colors.white24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ratingValue > 0 ? ratingValue.toStringAsFixed(1) : '0.0',
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body.isNotEmpty ? body : AppStrings.reviewNoComment.tr,
            style: AppTextStyles.small(context).copyWith(
              color: scheme.onSurface.withOpacity(0.85),
            ),
          ),
          if (email.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (phone.isNotEmpty)
                  _contactBadge(Icons.phone, phone, context),
                if (email.isNotEmpty)
                  _contactBadge(Icons.email, email, context),
              ],
            ),
          ],
          if (hasReply) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.yourReply.tr,
                        style: AppTextStyles.small(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reply,
                    style: AppTextStyles.small(context).copyWith(
                      color: scheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          CustomMaterialButton(
            width: double.infinity,
            text:
                hasReply ? AppStrings.editReply.tr : AppStrings.replyReview.tr,
            onPressed: () => _showReplyDialog(context, review, controller),
            color: scheme.primary,
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
    final existing = (review['reply'] ?? review['artisanReply'] ?? '')
        .toString()
        .trim();
    final replyCtrl = TextEditingController(text: existing);
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
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyCtrl,
                maxLines: 4,
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
                        text: busy ? AppStrings.loading.tr : AppStrings.send.tr,
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
                                final success =
                                    await controller.replyToReview(
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

  String _formatDate(dynamic raw) {
    if (raw == null) {
      return AppStrings.reviewDatePlaceholder.tr;
    }
    DateTime? parsed;
    if (raw is DateTime) {
      parsed = raw;
    } else {
      parsed = DateTime.tryParse(raw.toString());
    }
    if (parsed == null) return raw.toString();
    final localeCode =
        Get.locale?.languageCode ?? Get.deviceLocale?.languageCode ?? 'en';
    final formatted = DateFormat.yMMMd(localeCode).add_jm().format(
          parsed.toLocal(),
        );
    return formatted;
  }

  double _ratingValue(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  int _ratingInt(dynamic raw) {
    return _ratingValue(raw).round().clamp(0, 5);
  }

  Widget _buildStars(
    double value, {
    double size = 18,
    Color color = Colors.amber,
    Color emptyColor = Colors.white24,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = value - i;
        if (starValue >= 1) {
          return Icon(Icons.star, color: color, size: size);
        }
        if (starValue >= 0.25) {
          return Icon(Icons.star_half, color: color, size: size);
        }
        return Icon(Icons.star_border, color: emptyColor, size: size);
      }),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first;
  }

  Widget _contactBadge(IconData icon, String text, BuildContext context) {
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

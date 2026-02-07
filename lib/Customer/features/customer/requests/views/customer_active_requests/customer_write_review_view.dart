import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/review_comment_box.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/review_rating_stars.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/review_submit_button.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerWriteReviewView extends StatefulWidget {
  const CustomerWriteReviewView({
    super.key,
    required this.artisanId,
    this.initialRating,
    this.initialComment,
  });

  final String artisanId;
  final int? initialRating;
  final String? initialComment;

  @override
  State<CustomerWriteReviewView> createState() =>
      _CustomerWriteReviewViewState();
}

class _CustomerWriteReviewViewState extends State<CustomerWriteReviewView> {
  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  double rating = 0;
  final commentCtrl = TextEditingController();
  bool submitting = false;

  final _repo = Get.find<CustomerRepository>();

  @override
  void initState() {
    super.initState();
    rating = (widget.initialRating ?? 0).toDouble();
    if (widget.initialComment != null) {
      commentCtrl.text = widget.initialComment!;
    }
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          "اكتب تقييمك".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              "قيّم الحرفي من 1 إلى 5".tr,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: "Cairo",
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            ReviewRatingStars(
              rating: rating,
              onSelect: (value) => setState(() => rating = value),
            ),
            const SizedBox(height: 25),
            ReviewCommentBox(
              controller: commentCtrl,
              cardColor: card,
            ),
            const Spacer(),
            ReviewSubmitButton(
              submitting: submitting,
              color: blue,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.artisanId.trim().isEmpty) {
      AppSnackBar.show('تنبيه'.tr, 'معرف الحرفي غير صالح'.tr);
      return;
    }
    if (rating <= 0) {
      AppSnackBar.show('تنبيه'.tr, 'اختر تقييمًا أولاً'.tr);
      return;
    }
    setState(() => submitting = true);
    try {
      await _repo.api.createReview(
        artisanId: widget.artisanId.trim(),
        rating: rating.toInt(),
        comment:
            commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
      );
      if (mounted) {
        Get.back();
        AppSnackBar.show('تم'.tr, 'تم إرسال التقييم بنجاح'.tr);
      }
    } on ApiException catch (e) {
      AppSnackBar.show(
        'خطأ'.tr,
        e.message.isNotEmpty ? e.message : 'تعذر إرسال التقييم'.tr,
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}



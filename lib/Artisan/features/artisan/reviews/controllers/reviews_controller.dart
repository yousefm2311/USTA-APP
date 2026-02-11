
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class ReviewsController extends GetxController {
  final ArtisanApi _api = ArtisanApi();

  final RxBool loading = false.obs;
  final RxDouble average = 0.0.obs;
  final RxInt count = 0.obs;
  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;

  Future<void> fetchReviews() async {
    loading.value = true;
    try {
      final avgResponse = await _api.reviewsAverage();
      final avgData = ApiClient.instance.unwrapData(avgResponse);
      if (avgData is Map<String, dynamic>) {
        average.value = double.tryParse('${avgData['average'] ?? 0}') ?? 0.0;
        count.value = int.tryParse('${avgData['count'] ?? 0}') ?? 0;
      }

      final listResponse = await _api.reviews();
      final listData = ApiClient.instance.unwrapData(listResponse);
      if (listData is List) {
        reviews.assignAll(_mapList(listData));
      } else if (listData is Map<String, dynamic> &&
          listData['items'] is List) {
        reviews.assignAll(_mapList(listData['items']));
      }
    } catch (_) {
      _showSnack(AppStrings.reviewsLoadFailed.tr, true);
    } finally {
      loading.value = false;
    }
  }

  Future<void> replyReview(String reviewId, String reply) async {
    if (reply.trim().isEmpty) return;
    try {
      await _api.replyReview(reviewId, reply);
      await fetchReviews();
      _showSnack(AppStrings.reviewReplySent.tr, false);
    } catch (_) {
      _showSnack(AppStrings.reviewReplyFailed.tr, true);
    }
  }

  List<Map<String, dynamic>> _mapList(List<dynamic> data) {
    return data
        .map((e) => (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
        .toList();
  }

  void _showSnack(String message, bool isError) {
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      message,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }
}


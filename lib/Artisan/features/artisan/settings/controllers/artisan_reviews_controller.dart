import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class ArtisanReviewsController extends GetxController {
  final ArtisanApi _api = ArtisanApi();

  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;
  final RxDouble average = 0.0.obs;
  final RxInt totalReviews = 0.obs;
  final RxBool loading = false.obs;
  final RxBool replying = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    loading.value = true;
    try {
      final response = await _api.getReviews();
      final payload = ApiClient.instance.unwrapData(response);
      final reviewList = _extractReviews(payload);
      reviews.assignAll(reviewList);
      totalReviews.value = _extractTotal(payload) ?? reviewList.length;

      final averageResp = await _api.getReviewsAverage();
      final averagePayload = ApiClient.instance.unwrapData(averageResp);
      average.value = _extractAverage(averagePayload);
      final avgTotal = _extractTotal(averagePayload);
      if (avgTotal != null) {
        totalReviews.value = avgTotal;
      }
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : AppStrings.reviewsLoadFailed.tr;
      AppSnackBar.show(
        AppStrings.error.tr,
        message,
        type: SnackBarType.error,
      );
    } finally {
      loading.value = false;
    }
  }

  Future<bool> replyToReview(String reviewId, String reply) async {
    if (replying.value) return false;
    replying.value = true;
    try {
      await _api.replyReview(reviewId, reply);
      final index = reviews.indexWhere((element) => element['_id'] == reviewId);
      if (index != -1) {
        reviews[index] = {...reviews[index], 'reply': reply};
        reviews.refresh();
      }
      return true;
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : AppStrings.reviewReplyFailed.tr;
      AppSnackBar.show(
        AppStrings.error.tr,
        message,
        type: SnackBarType.error,
      );
      return false;
    } finally {
      replying.value = false;
    }
  }

  List<Map<String, dynamic>> _extractReviews(dynamic payload) {
    if (payload is List) {
      return _castReviewList(payload);
    }
    if (payload is Map<String, dynamic>) {
      final list = payload['reviews'] ?? payload['items'] ?? payload['results'];
      if (list is List) {
        return _castReviewList(list);
      }
      if (payload['data'] != null) {
        return _extractReviews(payload['data']);
      }
    }
    return [];
  }

  double _extractAverage(dynamic payload) {
    if (payload is num) return payload.toDouble();
    if (payload is Map<String, dynamic>) {
      final value =
          payload['average'] ??
          payload['rating'] ??
          payload['ratingAverage'] ??
          payload['score'];
      if (value is num) return value.toDouble();
      if (payload['data'] != null) {
        return _extractAverage(payload['data']);
      }
    }
    return 0.0;
  }

  int? _extractTotal(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final value =
          payload['total'] ??
          payload['count'] ??
          payload['reviewsCount'] ??
          payload['totalReviews'];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (payload['data'] != null) {
        return _extractTotal(payload['data']);
      }
    }
    if (payload is List) {
      return payload.length;
    }
    return null;
  }

  List<Map<String, dynamic>> _castReviewList(List<dynamic> data) {
    return data
        .map(
          (item) =>
              (item as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
        )
        .toList();
  }
}


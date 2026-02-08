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
  final RxInt ratingFilter = 0.obs;

  List<Map<String, dynamic>> get filteredReviews {
    final filter = ratingFilter.value;
    if (filter <= 0) return reviews.toList();
    return reviews.where((review) => _ratingValue(review) == filter).toList();
  }

  void setRatingFilter(int value) {
    ratingFilter.value = value;
  }

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
      final normalized = _normalizeReviews(reviewList);
      normalized.sort(
        (a, b) => _reviewDate(b).compareTo(_reviewDate(a)),
      );
      reviews.assignAll(normalized);
      totalReviews.value = _extractTotal(payload) ?? normalized.length;

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
      final index = reviews.indexWhere(
        (element) => (element['_id'] ?? element['id'])?.toString() == reviewId,
      );
      if (index != -1) {
        reviews[index] = {
          ...reviews[index],
          'reply': reply,
          'repliedAt': DateTime.now().toIso8601String(),
        };
        reviews.refresh();
      }
      AppSnackBar.show(
        AppStrings.success.tr,
        AppStrings.reviewReplySent.tr,
        type: SnackBarType.success,
      );
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

  List<Map<String, dynamic>> _normalizeReviews(
    List<Map<String, dynamic>> data,
  ) {
    return data.map(_normalizeReview).toList();
  }

  Map<String, dynamic> _normalizeReview(Map<String, dynamic> raw) {
    final customerRaw =
        raw['customer'] ??
        raw['customerId'] ??
        raw['customer_id'] ??
        raw['user'] ??
        raw['client'];
    final Map<String, dynamic>? customer =
        customerRaw is Map ? Map<String, dynamic>.from(customerRaw) : null;
    final name =
        raw['customerName'] ??
        raw['customer_name'] ??
        raw['reviewerName'] ??
        customer?['name'] ??
        customer?['fullName'] ??
        customer?['username'];
    final rating =
        raw['rating'] ?? raw['score'] ?? raw['stars'] ?? raw['value'];
    final comment =
        raw['comment'] ?? raw['message'] ?? raw['text'] ?? raw['review'];
    final reply =
        raw['reply'] ??
        raw['artisanReply'] ??
        raw['replyText'] ??
        raw['response'];
    return {
      ...raw,
      if (customer != null) 'customer': customer,
      if (name != null) 'customerName': name,
      'rating': rating,
      'comment': comment,
      'reply': reply,
      'createdAt':
          raw['createdAt'] ?? raw['created_at'] ?? raw['date'] ?? raw['time'],
      'repliedAt':
          raw['repliedAt'] ?? raw['replied_at'] ?? raw['replyAt'] ?? raw['reply_at'],
    };
  }

  int _ratingValue(Map<String, dynamic> review) {
    final raw =
        review['rating'] ?? review['score'] ?? review['stars'] ?? review['value'];
    if (raw is num) return raw.round().clamp(0, 5);
    return int.tryParse(raw?.toString() ?? '')?.clamp(0, 5) ?? 0;
  }

  DateTime _reviewDate(Map<String, dynamic> review) {
    final raw =
        review['createdAt'] ??
        review['repliedAt'] ??
        review['created_at'] ??
        review['date'];
    final parsed = _parseDate(raw);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}


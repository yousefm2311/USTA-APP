import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerReviewsController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;
  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxBool deleting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    loading.value = true;
    try {
      final res = await _repo.api.myReviews();
      final list = res['reviews'] ?? res['data'] ?? res;
      if (list is List) {
        reviews.assignAll(
          list
              .map<Map<String, dynamic>>(
                (e) => e is Map<String, dynamic> ? _normalizeReview(e) : {},
              )
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      } else {
        reviews.clear();
      }
    } on ApiException catch (e) {
      _handleApiError(e);
      reviews.clear();
    } finally {
      loading.value = false;
    }
  }

  Future<bool> updateReview({
    required String id,
    required int rating,
    String? comment,
  }) async {
    saving.value = true;
    try {
      final res = await _repo.api.updateReview(
        id: id,
        rating: rating,
        comment: comment,
      );
      final data = res['review'] ?? res['data'] ?? res;
      if (data is Map<String, dynamic>) {
        _upsert(_normalizeReview(data));
      }
      return true;
    } on ApiException catch (e) {
      _handleApiError(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> deleteReview(String id) async {
    deleting.value = true;
    try {
      await _repo.api.deleteReview(id);
      reviews.removeWhere(
        (item) => (item['_id'] ?? item['id'])?.toString() == id,
      );
      return true;
    } on ApiException catch (e) {
      _handleApiError(e);
      return false;
    } finally {
      deleting.value = false;
    }
  }

  Map<String, dynamic> _normalizeReview(Map<String, dynamic> raw) {
    final artisanRaw = raw['artisan'] ?? raw['artisanId'] ?? raw['artisan_id'];
    String? artisanName;
    if (artisanRaw is Map) {
      artisanName = (artisanRaw['name'] ??
              artisanRaw['fullName'] ??
              artisanRaw['username'])
          ?.toString();
    }
    return {
      '_id': raw['_id'] ?? raw['id'],
      'rating': raw['rating'] ?? raw['stars'] ?? raw['value'],
      'comment': raw['comment'] ?? raw['message'] ?? raw['text'],
      'artisan': artisanRaw,
      'artisanName': raw['artisanName'] ?? raw['artisan_name'] ?? artisanName,
      'reply': raw['reply'],
      'repliedAt': raw['repliedAt'],
      'createdAt': raw['createdAt'],
      'updatedAt': raw['updatedAt'],
    };
  }

  void _upsert(Map<String, dynamic> review) {
    final id = (review['_id'] ?? review['id'])?.toString();
    if (id == null || id.isEmpty) return;
    final idx = reviews.indexWhere(
      (r) => (r['_id'] ?? r['id'])?.toString() == id,
    );
    if (idx >= 0) {
      reviews[idx] = {...reviews[idx], ...review};
      reviews.refresh();
    } else {
      reviews.insert(0, review);
    }
  }

  void _handleApiError(ApiException e) {
    if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
      Get.find<AuthController>(tag: 'customer').logout(remote: false);
      return;
    }
    final msg = e.message.isNotEmpty ? e.message : 'حدث خطأ، حاول مرة أخرى'.tr;
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}



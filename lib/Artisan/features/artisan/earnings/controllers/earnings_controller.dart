import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class EarningsController extends GetxController {
  final ArtisanApi _api = ArtisanApi();
  final AuthService _auth = Get.find<AuthService>();

  final RxBool loading = false.obs;
  final RxDouble total = 0.0.obs;
  final RxDouble month = 0.0.obs;
  final RxDouble week = 0.0.obs;
  final RxList<Map<String, dynamic>> transactions =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _auth.whenAuthenticated(fetchEarnings);
  }

  Future<void> fetchEarnings() async {
    if (!_auth.isAuthenticated) return;

    loading.value = true;
    try {
      await _tryFetchEarnings();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _tryFetchEarnings() async {
    try {
      final response = await _api.earnings();
      final raw = ApiClient.instance.unwrapData(response);
      _parseEarnings(raw);
    } on ApiException catch (e) {
      // لو 401 → refresh
      if (e.statusCode == 401) {
        final refreshed = await _auth.refreshTokens();
        if (refreshed) {
          // retry silently
          final responseRetry = await _api.earnings();
          final raw = ApiClient.instance.unwrapData(responseRetry);
          _parseEarnings(raw);
          return;
        }
        await _auth.handleUnauthorized(skipRefresh: true);
        return;
      }
      _showSnack(e.message, true);
    } catch (e) {
      _showSnack(AppStrings.earningsLoadFailed.tr, true);
    }
  }

  void _parseEarnings(dynamic raw) {
    final data = (raw is Map<String, dynamic> && raw['data'] is Map)
        ? (raw['data'] as Map).cast<String, dynamic>()
        : (raw is Map<String, dynamic>)
        ? raw
        : <String, dynamic>{};

    if (data.isNotEmpty) {
      total.value =
          double.tryParse(
            "${data['total'] ?? data['all'] ?? data['balance']}",
          ) ??
          0.0;
      month.value =
          double.tryParse("${data['month'] ?? data['thisMonth']}") ?? 0.0;
      week.value =
          double.tryParse("${data['week'] ?? data['thisWeek']}") ?? 0.0;

      final list = data['history'] ?? data['transactions'];
      if (list is List) {
        final parsed = list
            .map(
              (e) =>
                  (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
            )
            .toList();
        parsed.sort((a, b) {
          final da =
              DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db =
              DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        transactions.assignAll(parsed);
      }
    }
  }

  void _showSnack(String message, bool isError) {
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      message,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }
}


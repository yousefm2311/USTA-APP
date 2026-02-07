import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class PortfolioController extends GetxController {
  static const int maxItems = 10;

  final ArtisanApi _api = ArtisanApi();
  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  bool get isAtLimit => items.length >= maxItems;

  Future<void> loadFromProfile() async {
    loading.value = true;
    try {
      final response = await _api.me();
      final data = ApiClient.instance.unwrapData(response);
      Map<String, dynamic>? artisan;
      if (data is Map<String, dynamic>) {
        artisan = (data['artisan'] ?? data) as Map<String, dynamic>?;
      }
      if (artisan != null && artisan['portfolio'] is List) {
        items.assignAll(
          (artisan['portfolio'] as List)
              .map((e) => (e as Map?)?.cast<String, dynamic>() ?? {}),
        );
      }
    } catch (e) {
      _showSnack(
        AppStrings.portfolioLoadFailed.tr,
        isError: true,
        details: _errorMessage(e),
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> addPortfolios({
    required List<XFile> files,
    required String description,
  }) async {
    if (files.isEmpty) return;

    final remaining = maxItems - items.length;
    if (remaining <= 0) {
      _showSnack(
        AppStrings.portfolioLimitReached.trParams({'count': '$maxItems'}),
        isError: true,
      );
      return;
    }

    final toUpload = files.take(remaining).toList();
    if (toUpload.length < files.length) {
      _showSnack(
        AppStrings.portfolioLimitReached.trParams({'count': '$maxItems'}),
        isError: true,
      );
    }

    saving.value = true;
    int success = 0;
    int failed = 0;
    String? lastError;

    try {
      for (final file in toUpload) {
        try {
          final created = await _uploadSingle(
            file: file,
            description: description,
          );
          if (created != null) {
            items.add(created);
            success++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
          lastError = _errorMessage(e);
        }
      }

      if (success > 0 && failed == 0) {
        _showSnack(
          AppStrings.portfolioUploadSuccess.trParams({'count': '$success'}),
          isError: false,
        );
      } else if (success > 0 && failed > 0) {
        _showSnack(
          AppStrings.portfolioUploadPartial.trParams({
            'success': '$success',
            'failed': '$failed',
          }),
          isError: true,
        );
      } else if (failed > 0) {
        _showSnack(
          AppStrings.portfolioUploadFailed.tr +
              (lastError != null ? ': $lastError' : ''),
          isError: true,
        );
      }
    } finally {
      saving.value = false;
    }
  }

  Future<void> addPortfolio({
    required XFile file,
    required String description,
  }) async {
    await addPortfolios(files: [file], description: description);
  }

  Future<Map<String, dynamic>?> _uploadSingle({
    required XFile file,
    required String description,
  }) async {
    final bytes = await file.readAsBytes();
    final base64Image =
        'data:${file.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
    final response = await _api.addPortfolio(
      imageBase64: base64Image,
      description: description,
    );
    final payload = ApiClient.instance.unwrapData(response);
    if (payload is Map<String, dynamic>) {
      final nested = payload['item'];
      if (nested is Map) return nested.cast<String, dynamic>();
      return payload.cast<String, dynamic>();
    }
    return null;
  }

  Future<void> deletePortfolio(String id) async {
    if (id.isEmpty) return;
    saving.value = true;
    try {
      await _api.deletePortfolio(id);
      items.removeWhere((element) => (element['id'] ?? element['_id']) == id);
      _showSnack(AppStrings.portfolioDeleteSuccess.tr, isError: false);
    } catch (e) {
      _showSnack(
        AppStrings.portfolioDeleteFailed.tr,
        isError: true,
        details: _errorMessage(e),
      );
    } finally {
      saving.value = false;
    }
  }

  String _errorMessage(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  void _showSnack(
    String message, {
    bool isError = false,
    String? details,
  }) {
    final display =
        details != null && details.isNotEmpty ? '$message: $details' : message;
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      display,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }
}


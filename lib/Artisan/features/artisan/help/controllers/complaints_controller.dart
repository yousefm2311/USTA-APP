import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class ComplaintsController extends GetxController {
  final ArtisanApi _api = ArtisanApi();

  final RxBool loading = false.obs;
  final RxBool submitting = false.obs;
  final RxList<Map<String, dynamic>> complaints = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> selectedComplaint = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  Future<void> fetchComplaints({String? status}) async {
    loading.value = true;
    try {
      final response =
          await _api.complaints(status: status, page: 1, perPage: 50);
      final data = ApiClient.instance.unwrapData(response);
      if (data is List) {
        complaints.assignAll(
          data
              .map((e) => (e as Map?)?.cast<String, dynamic>() ?? {})
              .toList(),
        );
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        complaints.assignAll(
          (data['items'] as List)
              .map((e) => (e as Map?)?.cast<String, dynamic>() ?? {})
              .toList(),
        );
      }
    } catch (_) {
      _showSnack(AppStrings.complaintsLoadFailed.tr, true);
    } finally {
      loading.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchComplaint(String id) async {
    loading.value = true;
    try {
      final response = await _api.complaint(id);
      final data = ApiClient.instance.unwrapData(response);
      if (data is Map<String, dynamic>) {
        selectedComplaint.assignAll(data);
        if (data['messages'] is List) {
          messages.assignAll(
            (data['messages'] as List)
                .map((e) => (e as Map?)?.cast<String, dynamic>() ?? {})
                .toList(),
          );
        }
        return data;
      }
    } catch (_) {
      _showSnack(AppStrings.complaintDetailsFailed.tr, true);
    } finally {
      loading.value = false;
    }
    return null;
  }

  Future<void> createComplaint(Map<String, dynamic> payload) async {
    submitting.value = true;
    try {
      await _api.createComplaint(payload);
      _showSnack(AppStrings.complaintSentSuccess.tr, false);
      await fetchComplaints();
    } catch (_) {
      _showSnack(AppStrings.complaintSendFailed.tr, true);
    } finally {
      submitting.value = false;
    }
  }

  Future<void> addMessage(String id, String message) async {
    submitting.value = true;
    try {
      await _api.complaintMessages(id, message: message);
      _showSnack(AppStrings.complaintMessageSent.tr, false);
      await fetchComplaint(id);
    } catch (_) {
      _showSnack(AppStrings.complaintMessageFailed.tr, true);
    } finally {
      submitting.value = false;
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


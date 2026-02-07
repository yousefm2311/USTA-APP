import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';
import 'package:usta/Artisan/data/repositories/artisan_requests_repository.dart';

class ArtisanRequestsController extends GetxController {
  final ArtisanApi _api = ArtisanApi();
  final ArtisanRequestsRepository _repository = ArtisanRequestsRepository();
  final AuthService _auth = Get.find<AuthService>();
  final AppPrefs _prefs = AppPrefs();
  double? _artisanLat;
  double? _artisanLng;
  static const double _nearbyKm = 50.0;

  final RxList<Map<String, dynamic>> newRequests = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> activeRequests =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> historyRequests =
      <Map<String, dynamic>>[].obs;

  final RxBool loadingNew = false.obs;
  final RxBool loadingActive = false.obs;
  final RxBool loadingHistory = false.obs;
  final RxBool submitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _waitForAuthBeforeFetch();
  }

  void _waitForAuthBeforeFetch() async {
    await _auth.waitForAuthentication();
    if (!_auth.isAuthenticated || isClosed) return;
    await _prefs.init();
    _loadCachedLocation();
    await fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchNewRequests(),
      fetchActiveRequests(),
      fetchHistoryRequests(),
    ]);
  }

  Future<void> fetchNewRequests() async {
    if (!_auth.isAuthenticated) return;
    loadingNew.value = true;
    try {
      final response = await _repository.getNewRequests();
      _loadCachedLocation();
      final filtered = _filterNearby(response);
      newRequests.assignAll(filtered);
    } catch (e) {
      _handleError(e);
    } finally {
      loadingNew.value = false;
    }
  }

  void _loadCachedLocation() {
    final cached = _prefs.getString(kCachedProfileKey);
    if (cached == null || cached.isEmpty) return;
    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final loc = data['location'];
      if (loc is Map && loc['coordinates'] is List) {
        final coords = loc['coordinates'] as List;
        if (coords.length >= 2) {
          _artisanLng = (coords[0] as num?)?.toDouble();
          _artisanLat = (coords[1] as num?)?.toDouble();
          return;
        }
      }
      final lat = (loc is Map ? loc['lat'] : null) ?? data['lat'];
      final lng = (loc is Map ? loc['lng'] : null) ?? data['lng'];
      _artisanLat = (lat as num?)?.toDouble();
      _artisanLng = (lng as num?)?.toDouble();
    } catch (_) {
      // ignore cache parse errors
    }
  }

  List<Map<String, dynamic>> _filterNearby(
    List<Map<String, dynamic>> items,
  ) {
    if (_artisanLat == null || _artisanLng == null) return items;
    final withDistance = <Map<String, dynamic>>[];
    for (final item in items) {
      final coords = _requestCoords(item['location']);
      if (coords == null) continue;
      final dist = _distanceKm(
        _artisanLat!,
        _artisanLng!,
        coords[0],
        coords[1],
      );
      if (dist <= _nearbyKm) {
        withDistance.add({...item, '_distanceKm': dist});
      }
    }
    if (withDistance.isEmpty) return items;
    withDistance.sort((a, b) {
      final da = (a['_distanceKm'] as num?)?.toDouble() ?? 0;
      final db = (b['_distanceKm'] as num?)?.toDouble() ?? 0;
      return da.compareTo(db);
    });
    return withDistance;
  }

  List<double>? _requestCoords(dynamic location) {
    if (location is Map && location['coordinates'] is List) {
      final coords = location['coordinates'] as List;
      if (coords.length >= 2) {
        final lng = (coords[0] as num?)?.toDouble();
        final lat = (coords[1] as num?)?.toDouble();
        if (lat != null && lng != null) return [lat, lng];
      }
    }
    return null;
  }

  double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  Future<void> fetchActiveRequests() async {
    if (!_auth.isAuthenticated) return;
    loadingActive.value = true;
    try {
      final response = await _repository.getActiveRequests();
      activeRequests.assignAll(response);
    } catch (e) {
      _handleError(e);
    } finally {
      loadingActive.value = false;
    }
  }

  Future<void> fetchHistoryRequests() async {
    if (!_auth.isAuthenticated) return;
    loadingHistory.value = true;
    try {
      final response = await _repository.getHistoryRequests();
      response.sort((a, b) {
        final da =
            DateTime.tryParse(
              (a['updatedAt'] ?? a['createdAt'] ?? '').toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            DateTime.tryParse(
              (b['updatedAt'] ?? b['createdAt'] ?? '').toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      historyRequests.assignAll(response);
    } catch (e) {
      _handleError(e);
    } finally {
      loadingHistory.value = false;
    }
  }

  Future<void> acceptRequest(String id, {int? price, String? note}) async {
    submitting.value = true;
    try {
      await _api.acceptRequest(id, price: price, note: note);
      newRequests.removeWhere(
        (element) => element['id'] == id || element['_id'] == id,
      );
      await fetchActiveRequests();
      _showSnack(
        AppStrings.requestAcceptedTitle.tr,
        AppStrings.requestAcceptedMessage.tr,
        SnackBarType.success,
      );
    } catch (e) {
      _handleError(e);
    } finally {
      submitting.value = false;
    }
  }

  Future<void> rejectRequest(String id, {String? reason}) async {
    submitting.value = true;
    try {
      await _api.rejectRequest(id, reason: reason);
      newRequests.removeWhere(
        (element) => element['id'] == id || element['_id'] == id,
      );
      _showSnack(
        AppStrings.requestRejectedTitle.tr,
        AppStrings.requestRejectedMessage.tr,
        SnackBarType.warning,
      );
    } catch (e) {
      _handleError(e);
    } finally {
      submitting.value = false;
    }
  }

  Future<void> completeRequest(String id) async {
    submitting.value = true;
    try {
      final response = await _api.completeRequest(id);
      final data = ApiClient.instance.unwrapData(response);

      _updateLocalStatus(id, 'awaiting_confirmation', data);

      _showSnack(
        AppStrings.waitingCustomerConfirmationTitle.tr,
        AppStrings.waitingCustomerConfirmationMessage.tr,
        SnackBarType.info,
      );
    } catch (e) {
      _handleError(e);
    } finally {
      submitting.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchRequestDetails(String id) async {
    try {
      final response = await _api.requestDetails(id);
      final data = ApiClient.instance.unwrapData(response);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (e) {
      _handleError(e);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchRequestTimeline(String id) async {
    try {
      final response = await _api.requestTimeline(id);
      final data = ApiClient.instance.unwrapData(response);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      if (data is Map && data['timeline'] is List) {
        return (data['timeline'] as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    } catch (e) {
      _handleError(e);
    }
    return [];
  }

  Future<void> updateTimeline(String id, String status, {String? note}) async {
    submitting.value = true;
    try {
      await _api.updateTimeline(id, status: status, note: note);
      await fetchActiveRequests();
      _showSnack(
        AppStrings.timelineUpdatedTitle.tr,
        AppStrings.timelineUpdatedMessage.tr,
        SnackBarType.success,
      );
    } catch (e) {
      _handleError(e);
    } finally {
      submitting.value = false;
    }
  }
  void _updateLocalStatus(
    String id,
    String status,
    Map<String, dynamic>? data,
  ) {
    int idx = activeRequests.indexWhere(
      (element) => (element['id'] ?? element['_id']).toString() == id,
    );

    if (idx != -1) {
      final updated = Map<String, dynamic>.from(activeRequests[idx]);
      updated['status'] = status;
      if (data != null && data is Map<String, dynamic>) {
        updated.addAll(data);
      }
      activeRequests[idx] = updated;
      activeRequests.refresh();
    } else {
      fetchActiveRequests();
    }
  }

  void _handleError(Object error) {
    if (error is ApiException) {
      _showSnack(AppStrings.error.tr, error.message, SnackBarType.error);
      return;
    }

    _showSnack(
      AppStrings.error.tr,
      AppStrings.couldNotCompleteRequest.tr,
      SnackBarType.error,
    );
  }

  void _showSnack(String title, String message, SnackBarType type) {
    AppSnackBar.show(title, message, type: type);
  }
}


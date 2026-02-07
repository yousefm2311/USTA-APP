import 'package:get/get.dart';
import 'package:usta/Customer/core/realtime/events.dart';
import 'package:usta/Customer/core/realtime/realtime_controller.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/settings/nearby_radius_settings.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerRequestsController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final RealtimeController _rt = Get.find<RealtimeController>(tag: 'customer');

  final RxList<Map<String, dynamic>> activeRequests =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> historyRequests =
      <Map<String, dynamic>>[].obs;

  final Rxn<Map<String, dynamic>> requestDetails = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> timeline = <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> nearbyArtisans =
      <Map<String, dynamic>>[].obs;

  final RxList<String> serviceTypes = <String>[].obs;
  final Map<String, String> _serviceTypeIds = {};

  final RxBool loadingActive = false.obs;
  final RxBool loadingHistory = false.obs;
  final RxBool loadingDetails = false.obs;
  final RxBool loadingTimeline = false.obs;
  final RxBool submitting = false.obs;
  bool _activeLoaded = false;
  bool _historyLoaded = false;
  bool _serviceTypesLoaded = false;
  bool _socketsBound = false;
  int _detailsToken = 0;
  int _timelineToken = 0;

  final RxString currentRequestId = ''.obs;
  final RxString timelineRequestId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (!_socketsBound) {
      _listenSockets();
      _socketsBound = true;
    }
    fetchActiveRequests();
    fetchHistoryRequests();
    if (!_serviceTypesLoaded) {
      loadServiceTypes();
    }
  }

  void _listenSockets() {
    _rt.listenRequestEvents(
      onNew: _handleIncomingRequest,
      onAccepted: _handleIncomingRequest,
      onRejected: _handleIncomingRequest,
      onCancelled: _handleIncomingRequest,
      onUpdated: _handleIncomingRequest,
    );
    _rt.onEvent(RealtimeEvents.requestTimeline, _handleTimelineEvent);
  }
  Future<void> fetchActiveRequests({bool force = false}) async {
    if (_activeLoaded && !force) return;

    loadingActive.value = true;
    try {
      final response = await _repo.api.activeRequests();
      final list = _extractList(response, 'requests')
          .map<Map<String, dynamic>>(_normalizeRequest)
          .toList();
      activeRequests.assignAll(list);
      _activeLoaded = true;
    } on ApiException catch (e) {
      _handleError(e, fallback: 'تعذّر جلب الطلبات النشطة'.tr);
    } catch (e) {
      _showError('حدث خطأ غير متوقع'.tr);
    } finally {
      loadingActive.value = false;
    }
  }
  Future<void> fetchHistoryRequests({bool force = false}) async {
    if (_historyLoaded && !force) return;
    loadingHistory.value = true;
    try {
      final response = await _repo.api.requestsHistory();
      historyRequests.assignAll(_extractList(response, 'requests'));
      _historyLoaded = true;
    } on ApiException catch (e) {
      if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      historyRequests.clear();
    } finally {
      loadingHistory.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchRequestDetails(String id) async {
    currentRequestId.value = id;
    final token = ++_detailsToken;
    loadingDetails.value = true;
    try {
      final response = await _repo.api.requestDetails(id);
      if (_detailsToken != token || currentRequestId.value != id) {
        return null;
      }
      final timelineFromDetails = _extractTimelineFromDetails(response);
      if (timelineFromDetails != null) {
        timelineRequestId.value = id;
        timeline.assignAll(timelineFromDetails);
      }
      final raw = _extractMap(response, ['request', 'data']) ?? response;
      final req = _normalizeRequest(raw);
      requestDetails.value = req;
      return req;
    } on ApiException catch (e) {
      _handleError(e, fallback: 'تعذّر جلب تفاصيل الطلب'.tr);
      return null;
    } finally {
      if (_detailsToken == token) {
        loadingDetails.value = false;
      }
    }
  }

  Future<void> fetchTimeline(String id) async {
    final token = ++_timelineToken;
    timelineRequestId.value = id;
    loadingTimeline.value = true;
    timeline.clear();
    try {
      final response = await _repo.api.requestTimeline(id);
      if (_timelineToken != token || timelineRequestId.value != id) {
        return;
      }
      final map = Map<String, dynamic>.from(response);

      List<dynamic> rawList = [];
      if (map['timeline'] is List) {
        rawList = map['timeline'] as List;
      } else if (map['data'] is Map &&
          (map['data'] as Map)['timeline'] is List) {
        rawList = (map['data'] as Map)['timeline'] as List;
      } else if (map['data'] is List) {
        rawList = map['data'] as List;
      }
      final list = rawList
          .map<Map<String, dynamic>>(
            (e) => e is Map<String, dynamic> ? e : <String, dynamic>{},
          )
          .map(_normalizeTimelineItem)
          .toList();
      timeline.assignAll(list);
    } on ApiException catch (e) {
      if (_timelineToken == token) {
        timeline.clear();
        _handleError(e, fallback: 'تعذّر جلب خط الزمن'.tr);
      }
    } catch (_) {
      if (_timelineToken == token) {
        timeline.clear();
        _showError('حدث خطأ غير متوقع'.tr);
      }
    } finally {
      if (_timelineToken == token) {
        loadingTimeline.value = false;
      }
    }
  }

  Future<Map<String, dynamic>> createRequest({
    String? serviceType,
    String? artisanId,
    double? lat,
    double? lng,
    String? address,
    String? description,
  }) async {
    if ((serviceType == null || serviceType.trim().isEmpty) &&
        (artisanId == null || artisanId.trim().isEmpty)) {
      _showError('يجب اختيار الخدمة أو الحرفي أولا'.tr);
      throw ApiException(message: 'serviceType_or_artisan_required');
    }

    submitting.value = true;
    try {
      final response = await _repo.api.createRequest(
        serviceType: serviceType?.trim(),
        artisanId: artisanId?.trim(),
        lat: lat,
        lng: lng,
        address: address?.trim(),
        description: description?.trim(),
      );

      final request = _extractMap(response, ['request', 'data']) ?? response;
      _upsert(activeRequests, request);
      _activeLoaded = true;
      return request;
    } catch (e) {
      _handleError(e, fallback: 'تعذّر إنشاء الطلب'.tr);
      rethrow;
    } finally {
      submitting.value = false;
    }
  }

  Future<void> addImages({
    required String requestId,
    required List<dynamic> images,
  }) async {
    if (requestId.isEmpty) {
      _showError('معرّف الطلب غير صالح'.tr);
      return;
    }
    if (images.isEmpty) {
      _showError('يجب إضافة صورة واحدة على الأقل'.tr);
      return;
    }
    try {
      final response = await _repo.api.addRequestImages(
        requestId: requestId,
        images: images,
      );
      final req = _extractMap(response, ['request', 'data']);
      if (req != null) {
        _upsert(activeRequests, req);
        _activeLoaded = true;
      }
    } catch (e) {
      _handleError(e, fallback: 'تعذّر رفع الصور'.tr);
      rethrow;
    }
  }
  Future<void> cancelRequest(String id, {String? reason}) async {
    if (id.isEmpty) {
      _showError('معرّف الطلب غير صالح'.tr);
      return;
    }
    try {
      final response = await _repo.api.cancelRequest(
        id: id,
        reason: reason ?? '',
      );
      final req = _extractMap(response, ['request', 'data']) ?? response;
      _removeFromActive(id);
      historyRequests.insert(0, req);

      _historyLoaded = true;
    } catch (e) {
      _handleError(e, fallback: 'تعذّر إلغاء الطلب'.tr);
      rethrow;
    }
  }

  Future<void> confirmCompletion(String id, {String? note}) async {
    if (id.isEmpty) {
      _showError('معرّف الطلب غير صالح'.tr);
      return;
    }
    try {
      final response = await _repo.api.confirmCompletion(
        id: id,
        note: note ?? '',
      );
      final req = _extractMap(response, ['request', 'data']) ?? response;
      _removeFromActive(id);
      historyRequests.insert(0, req);

      _historyLoaded = true;
    } catch (e) {
      _handleError(e, fallback: 'تعذّر تأكيد الإتمام'.tr);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> decidePrice({
    required String id,
    required String action,
    String? notes,
    double? price,
  }) async {
    if (id.isEmpty) {
      _showError('رقم الطلب غير صالح'.tr);
      throw ApiException(message: 'request_id_missing');
    }
    final normalizedAction = action.trim().toLowerCase();
    if (normalizedAction != 'accept' && normalizedAction != 'reject') {
      _showError('اختيار غير صالح لتأكيد السعر'.tr);
      throw ApiException(message: 'invalid_price_action');
    }

    submitting.value = true;
    try {
      final response = await _repo.api.decidePrice(
        id: id,
        action: normalizedAction,
        notes: notes?.trim(),
        price: price,
      );
      final raw = _extractMap(response, ['request', 'data']) ?? response;
      final updated = _normalizeRequestUpdate(raw, fallbackId: id);
      if (updated.isNotEmpty) {
        _upsert(activeRequests, updated);
        final current = requestDetails.value;
        final currentId =
            (current?['_id'] ?? current?['id'])?.toString();
        final updatedId =
            (updated['_id'] ?? updated['id'])?.toString();
        if (current != null &&
            currentId != null &&
            updatedId != null &&
            currentId == updatedId) {
          requestDetails.value = {...current, ...updated};
        }
      }
      return updated;
    } on ApiException catch (e) {
      _handleError(e, fallback: 'حصل خطأ أثناء تنفيذ الطلب'.tr);
      rethrow;
    } finally {
      submitting.value = false;
    }
  }

  Future<void> loadNearbyArtisans({
    required double lat,
    required double lng,
    double? radiusKm,
  }) async {
    try {
      final radiusMeters = radiusKm != null
          ? (radiusKm * 1000).round()
          : await NearbyRadiusSettings.readMeters();
      final res = await _repo.api.artisanNearby(
        query: {
          'lat': lat,
          'lng': lng,
          if (radiusMeters != null) 'radius': radiusMeters,
        },
      );
      final list = _extractList(res['data'] ?? res, 'artisans');
      nearbyArtisans.assignAll(list);
    } catch (e) {
      _handleError(e, fallback: 'تعذّر جلب الحرفيين القريبين'.tr);
      nearbyArtisans.clear();
      rethrow;
    }
  }

  Future<void> loadServiceTypes({bool force = false}) async {
    if (_serviceTypesLoaded && !force) return;

    try {
      final res = await _repo.api.categories();
      final dynamic raw =
          (res['data'] ?? res)['categories'] ?? res['categories'] ?? [];
      final List<dynamic> list = raw is List ? raw : [];

      _serviceTypeIds.clear();
      final names = <String>[];
      for (final entry in list) {
        if (entry is Map) {
          final name = entry['name']?.toString().trim() ?? '';
          final id = (entry['_id'] ?? entry['id'])?.toString().trim() ?? '';
          if (name.isNotEmpty && id.isNotEmpty) {
            _serviceTypeIds[name] = id;
            names.add(name);
          }
          continue;
        }
        if (entry is String) {
          final name = entry.trim();
          if (name.isNotEmpty && name != '{}') {
            names.add(name);
          }
        }
      }

      serviceTypes.assignAll(names.toSet().toList());
      _serviceTypesLoaded = true;
    } catch (_) {
      serviceTypes.clear();
    }
  }

  String? resolveServiceTypeId(String name) {
    final key = name.trim();
    if (key.isEmpty) return null;
    return _serviceTypeIds[key];
  }
  void _handleIncomingRequest(dynamic data) async {
    if (data is! Map) return;

    final request = _normalizeRequest(Map<String, dynamic>.from(data));
    final id =
        (request['_id'] ?? request['id'] ?? request['requestId'])?.toString();
    if (id == null || id.isEmpty) return;
    request['_id'] ??= id;

    if (request['serviceType'] == null &&
        request['service'] == null &&
        request['category'] == null) {
      try {
        final res = await _repo.api.requestDetails(id);
        final full = _extractMap(res, ['request', 'data']) ?? res;
        request.addAll(full);
      } catch (_) {
        try {
          final res = await _repo.api.requestDetailsPublic(id);
          final full = _extractMap(res, ['request', 'data']) ?? res;
          request.addAll(full);
        } catch (_) {}
      }
    }

    final status = request['status']?.toString().toLowerCase();
    final isClosed =
        status != null &&
        ['completed', 'cancelled', 'rejected', 'closed'].contains(status);

    if (isClosed) {
      _removeFromActive(id);

      historyRequests.removeWhere(
        (element) => (element['_id'] ?? element['id'])?.toString() == id,
      );
      historyRequests.insert(0, request);

      _historyLoaded = true;
    } else {
      _upsert(activeRequests, request);
      _activeLoaded = true;
    }

    final current = requestDetails.value;
    final currentId = (current?['_id'] ?? current?['id'])?.toString();
    if (currentId == id) {
      requestDetails.value = {...current ?? <String, dynamic>{}, ...request};
    }
  }

  void _handleTimelineEvent(dynamic data) {
    if (data is Map<String, dynamic>) {
      final eventRequestId = (data['requestId'] ??
              data['request'] ??
              data['request_id'] ??
              data['reqId'])
          ?.toString();
      if (timelineRequestId.value.isNotEmpty &&
          eventRequestId != null &&
          eventRequestId.isNotEmpty &&
          eventRequestId != timelineRequestId.value) {
        return;
      }
      timeline.insert(0, _normalizeTimelineItem(data));
    }
  }
  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is List) {
      return value
          .map<Map<String, dynamic>>(
            (e) => e is Map<String, dynamic> ? e : <String, dynamic>{},
          )
          .toList();
    }

    if (data['data'] is Map<String, dynamic>) {
      final nested = (data['data'] as Map<String, dynamic>)[key];
      if (nested is List) {
        return nested
            .map<Map<String, dynamic>>(
              (e) => e is Map<String, dynamic> ? e : <String, dynamic>{},
            )
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic>? _extractMap(
    Map<String, dynamic> data,
    List<String> preferredKeys,
  ) {
    for (final key in preferredKeys) {
      final value = data[key];
      if (value is Map<String, dynamic>) return value;
    }
    return null;
  }

  List<Map<String, dynamic>>? _extractTimelineFromDetails(
    Map<String, dynamic> data,
  ) {
    dynamic raw;
    if (data['timeline'] is List) {
      raw = data['timeline'];
    } else if (data['data'] is Map &&
        (data['data'] as Map)['timeline'] is List) {
      raw = (data['data'] as Map)['timeline'];
    } else if (data['request'] is Map &&
        (data['request'] as Map)['timeline'] is List) {
      raw = (data['request'] as Map)['timeline'];
    } else if (data['data'] is Map &&
        (data['data'] as Map)['request'] is Map &&
        ((data['data'] as Map)['request'] as Map)['timeline'] is List) {
      raw = ((data['data'] as Map)['request'] as Map)['timeline'];
    }

    if (raw is! List) return null;
    return raw
        .map<Map<String, dynamic>>(
          (e) => e is Map<String, dynamic> ? e : <String, dynamic>{},
        )
        .map(_normalizeTimelineItem)
        .toList();
  }

  Map<String, dynamic> _normalizeTimelineItem(Map<String, dynamic> item) {
    final normalized = Map<String, dynamic>.from(item);
    normalized['status'] ??= normalized['action'];
    normalized['createdAt'] ??= normalized['at'] ?? normalized['created_at'];
    normalized['note'] ??= normalized['message'];
    return normalized;
  }

  void _upsert(RxList<Map<String, dynamic>> target, Map<String, dynamic> item) {
    final normalized = _normalizeRequest(item);
    final id = (normalized['_id'] ?? normalized['id'])?.toString();
    if (id == null) return;

    final idx = target.indexWhere(
      (element) => (element['_id'] ?? element['id'])?.toString() == id,
    );

    if (idx >= 0) {
      target[idx] = {...target[idx], ...normalized};
      target.refresh();
    } else {
      target.insert(0, normalized);
    }
  }

  void _removeFromActive(String id) {
    activeRequests.removeWhere(
      (element) => (element['_id'] ?? element['id'])?.toString() == id,
    );
  }

  void _handleError(dynamic error, {String? fallback}) {
    String message = fallback ?? 'حدث خطأ غير متوقع'.tr;

    if (error is ApiException) {
      message = (error.message.isNotEmpty)
          ? error.message
          : (fallback ?? 'تعذّر إتمام العملية'.tr);

      if ((error.statusCode == 401 || error.statusCode == 403) &&
          Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
    }

    AppSnackBar.show(
      'خطأ'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _showError(String msg) {
    AppSnackBar.show(
      'تنبيه'.tr,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
  void clearCache() {
    _activeLoaded = false;
    _historyLoaded = false;
    _serviceTypesLoaded = false;
  }

  Map<String, dynamic> _normalizeRequestUpdate(
    Map<String, dynamic> input, {
    required String fallbackId,
  }) {
    if (input.isEmpty) return {};
    final map = Map<String, dynamic>.from(input);
    if (map['_id'] == null && map['id'] == null) {
      map['_id'] = fallbackId;
    }
    return _normalizeRequest(map);
  }

  Map<String, dynamic> _normalizeRequest(Map<String, dynamic> input) {
    if (input.isEmpty) return input;
    final map = Map<String, dynamic>.from(input);
    final status = map['status']?.toString().toLowerCase();
    if (status == 'awaiting_payment') {
      map['status'] = 'in_progress';
    }
    return map;
  }
}




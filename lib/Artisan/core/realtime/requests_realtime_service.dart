import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/events.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

/// Listens to request:* socket events and shows a one-time dialog for new requests.
class RequestsRealtimeService extends GetxService
    implements RealtimeAwareService {
  final RealtimeController _rt = Get.find<RealtimeController>(tag: 'artisan');
  ArtisanRequestsController? _requestsController;

  // Dialog handling is centralized in RequestQueue + RequestDialogWidget.
  String? _artisanId;
  bool _joinedRooms = false;
  bool _eventsRegistered = false;
  StreamSubscription<SocketStatus>? _statusSub;
  bool _started = false;
  DateTime? _lastRestSyncAt;
  Future<void>? _inflightSync;

  @override
  void onInit() {
    super.onInit();
    developer.log('[RT] RequestsRealtimeService init hash=$hashCode');
    if (Get.isRegistered<RealtimeLifecycleService>()) {
      Get.find<RealtimeLifecycleService>().register(this);
    }
  }

  @override
  bool get isStarted => _started;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _ensureController();
    await _loadArtisanIdAndJoin();
    _rt.connectIfNeeded();
    _listenConnection();
    await _resyncFromRest();
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _statusSub?.cancel();
    _statusSub = null;
    _unregisterEvents();
    _joinedRooms = false;
    _eventsRegistered = false;
    resetForLogout();
  }

  void _listenConnection() {
    _statusSub?.cancel();
    _statusSub = _rt.status.stream.listen((status) {
      if (status == SocketStatus.connected) {
        _registerEvents();
        _maybeJoinRooms();
        _resyncFromRest();
      } else {
        _joinedRooms = false;
        _unregisterEvents();
        _rt.connectIfNeeded();
      }
    });
    if (_rt.status.value == SocketStatus.connected) {
      _registerEvents();
      _maybeJoinRooms();
      _resyncFromRest();
    }
  }

  void _registerEvents() {
    if (_eventsRegistered) return;
    developer.log('[RT] RequestsRealtimeService listening for request events');
    _rt.onEvent(RealtimeEvents.requestNew, (data) {
      _handleIncoming(
        data,
        forceList: _requestsController?.newRequests,
      );
    });
    _rt.onEvent(RealtimeEvents.requestAccepted, _handleIncoming);
    _rt.onEvent(RealtimeEvents.requestRejected, _handleIncoming);
    _rt.onEvent(RealtimeEvents.requestCancelled, _handleIncoming);
    _rt.onEvent(RealtimeEvents.requestCanceled, _handleIncoming);
    _rt.onEvent(RealtimeEvents.requestUpdated, _handleIncoming);
    _rt.onEvent(RealtimeEvents.requestInProgress, _handleIncoming);
    _rt.onEvent(RealtimeEvents.requestCompleted, _handleIncoming);
    _eventsRegistered = true;
  }

  void _unregisterEvents() {
    if (!_eventsRegistered) return;
    _rt.offEvent(RealtimeEvents.requestNew);
    _rt.offEvent(RealtimeEvents.requestAccepted);
    _rt.offEvent(RealtimeEvents.requestRejected);
    _rt.offEvent(RealtimeEvents.requestCancelled);
    _rt.offEvent(RealtimeEvents.requestCanceled);
    _rt.offEvent(RealtimeEvents.requestUpdated);
    _rt.offEvent(RealtimeEvents.requestInProgress);
    _rt.offEvent(RealtimeEvents.requestCompleted);
    _eventsRegistered = false;
  }

  void _handleIncoming(
    dynamic payload, {
    RxList<Map<String, dynamic>>? forceList,
  }) {
    _ensureController();
    final data = _normalizePayload(payload);
    if (data == null) return;
    final status = (data['status'] ?? '').toString().toLowerCase();
    final target =
        forceList ??
        _targetListByStatus(status) ??
        _requestsController?.newRequests;

    developer.log('[RT] Incoming request event: $status => $data');
    if (target == null) return;

    _removeFromAll(data);
    _upsert(target, data, insertFirst: true);
  }

  RxList<Map<String, dynamic>>? _targetListByStatus(String status) {
    _ensureController();
    if (_requestsController == null) return null;
    if (status.isEmpty) return _requestsController!.newRequests;
    if (status == 'cancelled' || status == 'completed' || status == 'done') {
      return _requestsController!.historyRequests;
    }
    if (status == 'accepted' ||
        status == 'on_the_way' ||
        status == 'on the way' ||
        status == 'working' ||
        status == 'in_progress') {
      return _requestsController!.activeRequests;
    }
    return _requestsController!.newRequests;
  }

  void _removeFromAll(Map<String, dynamic> data) {
    final id = (data['_id'] ?? data['id'] ?? '').toString();
    if (id.isEmpty || _requestsController == null) return;
    _requestsController!.newRequests.removeWhere(
      (e) => (e['_id'] ?? e['id'] ?? '').toString() == id,
    );
    _requestsController!.activeRequests.removeWhere(
      (e) => (e['_id'] ?? e['id'] ?? '').toString() == id,
    );
    _requestsController!.historyRequests.removeWhere(
      (e) => (e['_id'] ?? e['id'] ?? '').toString() == id,
    );
  }

  String _upsert(
    RxList<Map<String, dynamic>> list,
    Map<String, dynamic> data, {
    bool insertFirst = false,
  }) {
    final id = (data['_id'] ?? data['id'] ?? '').toString();
    if (id.isEmpty) return '';
    final index = list.indexWhere(
      (e) => (e['_id'] ?? e['id'] ?? '').toString() == id,
    );
    if (index >= 0) {
      list[index] = {...list[index], ...data};
      list.refresh();
      return id;
    }
    if (insertFirst) {
      list.insert(0, data);
    } else {
      list.add(data);
    }
    return id;
  }

  Future<void> _resyncFromRest() async {
    final now = DateTime.now();
    if (_lastRestSyncAt != null &&
        now.difference(_lastRestSyncAt!).inSeconds < 20) {
      return;
    }
    if (_inflightSync != null) {
      return _inflightSync;
    }
    _lastRestSyncAt = now;
    _inflightSync = _performResync().whenComplete(() {
      _inflightSync = null;
    });
    return _inflightSync;
  }

  Future<void> _performResync() async {
    _ensureController();
    if (_requestsController == null) return;
    await Future.wait([
      _requestsController!.fetchNewRequests(),
      _requestsController!.fetchActiveRequests(),
      _requestsController!.fetchHistoryRequests(),
    ]);
  }

  void _ensureController() {
    if (_requestsController != null) return;
    if (Get.isRegistered<ArtisanRequestsController>()) {
      _requestsController ??= Get.find<ArtisanRequestsController>();
    } else {
      _requestsController ??= Get.put<ArtisanRequestsController>(
        ArtisanRequestsController(),
        permanent: true,
      );
    }
  }

  void _showInstantNotification(Map<String, dynamic> data) {
    final customer = data['customer'] is Map
        ? data['customer']['name']
        : data['customerName'] ??
            data['customer'] ??
            data['customerId'] ??
            AppStrings.unknownCustomer.tr;
    final service = data['serviceType'] ??
        data['serviceName'] ??
        (data['service'] is Map ? data['service']['name'] : null) ??
        AppStrings.unknownService.tr;
    final message = AppStrings.newRequestNotification.trParams({
      'customer': customer.toString(),
      'service': service.toString(),
    });
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;
    AppSnackBar.show(
      AppStrings.notifications.tr,
      message,
      type: SnackBarType.info,
      duration: const Duration(seconds: 5),
    );
  }

  Map<String, dynamic>? _normalizePayload(dynamic payload) {
    if (payload is Map) {
      final data = Map<String, dynamic>.from(payload);
      if (data['request'] is Map) {
        return Map<String, dynamic>.from(data['request'] as Map);
      }
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    if (payload is String) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          return _normalizePayload(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _loadArtisanIdAndJoin() async {
    await refreshArtisanProfile(forceJoin: true);
  }

  Future<void> refreshArtisanProfile({bool forceJoin = false}) async {
    final prefs = AppPrefs();
    await prefs.init();
    final cached = prefs.getString(kCachedProfileKey);
    final id = _extractArtisanIdFromCache(cached);
    if (id == null || id.isEmpty) return;
    final hasChanged = id != _artisanId;
    if (forceJoin || hasChanged) {
      _joinedRooms = false;
    }
    _artisanId = id;
    _maybeJoinRooms();
  }

  String? _extractArtisanIdFromCache(String? cached) {
    if (cached == null || cached.isEmpty) return null;
    try {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['_id'] ?? decoded['id'] ?? decoded['artisanId'];
        if (id != null) {
          final strId = id.toString();
          if (strId.isNotEmpty) {
            return strId;
          }
        }
      }
    } catch (_) {
      // ignore cache decode errors
    }
    return null;
  }

  void _maybeJoinRooms() {
    if (_joinedRooms) return;
    if (_artisanId == null || _artisanId!.isEmpty) return;
    if (_rt.status.value != SocketStatus.connected) return;
    developer.log('[RT] Joining artisan and user rooms for $_artisanId');
    _rt.emit('join', {'room': 'artisan:$_artisanId', 'userId': _artisanId});
    _rt.emit('join', {'room': 'user:$_artisanId', 'userId': _artisanId});
    _joinedRooms = true;
  }

  @override
  void onClose() {
    _statusSub?.cancel();
    super.onClose();
  }

  /// ??????? ??? ????? ???? ?????? ???? ?? ???? ?????? ??????? ??????.
  void resetForLogout() {
    _artisanId = null;
    _joinedRooms = false;
  }
}


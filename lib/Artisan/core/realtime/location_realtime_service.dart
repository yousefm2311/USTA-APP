import 'dart:async';

import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/events.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

typedef LocationProvider = Future<Map<String, double>?> Function();

/// Handles realtime artisan location streaming + REST fallback.
class LocationRealtimeService extends GetxService
    implements RealtimeAwareService {
  final RealtimeController _rt = Get.find<RealtimeController>(tag: 'artisan');

  final Rxn<IncomingLocation> lastIncoming = Rxn<IncomingLocation>();
  final Rxn<LocationAck> lastAck = Rxn<LocationAck>();
  final List<PendingLocation> _pending = [];
  Timer? _streamTimer;
  LocationProvider? _provider;
  StreamSubscription<SocketStatus>? _statusSub;
  bool _started = false;
  bool _eventsRegistered = false;
  String? _activeRequestId;
  DateTime? _lastRestFallbackAt;

  @override
  bool get isStarted => _started;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _statusSub?.cancel();
    _statusSub = _rt.status.stream.listen((status) {
      if (status == SocketStatus.connected) {
        _registerEvents();
        _flushPending();
      } else {
        _unregisterEvents();
      }
    });
    if (_rt.status.value == SocketStatus.connected) {
      _registerEvents();
      _flushPending();
    }
  }

  @override
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _statusSub?.cancel();
    _statusSub = null;
    _unregisterEvents();
    stopStreaming();
    _pending.clear();
    _activeRequestId = null;
  }

  /// Set the requestId that should be attached to outgoing location:update.
  void setActiveRequest(String? requestId) {
    _activeRequestId = requestId;
  }

  /// Start periodic streaming using the provided location source.
  void startStreaming(
    LocationProvider provider, {
    Duration interval = const Duration(seconds: 5),
    bool fallbackToRest = false,
    String? requestId,
  }) {
    _provider = provider;
    _activeRequestId = requestId ?? _activeRequestId;
    if (!_started) return;
    _streamTimer?.cancel();
    _streamTimer =
        Timer.periodic(interval, (_) => _tick(fallbackToRest: fallbackToRest));
  }

  void stopStreaming() {
    _streamTimer?.cancel();
    _streamTimer = null;
  }

  Future<void> _tick({bool fallbackToRest = false}) async {
    if (_provider == null) return;
    final location = await _provider!.call();
    if (location == null) return;
    sendLocation(location, fallbackToRest: fallbackToRest);
  }

  /// Send a location update (optionally with a specific requestId).
  void sendLocation(
    Map<String, double> location, {
    String? requestId,
    bool fallbackToRest = false,
  }) {
    final lat = location['lat'] ?? location['latitude'];
    final lng = location['lng'] ?? location['longitude'];
    if (lat == null || lng == null) return;
    final payload = PendingLocation(
      lat: lat,
      lng: lng,
      requestId: requestId ?? _activeRequestId,
      fallbackToRest: fallbackToRest,
    );
    _dispatch(payload);
  }

  void sendLocationForRequest({
    required String requestId,
    required double lat,
    required double lng,
    bool fallbackToRest = false,
  }) {
    _dispatch(PendingLocation(
      lat: lat,
      lng: lng,
      requestId: requestId,
      fallbackToRest: fallbackToRest,
    ));
  }

  void _dispatch(PendingLocation payload) {
    if (!_started || _rt.status.value != SocketStatus.connected) {
      _pending.add(payload);
      if (payload.fallbackToRest) {
        _pushRestFallback(payload);
      }
      return;
    }
    _emit(payload);
  }

  void _emit(PendingLocation payload) {
    _rt.emit(
      RealtimeEvents.locationUpdate,
      payload.toMap(),
      ack: (resp) {
        lastAck.value = LocationAck.from(payload, resp);
      },
    );
  }

  void _flushPending() {
    if (!_started || _pending.isEmpty) return;
    final batch = List<PendingLocation>.from(_pending);
    _pending.clear();
    for (final item in batch) {
      _emit(item);
    }
  }

  Future<void> _pushRestFallback(PendingLocation payload) async {
    final now = DateTime.now();
    if (_lastRestFallbackAt != null &&
        now.difference(_lastRestFallbackAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastRestFallbackAt = now;
    try {
      await ApiClient.instance.put(ApiEndpoints.setLocation, data: {
        'lat': payload.lat,
        'lng': payload.lng,
      });
    } catch (_) {
      // Ignore REST fallback failures silently.
    }
  }

  void _registerEvents() {
    if (_eventsRegistered) return;
    _rt.onEvent('artisan:location', _handleIncoming);
    _rt.onEvent('location:ack', _handleAck);
    _eventsRegistered = true;
  }

  void _unregisterEvents() {
    if (!_eventsRegistered) return;
    _rt.offEvent('artisan:location');
    _rt.offEvent('location:ack');
    _eventsRegistered = false;
  }

  void _handleIncoming(dynamic data) {
    if (data is! Map) return;
    final map = data.cast<String, dynamic>();
    final lat = double.tryParse((map['lat'] ?? map['latitude'] ?? '').toString());
    final lng = double.tryParse((map['lng'] ?? map['longitude'] ?? '').toString());
    if (lat == null || lng == null) return;
    final requestId = (map['requestId'] ?? map['request_id'] ?? '').toString();
    final updatedAt = DateTime.tryParse(
      (map['updatedAt'] ?? map['timestamp'] ?? '').toString(),
    );
    lastIncoming.value = IncomingLocation(
      requestId: requestId.isEmpty ? null : requestId,
      lat: lat,
      lng: lng,
      updatedAt: updatedAt,
    );
  }

  void _handleAck(dynamic data) {
    lastAck.value = LocationAck.from(null, data);
  }

  @override
  void onClose() {
    stopStreaming();
    _statusSub?.cancel();
    super.onClose();
  }
}

class PendingLocation {
  final double lat;
  final double lng;
  final String? requestId;
  final bool fallbackToRest;

  PendingLocation({
    required this.lat,
    required this.lng,
    this.requestId,
    this.fallbackToRest = false,
  });

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        if (requestId != null && requestId!.isNotEmpty) 'requestId': requestId,
      };
}

class IncomingLocation {
  final String? requestId;
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  IncomingLocation({
    required this.requestId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });
}

class LocationAck {
  final String? requestId;
  final double? lat;
  final double? lng;
  final dynamic raw;
  final DateTime receivedAt;

  LocationAck({
    required this.requestId,
    required this.lat,
    required this.lng,
    required this.raw,
    required this.receivedAt,
  });

  factory LocationAck.from(PendingLocation? source, dynamic raw) {
    double? lat;
    double? lng;
    String? requestId = source?.requestId;
    if (raw is Map) {
      lat = double.tryParse((raw['lat'] ?? raw['latitude'] ?? '').toString());
      lng = double.tryParse((raw['lng'] ?? raw['longitude'] ?? '').toString());
      final rid = (raw['requestId'] ?? raw['request_id'] ?? '').toString();
      if (rid.isNotEmpty) requestId = rid;
    }
    return LocationAck(
      requestId: requestId,
      lat: lat ?? source?.lat,
      lng: lng ?? source?.lng,
      raw: raw,
      receivedAt: DateTime.now(),
    );
  }
}


import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:usta/Artisan/core/realtime/location_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class ArtisanRequestMapView extends StatefulWidget {
  const ArtisanRequestMapView({super.key});

  @override
  State<ArtisanRequestMapView> createState() => _ArtisanRequestMapViewState();
}

class _ArtisanRequestMapViewState extends State<ArtisanRequestMapView> {
  static const String _googleMapsKey = 'AIzaSyBXSeADUrxqZFLpHMQw6zKIxJLeXSCHI1Y';
  static const LatLng _fallbackCenter = LatLng(30.0444, 31.2357); // Cairo

  final Completer<GoogleMapController> _mapController = Completer();
  final LocationRealtimeService _locationRt = Get.find<LocationRealtimeService>();
  final RealtimeController _rt = Get.find<RealtimeController>(tag: 'artisan');
  final Dio _directionsDio = Dio();

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<SocketStatus>? _statusSub;
  Worker? _incomingWorker;
  Worker? _ackWorker;

  LatLng? _artisan;
  LatLng? _destination;
  LatLng? _echoLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _permissionDenied = false;
  bool _loadingRoute = false;
  bool _fitDone = false;
  DateTime? _lastSendAt;
  DateTime? _lastRouteAt;
  String _requestId = '';
  String _address = '';
  String? _lastAck;

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _parseArgs();
    _locationRt.setActiveRequest(_requestId);
    _listenRealtime();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _statusSub?.cancel();
    _incomingWorker?.dispose();
    _ackWorker?.dispose();
    _locationRt.stopStreaming();
    _locationRt.setActiveRequest(null);
    super.dispose();
  }

  void _parseArgs() {
    final args = Get.arguments;
    if (args is Map) {
      final map = (args['request'] as Map?)?.cast<String, dynamic>() ??
          args.cast<String, dynamic>();
      _requestId =
          (args['requestId'] ?? map['_id'] ?? map['id'] ?? '').toString();
      _address = (map['address'] ?? map['locationName'] ?? '').toString();
      _destination = _parseLocation(map['location'] ?? args['location']);
    }
  }

  LatLng? _parseLocation(dynamic loc) {
    if (loc is Map) {
      if (loc['coordinates'] is List && (loc['coordinates'] as List).length >= 2) {
        final coords = (loc['coordinates'] as List);
        final first = double.tryParse(coords[0].toString());
        final second = double.tryParse(coords[1].toString());
        if (first != null && second != null) {
          // Default to [lng, lat] (GeoJSON). Flip only when we are sure the order is [lat, lng].
          final firstIsLat = first.abs() <= 90 && second.abs() > 90;
          final secondIsLat = second.abs() <= 90 && first.abs() > 90;
          if (firstIsLat) {
            return LatLng(first, second);
          }
          if (secondIsLat) {
            return LatLng(second, first);
          }
          // If both look like lat (<=90), still prefer GeoJSON ordering [lng, lat].
          return LatLng(second, first);
        }
      }
      final lat = loc['lat'] ?? loc['latitude'];
      final lng = loc['lng'] ?? loc['longitude'];
      if (lat != null && lng != null) {
        final dLat = double.tryParse(lat.toString());
        final dLng = double.tryParse(lng.toString());
        if (dLat != null && dLng != null) return LatLng(dLat, dLng);
      }
    }
    return null;
  }

  void _listenRealtime() {
    _statusSub = _rt.status.stream.listen((status) {
      if (status == SocketStatus.connected) {
        _subscribeToRequestRoom();
      }
    });
    if (_rt.status.value == SocketStatus.connected) {
      _subscribeToRequestRoom();
    }
    _incomingWorker =
        ever<IncomingLocation?>(_locationRt.lastIncoming, (incoming) {
      if (incoming == null) return;
      final reqId = (incoming.requestId ?? '').toString();
      if (_requestId.isNotEmpty && reqId.isNotEmpty && reqId != _requestId) {
        return;
      }
      _echoLocation = LatLng(incoming.lat, incoming.lng);
      _updateMarkers();
    });
    _ackWorker = ever<LocationAck?>(_locationRt.lastAck, (ack) {
      if (ack == null) return;
      final reqId = (ack.requestId ?? '').toString();
      if (_requestId.isNotEmpty && reqId.isNotEmpty && reqId != _requestId) {
        return;
      }
      final ackLat = ack.lat;
      final ackLng = ack.lng;
      if (ackLat != null && ackLng != null) {
        _lastAck =
            'آخر تأكيد: ${ackLat.toStringAsFixed(5)}, ${ackLng.toStringAsFixed(5)}';
      } else {
        _lastAck = 'تم تأكيد آخر موقع';
      }
      if (mounted) setState(() {});
    });
  }

  void _subscribeToRequestRoom() {
    if (_requestId.isEmpty) return;
    _rt.emit('chat:subscribe', {'requestId': _requestId});
  }

  Future<void> _startLocationStream() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _permissionDenied = true);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _permissionDenied = true);
      return;
    }
    final current = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    _onPosition(current);
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position pos) {
    _artisan = LatLng(pos.latitude, pos.longitude);
    _fitDone = false;
    _updateMarkers();
    _sendLocation(_artisan!);
    _maybeRefreshRoute(force: true);
  }

  void _sendLocation(LatLng pos) {
    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastSendAt = now;
    if (_requestId.isNotEmpty) {
      _locationRt.sendLocationForRequest(
        requestId: _requestId,
        lat: pos.latitude,
        lng: pos.longitude,
        fallbackToRest: _rt.status.value != SocketStatus.connected,
      );
    } else {
      _locationRt.sendLocation(
        {'lat': pos.latitude, 'lng': pos.longitude},
        fallbackToRest: _rt.status.value != SocketStatus.connected,
      );
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    if (_destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: InfoWindow(
            title: 'موقع الطلب',
            snippet: _address.isNotEmpty ? _address : null,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
    if (_artisan != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _artisan!,
          infoWindow: const InfoWindow(title: 'موقعي'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    if (_echoLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('echo'),
          position: _echoLocation!,
          infoWindow: const InfoWindow(title: 'موقع السيرفر'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }
    setState(() {
      _markers = markers;
    });
    _maybeFitBounds();
  }

  Future<void> _maybeRefreshRoute({bool force = false}) async {
    if (_artisan == null || _destination == null) return;
    final now = DateTime.now();
    if (!force &&
        _lastRouteAt != null &&
        now.difference(_lastRouteAt!) < const Duration(seconds: 6)) {
      return;
    }
    _lastRouteAt = now;
    await _buildRoute(_artisan!, _destination!);
  }

  Future<void> _buildRoute(LatLng origin, LatLng dest) async {
    setState(() => _loadingRoute = true);
    try {
      final points = await _fetchRoute(origin, dest);
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: primaryBlue,
            width: 5,
          ),
        };
      });
    } catch (_) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [origin, dest],
            color: primaryBlue,
            width: 5,
          ),
        };
      });
    } finally {
      setState(() => _loadingRoute = false);
      _maybeFitBounds();
    }
  }

  Future<List<LatLng>> _fetchRoute(LatLng origin, LatLng dest) async {
    // 1) Try Google Directions (requires enabled Directions API on the key)
    try {
      final response = await _directionsDio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${dest.latitude},${dest.longitude}',
          'mode': 'driving',
          'key': _googleMapsKey,
        },
      );
      if (response.data is Map &&
          response.data['routes'] is List &&
          (response.data['routes'] as List).isNotEmpty) {
        final first = response.data['routes'][0];
        final encoded = first['overview_polyline']?['points']?.toString() ?? '';
        if (encoded.isNotEmpty) {
          return _decodePolyline(encoded);
        }
      }
    } catch (_) {
      // fall through to OSRM fallback
    }

    // 2) Fallback to free OSRM routing (no key needed)
    try {
      final osrm = await _directionsDio.get(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}',
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
        },
      );
      if (osrm.data is Map &&
          osrm.data['routes'] is List &&
          (osrm.data['routes'] as List).isNotEmpty) {
        final encoded = osrm.data['routes'][0]['geometry']?.toString() ?? '';
        if (encoded.isNotEmpty) {
          return _decodePolyline(encoded);
        }
      }
    } catch (_) {
      // ignore and fallback to straight line
    }

    // 3) Straight line fallback if both failed.
    return [origin, dest];
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(
        LatLng(lat / 1e5, lng / 1e5),
      );
    }
    return points;
  }

  Future<void> _maybeFitBounds() async {
    if (_fitDone) return;
    if (_destination == null || _artisan == null) return;
    if (!_mapController.isCompleted) return;
    final ctrl = await _mapController.future;
    final sw = LatLng(
      min(_destination!.latitude, _artisan!.latitude),
      min(_destination!.longitude, _artisan!.longitude),
    );
    final ne = LatLng(
      max(_destination!.latitude, _artisan!.latitude),
      max(_destination!.longitude, _artisan!.longitude),
    );
    await ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne),
        60,
      ),
    );
    _fitDone = true;
  }

  Future<void> _centerOnMe() async {
    if (_artisan == null || !_mapController.isCompleted) return;
    final ctrl = await _mapController.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngZoom(_artisan!, 16));
  }

  Future<void> _centerOnDestination() async {
    if (_destination == null || !_mapController.isCompleted) return;
    final ctrl = await _mapController.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngZoom(_destination!, 16));
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _destination ?? _artisan ?? _fallbackCenter;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'خريطة الطلب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapActionButton(
            icon: Icons.navigation,
            label: 'ملاءمة المسار',
            onTap: _maybeFitBounds,
          ),
          const SizedBox(height: 10),
          _MapActionButton(
            icon: Icons.my_location,
            label: 'موقعي',
            onTap: _centerOnMe,
          ),
          const SizedBox(height: 10),
          _MapActionButton(
            icon: Icons.location_pin,
            label: 'موقع الطلب',
            onTap: _centerOnDestination,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_permissionDenied)
            Container(
              width: double.infinity,
              color: Colors.redAccent.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              child: const Text(
                'من فضلك فعّل صلاحيات الموقع لعرض مسار الطلب وتحديث موقعك.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialTarget,
                    zoom: 13,
                  ),
                  onMapCreated: (ctrl) => _mapController.complete(ctrl),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  compassEnabled: true,
                  trafficEnabled: true,
                ),
                if (_loadingRoute)
                  const Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رقم الطلب: ${_requestId.isEmpty ? '-' : _requestId}',
                  style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold),
                ),
                if (_address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _address,
                      style: AppTextStyles.body(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  _lastAck ?? 'في انتظار تأكيد الموقع من الخادم...',
                  style: AppTextStyles.body(context).copyWith(
                    color: _lastAck == null ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: label,
      onPressed: onTap,
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'Cairo'),
      ),
      icon: Icon(icon),
    );
  }
}


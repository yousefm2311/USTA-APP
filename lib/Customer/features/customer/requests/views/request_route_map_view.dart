import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RequestRouteMapView extends StatefulWidget {
  const RequestRouteMapView({
    super.key,
    required this.artisanLat,
    required this.artisanLng,
    this.userLat,
    this.userLng,
    this.artisanName,
    this.artisanProfession,
    this.artisanLocation,
  });

  final double artisanLat;
  final double artisanLng;
  final double? userLat;
  final double? userLng;
  final String? artisanName;
  final String? artisanProfession;
  final Map<String, dynamic>? artisanLocation;

  @override
  State<RequestRouteMapView> createState() => _RequestRouteMapViewState();
}

class _RequestRouteMapViewState extends State<RequestRouteMapView> {
  GoogleMapController? _mapController;
  List<LatLng> _route = [];
  bool _loading = true;
  LatLng? _currentUser;
  Timer? _fitTimer;

  LatLng get _artisan => _resolveArtisan();
  LatLng? get _user => _currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.userLat != null && widget.userLng != null) {
      _currentUser = LatLng(widget.userLat!, widget.userLng!);
    }
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    _route = <LatLng>[_artisan];
    _loading = true;

    LatLng? user = _user;
    if (user == null) {
      try {
        final perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition();
          user = LatLng(pos.latitude, pos.longitude);
        }
      } catch (_) {}
    }

    if (user != null) {
      _currentUser = user;
    }
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _fit();
      return;
    }
    if (!mounted) return;
    setState(() {
      _route = <LatLng>[user!, _artisan];
      _loading = true;
    });
    _fit();
    try {
      final from = user;
      final to = _artisan;
      final url =
          'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson';
      final resp = await Dio().get(url);
      final data = resp.data;
      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final geom = routes.first['geometry'];
        if (geom is Map && geom['coordinates'] is List) {
          final coords = geom['coordinates'] as List;
          final pts = coords
              .where((c) => c is List && c.length >= 2)
              .map<LatLng>(
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              )
              .toList();
          if (pts.length >= 2) {
            if (!mounted) return;
            setState(() {
              _route = pts;
              _loading = false;
            });
            _fit();
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _route = <LatLng>[if (user != null) user, _artisan];
        _loading = false;
      });
      _fit();
    }
  }

  void _fit() {
    if (!mounted || _mapController == null || _route.isEmpty) return;
    if (_route.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_route.first, 12),
      );
      return;
    }
    final bounds = _expandBounds(_computeBounds(_route));
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('artisan'),
        position: _artisan,
        infoWindow: InfoWindow(
          title: widget.artisanName ?? 'الفني'.tr,
          snippet: widget.artisanProfession,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
    if (_user != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _user!,
          infoWindow: InfoWindow(title: 'موقعي'.tr),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    final polylines = <Polyline>{
      if (_route.length >= 2)
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blueAccent,
          width: 5,
          points: _route,
          geodesic: true,
        ),
    };

    final initial = _user ?? _artisan;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المسار بينك وبين الفني'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            markers: markers,
            polylines: polylines,
            onMapCreated: (c) {
              _mapController = c;
              _fitTimer?.cancel();
              _fitTimer = Timer(const Duration(milliseconds: 300), _fit);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (_loading)
            const Positioned(
              top: 16,
              right: 16,
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fitTimer?.cancel();
    _mapController = null;
    super.dispose();
  }

  LatLngBounds _computeBounds(List<LatLng> pts) {
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  LatLng _resolveArtisan() {
    final lat = widget.artisanLat;
    final lng = widget.artisanLng;
    return LatLng(lat, lng);
  }

  double? _extractCoord(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (v != null) {
        final parsed = double.tryParse(v.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  LatLngBounds _expandBounds(LatLngBounds bounds) {
    const double minDelta = 0.002;
    final latSpan = (bounds.northeast.latitude - bounds.southwest.latitude)
        .abs();
    final lngSpan = (bounds.northeast.longitude - bounds.southwest.longitude)
        .abs();
    final expandLat = latSpan < minDelta ? minDelta : latSpan * 0.15;
    final expandLng = lngSpan < minDelta ? minDelta : lngSpan * 0.15;
    return LatLngBounds(
      southwest: LatLng(
        bounds.southwest.latitude - expandLat,
        bounds.southwest.longitude - expandLng,
      ),
      northeast: LatLng(
        bounds.northeast.latitude + expandLat,
        bounds.northeast.longitude + expandLng,
      ),
    );
  }
}

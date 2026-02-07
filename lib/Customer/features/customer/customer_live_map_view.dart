import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/customer_artisan_details_view.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerLiveMapView extends StatefulWidget {
  const CustomerLiveMapView({
    super.key,
    this.focusLat,
    this.focusLng,
    this.focusTitle,
    this.focusSnippet,
    this.drawRoute = true,
    this.initialLat,
    this.initialLng,
    this.initialRadiusKm,
  });

  final double? focusLat;
  final double? focusLng;
  final String? focusTitle;
  final String? focusSnippet;
  final bool drawRoute;
  final double? initialLat;
  final double? initialLng;
  final double? initialRadiusKm;

  @override
  State<CustomerLiveMapView> createState() => _CustomerLiveMapViewState();
}

class _CustomerLiveMapViewState extends State<CustomerLiveMapView> {
  GoogleMapController? mapController;
  static const LatLng _defaultCenter = LatLng(24.7136, 46.6753);
  final CustomerMarketingController marketing =
      Get.find<CustomerMarketingController>();

  final Completer<void> _firstLoad = Completer<void>();
  Worker? _liveLocationsWorker;
  Worker? _liveCenterWorker;
  Worker? _liveErrorWorker;
  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};
  LatLng _initialCamera = _defaultCenter;
  LatLng? _userPosition;
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;
  bool _routeRequested = false;
  BitmapDescriptor? _markerIcon;
  String _liveError = '';
  LatLng? _focusPoint;
  bool _hasCenteredMap = false;

  Color get bg => const Color(0xFF050816);

  @override
  void initState() {
    super.initState();
    _bindLiveStreams();
    _initMarkerIcon();
    _load();
  }

  void _bindLiveStreams() {
    _liveLocationsWorker = ever<List<Map<String, dynamic>>>(
      marketing.liveLocations,
      (_) => _refreshMarkersAndCamera(),
    );
    _liveCenterWorker = ever<String?>(
      marketing.liveCenter,
      (_) => _centerOnLiveCenter(),
    );
    _liveErrorWorker = ever<String>(
      marketing.liveError,
      (val) {
        if (!mounted) return;
        setState(() => _liveError = val);
      },
    );
  }

  @override
  void dispose() {
    _liveLocationsWorker?.dispose();
    _liveCenterWorker?.dispose();
    _liveErrorWorker?.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _initMarkerIcon() async {
    try {
      final icon = await _bitmapFromAsset('assets/images/marker.png', width: 96);
      if (mounted) {
        setState(() => _markerIcon = icon);
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "الخريطة المباشرة".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: FutureBuilder<void>(
        future: _firstLoad.future,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_liveError.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _liveError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            );
          }

          return GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _initialCamera, zoom: 12),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              mapController = controller;
              if (!_hasCenteredMap) {
                _centerOnLiveCenter();
                _hasCenteredMap = true;
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          );
        },
      ),
    );
  }

  List<Marker> _buildMarkers(List<Map<String, dynamic>> data) {
    return data.map<Marker>((item) {
      final id =
          item['_id']?.toString() ??
          item['id']?.toString() ??
          item['name']?.toString() ??
          UniqueKey().toString();
      double? lat;
      double? lng;
      if (item['location'] is Map) {
        final loc = item['location'] as Map;
        lat = _extractCoord(loc.cast<String, dynamic>(), 'lat', 'latitude');
        lng = _extractCoord(loc.cast<String, dynamic>(), 'lng', 'longitude');
        if (lat == null &&
            lng == null &&
            loc['coordinates'] is List &&
            (loc['coordinates'] as List).length >= 2) {
          final coords = loc['coordinates'] as List;
          if (coords[1] is num && coords[0] is num) {
            lat = (coords[1] as num).toDouble();
            lng = (coords[0] as num).toDouble();
          }
        }
      }
      lat ??= _extractCoord(item, 'lat', 'latitude');
      lng ??= _extractCoord(item, 'lng', 'longitude');
      LatLng position = _defaultCenter;
      if (lat != null && lng != null) {
        position = LatLng(lat, lng);
      }
      return Marker(
        markerId: MarkerId(id),
        position: position,
        icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: item['name']?.toString() ?? 'موقع الحرفي'.tr,
          snippet: (item['profession'] ?? item['serviceType'] ?? item['status'])
              ?.toString(),
        ),
        onTap: () {
          final artisanId = item['_id']?.toString() ?? item['id']?.toString();
          Get.to(
            () => CustomerArtisanDetailsView(
              artisanId: artisanId ?? '',
              artisan: item,
            ),
          );
        },
      );
    }).toList();
  }

  double? _extractCoord(Map<String, dynamic> item, String key1, String key2) {
    final val = item[key1] ?? item[key2];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  Future<void> _load() async {
    const double fallbackLat = 30.756338;
    const double fallbackLng = 31.534981;
    double? lat = widget.initialLat;
    double? lng = widget.initialLng;

    try {
      final position = await marketing.getCurrentPositionSafely();
      lat ??= position?.latitude;
      lng ??= position?.longitude;

      lat ??= fallbackLat;
      lng ??= fallbackLng;

      _initialCamera = LatLng(lat, lng);

      await marketing.fetchLiveMap(
        lat: lat,
        lng: lng,
        radiusKm: widget.initialRadiusKm,
      );
      if (marketing.liveLocations.isEmpty && marketing.liveError.value.isEmpty) {
        marketing.liveError.value =
            'لم يتم العثور على مواقع نشطة في الوقت الحالي. تأكد من تشغيل الموقع ثم أعد المحاولة.'
                .tr;
      }
      if (position != null) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
        });
      }
      _refreshMarkersAndCamera();
    } catch (e) {
      marketing.liveError.value = e.toString();
      AppSnackBar.show('خطأ'.tr, e.toString());
    } finally {
      if (!_firstLoad.isCompleted) _firstLoad.complete();
    }
  }

  Future<void> _fetchRoute(LatLng focus) async {
    _routeLoading = true;
    try {
      final from = _userPosition!;
      final url =
          'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${focus.longitude},${focus.latitude}?overview=full&geometries=geojson';
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
              _routePoints = pts;
            });
            return;
          }
        }
      }
    } catch (_) {
    } finally {
      _routeLoading = false;
      if (!mounted) return;
      _rebuildPolylines();
    }
  }

  void _ensureRoute(LatLng focus) {
    if (_routeRequested) return;
    _routeRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRoute(focus).whenComplete(() {
        _routeRequested = false;
      });
    });
  }

  void _refreshMarkersAndCamera() {
    if (!mounted) return;
    final markers = _buildMarkers(marketing.liveLocations);

    if (widget.focusLat != null && widget.focusLng != null) {
      _focusPoint = LatLng(widget.focusLat!, widget.focusLng!);
      markers.insert(
        0,
        Marker(
          markerId: const MarkerId('artisan_focus'),
          position: _focusPoint!,
          infoWindow: InfoWindow(
            title: widget.focusTitle ?? 'الحرفي'.tr,
            snippet: widget.focusSnippet,
          ),
          icon: _markerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
        ),
      );
    } else {
      _focusPoint = markers.isNotEmpty ? markers.first.position : null;
    }

    setState(() {
      _markers = markers.toSet();
    });

    if (!_hasCenteredMap) {
      final target = _focusPoint ?? _initialCamera;
      _moveCamera(target);
      _hasCenteredMap = true;
    }

    _rebuildPolylines();
    if (widget.drawRoute &&
        _focusPoint != null &&
        _userPosition != null &&
        !_routeLoading &&
        _routePoints.isEmpty) {
      _ensureRoute(_focusPoint!);
    }
  }

  void _rebuildPolylines() {
    if (!mounted) return;
    if (!widget.drawRoute || _focusPoint == null || _userPosition == null) {
      setState(() => _polylines = <Polyline>{});
      return;
    }
    final points = _routePoints.length > 1
        ? _routePoints
        : <LatLng>[_userPosition!, _focusPoint!];
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blueAccent,
          width: 4,
          geodesic: true,
          points: points,
        ),
      };
    });
  }

  void _moveCamera(LatLng target) {
    _initialCamera = target;
    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(target));
    }
  }

  void _centerOnLiveCenter() {
    final centerStr = marketing.liveCenter.value;
    if (centerStr == null) return;
    final parts = centerStr.split(',');
    if (parts.length != 2) return;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return;
    _moveCamera(LatLng(lat, lng));
  }

  Future<BitmapDescriptor> _bitmapFromAsset(String path, {int width = 96}) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final byteData =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}


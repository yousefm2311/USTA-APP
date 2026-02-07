import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/settings/nearby_radius_settings.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerExploreController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topRated = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> nearby = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> areaResults = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> artisanDetail = Rxn<Map<String, dynamic>>();

  final loadingCategories = false.obs;
  final loadingSearch = false.obs;
  final loadingTop = false.obs;
  final loadingNearby = false.obs;
  final loadingDetail = false.obs;
  final loadingArea = false.obs;

  bool _categoriesLoaded = false;
  bool _topRatedLoaded = false;
  bool _nearbyLoaded = false;
  Set<Marker> _cachedNearbyMarkers = <Marker>{};
  String _cachedMarkersKey = '';
  DateTime? _lastLocationWarningAt;

  @override
  void onInit() {
    super.onInit();

    if (!_categoriesLoaded) {
      fetchCategories();
    }

    if (!_topRatedLoaded) {
      fetchTopRated();
    }

    if (!_nearbyLoaded) {
      fetchNearby();
    }
  }

  Future<void> fetchCategories({bool force = false}) async {
    if (_categoriesLoaded && !force) return;

    loadingCategories.value = true;
    try {
      final res = await _repo.api.categories();
      final list = _extractList(res, 'categories');

      categories.assignAll(
        list.map<Map<String, dynamic>>(
          (e) => e is Map<String, dynamic> ? e : {'name': e.toString()},
        ),
      );

      _categoriesLoaded = true;
    } on ApiException catch (e) {
      _handleError(e);
    } finally {
      loadingCategories.value = false;
    }
  }

bool _searchLoaded = false;

  Future<void> searchArtisans({
    String? query,
    String? category,
    bool force = false,
  }) async {
    if (_searchLoaded && !force) return;

    loadingSearch.value = true;

    try {
      final res = await _repo.api.searchArtisans(
        query: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (category != null && category.isNotEmpty) 'category': category,
          if (category != null && category.isNotEmpty) 'serviceName': category,
        },
      );

      final list = _extractList(res, 'artisans');

      searchResults.assignAll(list.cast<Map<String, dynamic>>());

      _searchLoaded = true;
    } on ApiException catch (e) {
      _handleError(e);
      searchResults.clear();
    } finally {
      loadingSearch.value = false;
    }
  }

  Future<void> fetchTopRated({String? category, bool force = false}) async {
    if (_topRatedLoaded && !force && category == null) return;

    loadingTop.value = true;
    try {
      final res = await _repo.api.topRatedArtisans(
        query: {
          if (category != null && category.isNotEmpty) 'category': category,
          if (category != null && category.isNotEmpty) 'serviceName': category,
        },
      );

      final list = _extractList(res, 'artisans');
      topRated.assignAll(list.cast<Map<String, dynamic>>());

      _topRatedLoaded = true;
    } on ApiException catch (e) {
      _handleError(e);
      topRated.clear();
    } finally {
      loadingTop.value = false;
    }
  }

  Future<void> fetchNearby({String? category, bool force = false}) async {
    if (_nearbyLoaded && !force && category == null) return;

    loadingNearby.value = true;
    try {
      Position? pos;
      try {
        pos = await _currentPosition().timeout(
          const Duration(seconds: 6),
          onTimeout: () => null,
        );
      } catch (_) {
        pos = null;
      }

      if (pos == null) {
        try {
          pos = await Geolocator.getLastKnownPosition();
        } catch (_) {
          pos = null;
        }
      }

      pos ??= _fallbackPosition();

      final radiusMeters = await NearbyRadiusSettings.readMeters();

      final res = await _repo.api.nearbyArtisans(
        query: {
          'lat': pos.latitude,
          'lng': pos.longitude,
          if (radiusMeters != null) 'radius': radiusMeters,
          if (category != null && category.isNotEmpty) 'category': category,
          if (category != null && category.isNotEmpty) 'serviceName': category,
        },
      );

      final list = _extractList(res, 'artisans');
      nearby.assignAll(list.cast<Map<String, dynamic>>());

      _nearbyLoaded = true;
    } on ApiException catch (e) {
      _handleError(e);
      nearby.clear();
    } catch (_) {
      nearby.clear();
    } finally {
      loadingNearby.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchArtisanDetails(String id) async {
    loadingDetail.value = true;
    try {
      final res = await _repo.api.artisanDetails(id);
      final data =
          res['artisan'] ??
          (res['data'] is Map ? res['data']['artisan'] : null) ??
          res['data'] ??
          res;

      if (data is Map<String, dynamic>) {
        artisanDetail.value = data;
        return data;
      }
      return null;
    } on ApiException catch (e) {
      _handleError(e);
      return null;
    } finally {
      loadingDetail.value = false;
    }
  }

  Future<void> fetchArea({String? area}) async {
    loadingArea.value = true;
    try {
      final res = await _repo.api.artisansInArea(
        query: {if (area != null && area.isNotEmpty) 'area': area},
      );

      final list = _extractList(res, 'artisans');
      areaResults.assignAll(list.cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      _handleError(e);
      areaResults.clear();
    } finally {
      loadingArea.value = false;
    }
  }

  Map<String, double>? coordsOf(Map<String, dynamic> artisan) {
    try {
      if (artisan['lat'] is num && artisan['lng'] is num) {
        return {
          'lat': (artisan['lat'] as num).toDouble(),
          'lng': (artisan['lng'] as num).toDouble(),
        };
      }

      if (artisan['location'] is Map &&
          artisan['location']['coordinates'] is List &&
          artisan['location']['coordinates'].length >= 2) {
        final coords = artisan['location']['coordinates'];
        return {
          'lat': (coords[1] as num).toDouble(),
          'lng': (coords[0] as num).toDouble(),
        };
      }
    } catch (_) {}
    return null;
  }

  Set<Marker> nearbyMarkers({
    required void Function(Map<String, dynamic> artisan) onTap,
  }) {
    final key = _buildMarkersKey();
    if (key == _cachedMarkersKey) return _cachedNearbyMarkers;

    final markers = <Marker>{};
    for (var i = 0; i < nearby.length; i++) {
      final art = nearby[i];
      final coords = coordsOf(art);
      if (coords == null) continue;

      final lat = coords['lat'];
      final lng = coords['lng'];
      if (lat == null || lng == null) continue;

      final rawId = (art['_id'] ?? art['id'])?.toString().trim();
      final markerId = rawId != null && rawId.isNotEmpty
          ? 'artisan_$rawId'
          : 'nearby_$i';

      markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: art['name']?.toString() ?? 'حرفي'.tr,
            snippet: art['profession']?.toString(),
          ),
          onTap: () => onTap(art),
        ),
      );
    }

    _cachedMarkersKey = key;
    _cachedNearbyMarkers = markers;
    return _cachedNearbyMarkers;
  }

  LatLng? firstNearbyPosition() {
    for (final art in nearby) {
      final coords = coordsOf(art);
      if (coords == null) continue;
      final lat = coords['lat'];
      final lng = coords['lng'];
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  String _buildMarkersKey() {
    if (nearby.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < nearby.length; i++) {
      final art = nearby[i];
      final coords = coordsOf(art);
      if (coords == null) continue;
      final lat = coords['lat'];
      final lng = coords['lng'];
      if (lat == null || lng == null) continue;
      final rawId = (art['_id'] ?? art['id'])?.toString().trim();
      buffer.write(rawId ?? 'idx$i');
      buffer.write(':');
      buffer.write(lat.toStringAsFixed(6));
      buffer.write(',');
      buffer.write(lng.toStringAsFixed(6));
      buffer.write(':');
      buffer.write((art['name'] ?? '').toString());
      buffer.write(':');
      buffer.write((art['profession'] ?? '').toString());
      buffer.write(';');
    }
    return buffer.toString();
  }

  Future<Position?> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showLocationWarning('فعّل خدمة الموقع لاستخدام موقعك الحالي'.tr);
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationWarning('لم يتم السماح بالوصول للموقع'.tr);
        return null;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } on PermissionDeniedException {
      _showLocationWarning('لم يتم السماح بالوصول للموقع'.tr);
      return null;
    } catch (_) {
      return null;
    }
  }

  void _showLocationWarning(String message) {
    final now = DateTime.now();
    if (_lastLocationWarningAt != null &&
        now.difference(_lastLocationWarningAt!) < const Duration(seconds: 30)) {
      return;
    }
    _lastLocationWarningAt = now;
    AppSnackBar.show('تنبيه'.tr, message);
  }

  Position _fallbackPosition() {
    return Position(
      latitude: 30.756338,
      longitude: 31.534981,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  List<dynamic> _extractList(Map<String, dynamic> res, String key) {
    if (res[key] is List) return res[key];
    if (res['data'] is List) return res['data'];
    if (res['data'] is Map && res['data'][key] is List) {
      return res['data'][key];
    }
    return [];
  }

  void _handleError(ApiException e) {
    if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
      Get.find<AuthController>(tag: 'customer').logout(remote: false);
    }

    final msg =
        e.message.isNotEmpty ? e.message : 'تعذر إكمال الطلب'.tr;
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}



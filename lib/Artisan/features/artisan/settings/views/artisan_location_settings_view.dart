import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/features/artisan/profile/controllers/profile_controller.dart';

class ArtisanLocationSettingsView extends StatefulWidget {
  const ArtisanLocationSettingsView({super.key});

  @override
  State<ArtisanLocationSettingsView> createState() =>
      _ArtisanLocationSettingsViewState();
}

class _ArtisanLocationSettingsViewState
    extends State<ArtisanLocationSettingsView> {
  Color get primaryBlue => const Color(0xFF2563EB);

  final ProfileController profileController = Get.find<ProfileController>();

  final Completer<GoogleMapController> _mapController = Completer();
  LatLng _current = const LatLng(30.0444, 31.2357); // Cairo default
  bool _saving = false;
  bool _loadingLocation = false;
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    final loc = profileController.profile['location'];
    if (loc is Map && loc['lat'] != null && loc['lng'] != null) {
      final lat = double.tryParse(loc['lat'].toString());
      final lng = double.tryParse(loc['lng'].toString());
      if (lat != null && lng != null) {
        _setMarker(LatLng(lat, lng));
        return;
      }
    }
    await _useCurrentLocation(fallbackToDefault: true);
  }

  Future<void> _animateTo(LatLng target) async {
    if (_mapController.isCompleted) {
      final ctrl = await _mapController.future;
      await ctrl.animateCamera(CameraUpdate.newLatLng(target));
    }
  }

  Future<bool> _ensurePermission({bool fallbackToDefault = false}) async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      _showSnack(
        AppStrings.locationPermissionRequired.tr,
        isError: true,
      );
      if (fallbackToDefault && _marker == null) {
        _setMarker(_current);
      }
      return false;
    }
    if (perm == LocationPermission.denied) {
      _showSnack(AppStrings.locationPermissionDenied.tr, isError: true);
      if (fallbackToDefault && _marker == null) {
        _setMarker(_current);
      }
      return false;
    }
    return true;
  }

  Future<void> _useCurrentLocation({bool fallbackToDefault = false}) async {
    final ok = await _ensurePermission(fallbackToDefault: fallbackToDefault);
    if (!ok) return;
    setState(() => _loadingLocation = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _setMarker(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      _showSnack(AppStrings.currentLocationFailed.tr, isError: true);
      if (fallbackToDefault && _marker == null) {
        _setMarker(_current);
      }
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _save() async {
    if (_marker == null) {
      _showSnack(AppStrings.selectLocationFirst.tr, isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await profileController.setLocation(
        _marker!.position.latitude,
        _marker!.position.longitude,
      );
      _showSnack(AppStrings.locationSaved.tr, isError: false);
      if (mounted) Navigator.pop(context, _marker!.position);
    } catch (_) {
      _showSnack(AppStrings.locationSaveFailed.tr, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setMarker(LatLng pos) {
    setState(() {
      _current = pos;
      _marker = Marker(markerId: const MarkerId('pick'), position: pos);
    });
    _animateTo(pos);
  }

  void _showSnack(String msg, {required bool isError}) {
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      msg,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'تحديث موقعي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _current, zoom: 14),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _marker != null ? {_marker!} : {},
                  onLongPress: (latLng) {
                    setState(() {
                      _marker = Marker(
                        markerId: const MarkerId('pick'),
                        position: latLng,
                      );
                    });
                  },
                  onTap: (latLng) {
                    setState(() {
                      _marker = Marker(
                        markerId: const MarkerId('pick'),
                        position: latLng,
                      );
                    });
                  },
                  onMapCreated: (ctrl) => _mapController.complete(ctrl),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: FloatingActionButton(
                    heroTag: 'locate_me',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _loadingLocation ? null : _useCurrentLocation,
                    child: _loadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.my_location, color: primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          Container(
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _marker == null
                        ? 'اضغط على الخريطة لاختيار موقع'
                        : 'الموقع: ${_marker!.position.latitude.toStringAsFixed(5)}, ${_marker!.position.longitude.toStringAsFixed(5)}',
                    style: AppTextStyles.body(context),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'حفظ الموقع',
                    style: TextStyle(fontFamily: 'Cairo'),
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


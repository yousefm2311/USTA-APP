import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Customer/core/services/upload/image_compressor.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_request_details_view.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/widgets/create_request_action_button.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/widgets/create_request_artisan_sheet.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/widgets/create_request_field.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/widgets/create_request_images_grid.dart';
import 'package:usta/Customer/features/customer/requests/views/create_request/widgets/create_request_service_selector.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerCreateRequestView extends StatefulWidget {
  final String? presetArtisanId;
  final String? presetArtisanName;
  final String? presetService;
  final List<String>? presetServices;

  const CustomerCreateRequestView({
    super.key,
    this.presetArtisanId,
    this.presetArtisanName,
    this.presetService,
    this.presetServices,
  });

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  State<CustomerCreateRequestView> createState() =>
      _CustomerCreateRequestViewState();
}

class _CustomerCreateRequestViewState extends State<CustomerCreateRequestView> {
  final formKey = GlobalKey<FormState>();
  late final CustomerRequestsController controller;

  final serviceCtrl = TextEditingController();
  final artisanCtrl = TextEditingController();
  final governorateCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final areaCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();

  final List<String> _imagePaths = [];
  String? _selectedArtisanId;
  String? _selectedArtisanName;
  String? _selectedService;
  bool _locating = false;
  bool _uploadingImages = false;
  int _uploadProgress = 0;
  int _uploadTotal = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomerRequestsController>();
    if (widget.presetArtisanId != null && widget.presetArtisanId!.isNotEmpty) {
      _selectedArtisanId = widget.presetArtisanId;
      _selectedArtisanName = widget.presetArtisanName;
      artisanCtrl.text = widget.presetArtisanName ?? '';
    }
    if (widget.presetService != null && widget.presetService!.isNotEmpty) {
      _selectedService = widget.presetService;
      serviceCtrl.text = widget.presetService!;
    }
    if (widget.presetServices != null && widget.presetServices!.isNotEmpty) {
      final current = controller.serviceTypes;
      final extras = widget.presetServices!
          .where((s) => s.trim().isNotEmpty && !current.contains(s.trim()))
          .map((e) => e.trim())
          .toList();
      if (extras.isNotEmpty) {
        controller.serviceTypes.addAll(extras);
      }
    }
  }

  @override
  void dispose() {
    serviceCtrl.dispose();
    artisanCtrl.dispose();
    governorateCtrl.dispose();
    cityCtrl.dispose();
    areaCtrl.dispose();
    streetCtrl.dispose();
    landmarkCtrl.dispose();
    descCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "إنشاء طلب جديد".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),

      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CreateRequestServiceSelector(
              controller: controller,
              serviceCtrl: serviceCtrl,
              selectedService: _selectedService,
              onChanged: (val) {
                setState(() {
                  _selectedService = val;
                  if (val == '__custom__') {
                    serviceCtrl.text = '';
                  } else {
                    serviceCtrl.text = val ?? '';
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            CreateRequestField(
              controller: artisanCtrl,
              label: 'الفني (اختياري)',
              hint: 'سيتم اختيار فني قريب',
              readOnly: true,
              onTap: _fetchNearbyArtisans,
              validator: (value) => null,
              suffix: IconButton(
                icon: const Icon(Icons.near_me),
                onPressed: _fetchNearbyArtisans,
              ),
            ),
            if (_selectedArtisanName != null) ...[
              const SizedBox(height: 8),
              Text(
                'الفني المختار: @name'
                    .trParams({'name': _selectedArtisanName ?? ''}),
                style: const TextStyle(fontFamily: "Cairo"),
              ),
            ],
            const SizedBox(height: 14),
            CreateRequestField(
              controller: governorateCtrl,
              label: 'المحافظة',
              hint: 'الشرقية / القاهرة ...',
              validator: (_) => null,
            ),
            const SizedBox(height: 10),

            CreateRequestField(
              controller: cityCtrl,
              label: 'المركز / المدينة',
              hint: 'الزقازيق / بنها ...',
              validator: (_) => null,
            ),
            const SizedBox(height: 10),

            CreateRequestField(
              controller: areaCtrl,
              label: 'الحي / المنطقة / القرية',
              hint: 'المجاورة / الحي / القرية',
              validator: (_) => null,
            ),
            const SizedBox(height: 10),

            CreateRequestField(
              controller: streetCtrl,
              label: 'الشارع والتفاصيل',
              hint: 'اسم الشارع ورقم العقار إن وجد',
              validator: (_) => null,
            ),
            const SizedBox(height: 10),

            CreateRequestField(
              controller: landmarkCtrl,
              label: 'علامة مميزة (اختياري)',
              hint: 'قرب مسجد / مدرسة / مستشفى...',
              validator: (_) => null,
            ),
            const SizedBox(height: 10),

            CreateRequestField(
              controller: descCtrl,
              label: 'وصف المشكلة',
              hint: 'اكتب تفاصيل واضحة عن المشكلة التي تواجهها',
              keyboard: TextInputType.multiline,
              validator: (_) => null,
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CreateRequestActionButton(
                    icon: Icons.my_location,
                    label: 'موقعي الحالي',
                    onPressed: _locating ? null : _useCurrentLocation,
                    loading: _locating,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CreateRequestActionButton(
                    icon: Icons.map_outlined,
                    label: 'الفنيين القريبين',
                    onPressed: _fetchNearbyArtisans,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            CreateRequestField(
              controller: latCtrl,
              label: 'خط العرض (Latitude)',
              hint: '30.0507',
              keyboard: TextInputType.number,
              validator: (_) => null,
              readOnly: true,
            ),
            const SizedBox(height: 14),
            CreateRequestField(
              controller: lngCtrl,
              label: 'خط الطول (Longitude)',
              hint: '31.2489',
              keyboard: TextInputType.number,
              validator: (_) => null,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            CreateRequestActionButton(
              icon: Icons.photo_library_outlined,
              label: 'إضافة صور (حد أقصى 5)',
              onPressed: _pickImages,
            ),

            if (_imagePaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              CreateRequestImagesGrid(
                imagePaths: _imagePaths,
                onRemove: (path) => setState(() => _imagePaths.remove(path)),
              ),
            ],
            const SizedBox(height: 24),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.blue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: controller.submitting.value || _uploadingImages
              ? null
              : () async {
                  if (!formKey.currentState!.validate()) return;

                  if (_selectedArtisanId == null &&
                      artisanCtrl.text.trim().isNotEmpty &&
                      artisanCtrl.text.trim().length != 24) {
                    AppSnackBar.show(
                      'تنبيه'.tr,
                      'معرّف الفني يجب أن يكون 24 حرفًا'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  final addressParts = [
                    governorateCtrl.text.trim(),
                    cityCtrl.text.trim(),
                    areaCtrl.text.trim(),
                    streetCtrl.text.trim(),
                    landmarkCtrl.text.trim(),
                  ].where((e) => e.isNotEmpty).toList();
                  final address = addressParts.join(' - ');
                  if (address.isEmpty ||
                      (streetCtrl.text.trim().isEmpty &&
                          areaCtrl.text.trim().isEmpty)) {
                    AppSnackBar.show(
                      'تنبيه'.tr,
                      'أضف تفاصيل العنوان (المنطقة أو الشارع)'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );

                    return;
                  }

                  final lat = latCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(latCtrl.text.trim());
                  final lng = lngCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(lngCtrl.text.trim());
                  if (lat != null && (lat < -90 || lat > 90)) {
                    AppSnackBar.show(
                      'تنبيه'.tr,
                      'خط العرض يجب أن يكون بين -90 و 90'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );

                    return;
                  }
                  if (lng != null && (lng < -180 || lng > 180)) {
                    AppSnackBar.show(
                      'تنبيه'.tr,
                      'خط الطول يجب أن يكون بين -180 و 180'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );

                    return;
                  }

                  if (_selectedArtisanId == null &&
                      (lat == null || lng == null)) {
                    AppSnackBar.show(
                      'تنبيه'.tr,
                      'حدد موقعك قبل إرسال الطلب عشان يوصل للحرفيين القريبين منك'
                          .tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  final serviceName = serviceCtrl.text.trim();
                  final serviceId = controller.resolveServiceTypeId(serviceName);
                  if (serviceName.isNotEmpty && serviceId == null) {
                    AppSnackBar.show(
                      'تنبيه'.tr,
                      'يرجى اختيار خدمة من القائمة.'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  if (_imagePaths.isNotEmpty && mounted) {
                    setState(() {
                      _uploadingImages = true;
                      _uploadProgress = 0;
                      _uploadTotal = _imagePaths.length;
                    });
                  }
                  String reqId = '';
                  bool created = false;
                  try {
                    final response = await controller.createRequest(
                      serviceType: serviceId,
                      artisanId:
                          _selectedArtisanId ??
                          (artisanCtrl.text.trim().isNotEmpty
                              ? artisanCtrl.text.trim()
                              : null),
                      address: address,
                      lat: lat,
                      lng: lng,
                      description: descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text.trim()
                          : null,
                    );
                    reqId =
                        (response['_id'] ?? response['id'])?.toString() ?? '';
                    created = true;
                    if (reqId.isNotEmpty && _imagePaths.isNotEmpty) {
                      final result = await _uploadImages(reqId);
                      _showUploadSummary(result);
                    }
                  } catch (_) {
                  } finally {
                    if (mounted) {
                      setState(() {
                        _uploadingImages = false;
                        _uploadProgress = 0;
                        _uploadTotal = 0;
                      });
                    }
                  }
                  if (!created) return;
                  if (reqId.isNotEmpty) {
                    Get.off(() => CustomerRequestDetailsView(requestId: reqId));
                  } else {
                    Get.back();
                  }
                },
          child: Text(
            controller.submitting.value
                ? 'جاري الإرسال...'.tr
                : _uploadingImages
                    ? 'جاري رفع الصور (@current/@total)'.trParams(
                        {
                          'current': _uploadProgress.toString(),
                          'total': _uploadTotal.toString(),
                        },
                      )
                    : 'إرسال الطلب'.tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackBar.show(
          'تنبيه'.tr,
          'فعّل خدمة الموقع لاستخدام موقعك الحالي'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackBar.show(
          'تنبيه'.tr,
          'لم يتم السماح بالوصول للموقع'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      latCtrl.text = position.latitude.toStringAsFixed(6);
      lngCtrl.text = position.longitude.toStringAsFixed(6);
      try {
        final p = await _reverseGeocodeArabic(
          position.latitude,
          position.longitude,
        );
        if (p != null) _fillAddressFromPlacemark(p);
      } catch (_) {
        if (streetCtrl.text.trim().isEmpty) {
          streetCtrl.text = 'موقعي: @lat, @lng'.trParams(
            {
              'lat': position.latitude.toStringAsFixed(4),
              'lng': position.longitude.toStringAsFixed(4),
            },
          );
        }
        if (areaCtrl.text.trim().isEmpty) {
          areaCtrl.text = 'بالقرب من موقعي الحالي'.tr;
        }
        if (governorateCtrl.text.trim().isEmpty) {
          governorateCtrl.text = 'الموقع الحالي'.tr;
        }
        if (cityCtrl.text.trim().isEmpty) {
          cityCtrl.text = 'المدينة الأقرب'.tr;
        }
      }
    } catch (e) {
      AppSnackBar.show(
        'خطأ'.tr,
        'تعذر الحصول على الموقع الحالي'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<geo.Placemark?> _reverseGeocodeArabic(double lat, double lng) async {
    const locales = ['ar_EG', 'ar_SA', 'ar', 'en'];
    for (final loc in locales) {
      try {
        final list = await geo.placemarkFromCoordinates(
          lat,
          lng,
          localeIdentifier: loc,
        );
        if (list.isNotEmpty) return list.first;
      } catch (_) {
      }
    }
    return null;
  }

  void _fillAddressFromPlacemark(geo.Placemark p) {
    governorateCtrl.text = p.administrativeArea?.trim().isNotEmpty == true
        ? p.administrativeArea!
        : (p.country?.toString().isNotEmpty == true
              ? p.country!
              : (governorateCtrl.text.isNotEmpty
                    ? governorateCtrl.text
                    : 'غير معروف'.tr));
    cityCtrl.text = p.subAdministrativeArea?.trim().isNotEmpty == true
        ? p.subAdministrativeArea!
        : (p.locality?.toString().isNotEmpty == true
              ? p.locality!
              : (cityCtrl.text.isNotEmpty ? cityCtrl.text : 'غير معروف'.tr));
    areaCtrl.text = p.subLocality?.trim().isNotEmpty == true
        ? p.subLocality!
        : (p.locality?.toString().isNotEmpty == true
              ? p.locality!
              : (areaCtrl.text.isNotEmpty ? areaCtrl.text : 'غير معروف'.tr));
    String? streetGuess;
    for (final s in [p.thoroughfare, p.street, p.name]) {
      if (s != null && s.trim().isNotEmpty) {
        streetGuess = s;
        break;
      }
    }
    if (streetGuess != null) streetCtrl.text = streetGuess;
    if (landmarkCtrl.text.trim().isEmpty && p.name != null) {
      landmarkCtrl.text = p.name!;
    }
  }

  Future<void> _fetchNearbyArtisans() async {
    final lat = double.tryParse(latCtrl.text.trim());
    final lng = double.tryParse(lngCtrl.text.trim());
    if (lat == null || lng == null) {
      AppSnackBar.show(
        'تنبيه'.tr,
        'أدخل أو حدّد موقعك أولًا'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    try {
      await controller.loadNearbyArtisans(lat: lat, lng: lng);
      if (controller.nearbyArtisans.isEmpty) {
        AppSnackBar.show(
          'تنبيه'.tr,
          'لا يوجد فنيون بالقرب الآن'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => CreateRequestArtisanSheet(
          artisans: List<Map<String, dynamic>>.from(
            controller.nearbyArtisans,
          ),
          onSelect: (art, name) {
            setState(() {
              _selectedArtisanId = (art['_id'] ?? art['id'])?.toString() ?? '';
              _selectedArtisanName = name;
              artisanCtrl.text = name;
            });
          },
        ),
      );
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked.isEmpty) return;
    final files = picked.map((e) => e.path);
    setState(() {
      _imagePaths
        ..clear()
        ..addAll(files.where((p) => File(p).existsSync()).take(5));
    });
    if (picked.length > 5) {
      AppSnackBar.show(
        'تنبيه'.tr,
        'الحد الأقصى 5 صور فقط'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<_UploadResult> _uploadImages(String requestId) async {
    if (_imagePaths.isEmpty) {
      return const _UploadResult(total: 0, uploaded: 0, failed: 0, skipped: 0);
    }
    int uploaded = 0;
    int failed = 0;
    int skipped = 0;

    for (final path in _imagePaths) {
      final dataUri = await _prepareImageData(path);
      if (dataUri == null) {
        skipped += 1;
        _bumpUploadProgress();
        continue;
      }
      try {
        await controller.addImages(requestId: requestId, images: [dataUri]);
        uploaded += 1;
      } catch (_) {
        failed += 1;
      } finally {
        _bumpUploadProgress();
      }
    }

    return _UploadResult(
      total: _imagePaths.length,
      uploaded: uploaded,
      failed: failed,
      skipped: skipped,
    );
  }

  Future<String?> _prepareImageData(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;

    File processed = file;
    const targetBytes = 850 * 1024;
    const maxBytes = 1200 * 1024;

    try {
      if (file.lengthSync() > targetBytes) {
        processed = await ImageCompressor.compress(
          file,
          quality: 70,
          maxDimension: 1400,
        );
      }
      if (processed.lengthSync() > targetBytes) {
        processed = await ImageCompressor.compress(
          file,
          quality: 60,
          maxDimension: 1200,
        );
      }
      if (processed.lengthSync() > targetBytes) {
        processed = await ImageCompressor.compress(
          file,
          quality: 50,
          maxDimension: 1024,
        );
      }
      if (processed.lengthSync() > targetBytes) {
        processed = await ImageCompressor.compress(
          file,
          quality: 40,
          maxDimension: 900,
        );
      }
    } catch (_) {}

    if (processed.lengthSync() > maxBytes) {
      if (processed.path != file.path && processed.existsSync()) {
        processed.deleteSync();
      }
      return null;
    }

    final bytes = await processed.readAsBytes();
    if (processed.path != file.path && processed.existsSync()) {
      processed.deleteSync();
    }
    final mime = _inferMime(processed.path);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  void _bumpUploadProgress() {
    if (!mounted || !_uploadingImages) return;
    setState(() {
      _uploadProgress = (_uploadProgress + 1).clamp(0, _uploadTotal);
    });
  }

  void _showUploadSummary(_UploadResult result) {
    if (result.total == 0) return;
    if (result.uploaded == result.total) {
      AppSnackBar.show(
        'تم'.tr,
        'تم رفع الصور بنجاح'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (result.uploaded == 0) {
      AppSnackBar.show(
        'تنبيه'.tr,
        'تعذر رفع الصور، تم إرسال الطلب بدون صور'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    AppSnackBar.show(
      'تنبيه'.tr,
      'تم إرسال الطلب، لكن تعذر رفع بعض الصور'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _inferMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

}

class _UploadResult {
  const _UploadResult({
    required this.total,
    required this.uploaded,
    required this.failed,
    required this.skipped,
  });

  final int total;
  final int uploaded;
  final int failed;
  final int skipped;
}



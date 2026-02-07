// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';

class ArtisanRequestDetailsFromCustomerView extends StatefulWidget {
  const ArtisanRequestDetailsFromCustomerView({super.key});

  @override
  State<ArtisanRequestDetailsFromCustomerView> createState() =>
      _ArtisanRequestDetailsFromCustomerViewState();
}

class _ArtisanRequestDetailsFromCustomerViewState
    extends State<ArtisanRequestDetailsFromCustomerView> {
  Color get primaryBlue => const Color(0xFF2563EB);

  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();

  late Map<String, dynamic> request;
  late final String requestId;

  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments is Map ? Get.arguments as Map : <String, dynamic>{};
    request = (args['request'] as Map?)?.cast<String, dynamic>() ??
        args.cast<String, dynamic>();
    requestId = (args['requestId'] ?? request['_id'] ?? request['id'] ?? '').toString();
    final price = request['price'] ?? request['paidAmount'];
    if (price != null) priceCtrl.text = price.toString();
    if (request['note'] is String) {
      noteCtrl.text = request['note'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _serviceText(request);
    final customer = _customerText(request);
    final location = _formatLocation(request['location'], request['address']);
    final description = (request['description'] ?? '').toString();
    final status = (request['status'] ?? 'جديد').toString();
    final createdAt = (request['createdAt'] ?? '').toString();
    final images = _imagesList(request['images']);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "تفاصيل الطلب",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("معلومات الطلب"),
            const SizedBox(height: 16),
            _infoCard(context, service, customer, location, status, createdAt, description),
            const SizedBox(height: 24),
            _imagesSection(images),
            const SizedBox(height: 24),
            _sectionTitle("تحديد السعر/ملاحظة"),
            const SizedBox(height: 10),
            _priceField(),
            const SizedBox(height: 14),
            _notesField(),
            const SizedBox(height: 20),
            Obx(() {
              final loading = controller.submitting.value;
              return Column(
                children: [
                  _acceptButton(loading),
                  const SizedBox(height: 10),
                  _rejectButton(loading),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.body(context).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoCard(BuildContext context, String service, String customer,
      String location, String status, String createdAt, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _infoRow("الخدمة", service),
          _infoRow("العميل", customer),
          _infoRow("الموقع", location),
          _infoRow("الحالة", status),
          if (createdAt.isNotEmpty) _infoRow("تاريخ الإنشاء", createdAt),
          if (description.isNotEmpty) _infoRow("الوصف", description),
        ],
      ),
    );
  }

  Widget _imagesSection(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("صور الطلب"),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: images.length,
            itemBuilder: (_, i) {
              final url = images[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 110,
                  color: Colors.white12,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _priceField() {
    return TextField(
      controller: priceCtrl,
      keyboardType: TextInputType.number,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: "السعر المقترح (اختياري)",
        labelStyle: AppTextStyles.body(context),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _notesField() {
    return TextField(
      controller: noteCtrl,
      maxLines: 3,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: "ملاحظات (اختياري)",
        labelStyle: AppTextStyles.body(context),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _acceptButton(bool loading) {
    return ElevatedButton(
      onPressed: loading ? null : _onAccept,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text(
              "قبول الطلب مع السعر",
              style: TextStyle(fontFamily: "Cairo", color: Colors.white),
            ),
    );
  }

  Widget _rejectButton(bool loading) {
    return ElevatedButton(
      onPressed: loading ? null : _onReject,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text(
              "رفض الطلب",
              style: TextStyle(fontFamily: "Cairo", color: Colors.white),
            ),
    );
  }

  Future<void> _onAccept() async {
    if (requestId.isEmpty) return;
    int? price;
    if (priceCtrl.text.trim().isNotEmpty) {
      price = int.tryParse(priceCtrl.text.trim());
      if (price == null) {
        AppSnackBar.show(
          AppStrings.invalidPriceTitle.tr,
          AppStrings.invalidPriceMessage.tr,
          type: SnackBarType.error,
        );
        return;
      }
    }
    await controller.acceptRequest(requestId, price: price, note: noteCtrl.text.trim());
    if (mounted) Get.back();
  }

  Future<void> _onReject() async {
    if (requestId.isEmpty) return;
    await controller.rejectRequest(requestId, reason: noteCtrl.text.trim());
    if (mounted) Get.back();
  }

  List<String> _imagesList(dynamic images) {
    if (images is List) {
      return images
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .map(_resolveImageUrl)
          .toList();
    }
    return const [];
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    final base = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;
    final baseNoApi =
        base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
    if (url.startsWith('/')) return '$baseNoApi$url';
    return '$baseNoApi/$url';
  }

  String _serviceText(Map<String, dynamic> req) {
    return (req['serviceName'] ??
            (req['service'] is Map ? (req['service']['name'] ?? '') : null) ??
            req['serviceType'] ??
            'خدمة')
        .toString();
  }

  String _customerText(Map<String, dynamic> req) {
    return ((req['customer'] is Map ? req['customer']['name'] : req['customerName']) ?? 'عميل')
        .toString();
  }

  String _formatLocation(dynamic location, dynamic address) {
    if (address is String && address.isNotEmpty) return address;
    if (location is String && location.isNotEmpty) return location;
    if (location is Map && location['coordinates'] is List) {
      final coords = (location['coordinates'] as List);
      if (coords.length >= 2) {
        final lat = coords[1];
        final lng = coords[0];
        if (lat != null && lng != null) {
          return '$lat, $lng';
        }
      }
    }
    return 'غير متوفر';
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$title:",
              style: AppTextStyles.body(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: AppTextStyles.body(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


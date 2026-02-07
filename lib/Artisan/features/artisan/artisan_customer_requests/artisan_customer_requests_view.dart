import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';
import 'package:usta/Artisan/features/artisan/show_artisan_new_request/artisan_accept_request_view.dart';

class ArtisanCustomerRequestsView extends StatefulWidget {
  const ArtisanCustomerRequestsView({super.key});

  @override
  State<ArtisanCustomerRequestsView> createState() =>
      _ArtisanCustomerRequestsViewState();
}

class _ArtisanCustomerRequestsViewState
    extends State<ArtisanCustomerRequestsView> {
  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();
  final Color primaryBlue = const Color(0xFF2563EB);
  final Set<String> _shownDialogs = {};
  late final Worker _newRequestWorker;

  @override
  void initState() {
    super.initState();
    _newRequestWorker = ever<List<Map<String, dynamic>>>(
      controller.newRequests,
      _handleNew,
    );
  }

  @override
  void dispose() {
    _newRequestWorker.dispose();
    super.dispose();
  }

  void _handleNew(List<Map<String, dynamic>> list) {
    if (list.isEmpty || Get.context == null) return;
    final firstNew = list.firstWhere(
      (e) => !_shownDialogs.contains((e['_id'] ?? e['id'] ?? '').toString()),
      orElse: () => {},
    );
    if (firstNew.isEmpty) return;
    final id = (firstNew['_id'] ?? firstNew['id'] ?? '').toString();
    _shownDialogs.add(id);
    // final service = _serviceText(firstNew);/* */
    // final customer = _customerText(firstNew);

    // Get.defaultDialog(
    //   title: 'طلب جديد',
    //   middleText: 'نوع الخدمة: $service\nالعميل: $customer',
    //   confirm: ElevatedButton(
    //     onPressed: () {
    //       Get.back();
    //       _openAccept(firstNew);
    //     },
    //     style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
    //     child: const Text('عرض التفاصيل'),
    //   ),
    //   cancel: TextButton(
    //     onPressed: () => Get.back(),
    //     child: const Text('إلغاء'),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "طلبات العملاء",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.loadingNew.value && controller.newRequests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = controller.newRequests;
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => controller.fetchNewRequests(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 80),
                Icon(Icons.inbox_outlined, size: 54),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'لا توجد طلبات جديدة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'اسحب لتحديث القائمة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchNewRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final request = items[index];
              final service = _serviceText(request);
              final customer = _customerText(request);
              final location = _formatLocation(
                request['location'],
                request['address'],
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service,
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _info(Icons.person, customer),
                    const SizedBox(height: 6),
                    _info(Icons.location_on, location),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openAccept(request),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'عرض التفاصيل',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _openAccept(Map<String, dynamic> request) {
    final id = (request['_id'] ?? request['id'] ?? '').toString();
    Get.to(
      () => const ArtisanAcceptRequestView(),
      arguments: {'requestId': id, 'request': request},
    );
  }

  String _serviceText(Map<String, dynamic> request) {
    return (request['serviceName'] ??
            (request['service'] is Map
                ? (request['service']['name'] ?? '')
                : null) ??
            request['serviceType'] ??
            'غير محدد')
        .toString();
  }

  String _customerText(Map<String, dynamic> request) {
    return ((request['customer'] is Map
                ? request['customer']['name']
                : request['customerName']) ??
            'عميل')
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
}


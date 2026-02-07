import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';
import 'package:usta/Artisan/features/artisan/show_artisan_new_request/artisan_accept_request_view.dart';

class ShowArtisanNewRequestsView extends StatelessWidget {
  ShowArtisanNewRequestsView({super.key});

  final ArtisanRequestsController controller =
      Get.find<ArtisanRequestsController>();
  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "الطلبات الجديدة",
          style: TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
                Center(child: Text('لا توجد طلبات جديدة حالياً')),
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
              final service =
                  (request['serviceName'] ??
                          (request['service'] is Map
                              ? (request['service']['name'] ?? '')
                              : null) ??
                          request['serviceType'] ??
                          'غير محدد')
                      .toString();
              final customer =
                  ((request['customer'] is Map
                              ? request['customer']['name']
                              : request['customerName']) ??
                          'عميل')
                      .toString();
              final location = _formatLocation(
                request['location'],
                request['address'],
              );
              final price =
                  request['price']?.toString() ??
                  request['budget']?.toString() ??
                  '';
              final note = request['note']?.toString() ?? '';

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
                    const SizedBox(height: 8),
                    _info(Icons.person, customer, context),
                    const SizedBox(height: 6),
                    _info(Icons.location_on, location , context),
                    if (price.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _info(Icons.attach_money, price, context),
                    ],
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _info(Icons.notes, note, context),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openAccept(request),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              "عرض التفاصيل",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => controller.rejectRequest(
                              (request['_id'] ?? request['id'] ?? '')
                                  .toString(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              "رفض",
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

  Widget _info(IconData icon, String text,context) {
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


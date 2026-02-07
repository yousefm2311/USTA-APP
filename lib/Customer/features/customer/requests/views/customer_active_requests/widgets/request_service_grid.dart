import 'package:flutter/material.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_service_tile.dart';

class RequestServiceGrid extends StatelessWidget {
  const RequestServiceGrid({
    super.key,
    required this.primaryColor,
    required this.cardColor,
    required this.onServiceTap,
  });

  final Color primaryColor;
  final Color cardColor;
  final VoidCallback onServiceTap;

  static const List<Map<String, dynamic>> _services = [
    {"name": "سباكة", "icon": Icons.water_drop},
    {"name": "كهرباء", "icon": Icons.electrical_services},
    {"name": "نجارة", "icon": Icons.chair},
    {"name": "دهانات", "icon": Icons.format_paint},
    {"name": "تكييف", "icon": Icons.ac_unit},
    {"name": "تنظيف", "icon": Icons.cleaning_services},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: .9,
      ),
      itemBuilder: (context, i) {
        return RequestServiceTile(
          name: _services[i]["name"].toString(),
          icon: _services[i]["icon"] as IconData,
          primaryColor: primaryColor,
          cardColor: cardColor,
          onTap: onServiceTap,
        );
      },
    );
  }
}


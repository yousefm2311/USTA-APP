import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_card.dart';

class ArtisanServicesChips extends StatelessWidget {
  final List<String> services;
  final Color borderColor;

  const ArtisanServicesChips({
    super.key,
    required this.services,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return ArtisanCard(
        borderColor: borderColor,
        child: Text(
          'لا توجد خدمات مضافة حتى الآن'.tr,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services
          .map(
            (s) => Chip(
              label: Text(s, style: const TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Theme.of(context).colorScheme.surface,
              labelStyle: const TextStyle(),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          )
          .toList(),
    );
  }
}


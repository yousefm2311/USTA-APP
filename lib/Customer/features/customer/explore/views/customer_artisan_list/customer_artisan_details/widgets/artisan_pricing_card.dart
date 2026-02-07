import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_card.dart';

class ArtisanPricingCard extends StatelessWidget {
  final List<Map<String, String>> rows;
  final Color borderColor;

  const ArtisanPricingCard({
    super.key,
    required this.rows,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ArtisanCard(
      borderColor: borderColor,
      child: Column(
        children: rows.map((r) {
          final min = (r['min'] ?? '').toString();
          final max = (r['max'] ?? '').toString();
          final currency = (r['currency'] ?? '').toString();
          final priceText = (min.isEmpty && max.isEmpty)
              ? 'غير محدد'.tr
              : '$min - $max $currency'.trim();

          return Column(
            children: [
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  (r['name'] ?? '').toString(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                  ),
                ),
                subtitle: Text(
                  priceText,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              if (r != rows.last)
                Divider(color: Colors.white.withOpacity(0.08)),
            ],
          );
        }).toList(),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_section_card.dart';

class RequestAddressInfoCard extends StatelessWidget {
  const RequestAddressInfoCard({
    super.key,
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RequestSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 18, color: scheme.onSurface),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    height: 1.5,
                    color: scheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.language, size: 18, color: scheme.onSurface),
              const SizedBox(width: 6),
              Text(
                'lat: ${lat?.toStringAsFixed(6) ?? '--'}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'lng: ${lng?.toStringAsFixed(6) ?? '--'}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


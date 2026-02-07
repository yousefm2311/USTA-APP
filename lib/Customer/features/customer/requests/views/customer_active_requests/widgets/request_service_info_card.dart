import 'package:flutter/material.dart';
import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/widgets/request_section_card.dart';

class RequestServiceInfoCard extends StatelessWidget {
  const RequestServiceInfoCard({
    super.key,
    required this.service,
    required this.price,
    required this.description,
    required this.requestId,
  });

  final String service;
  final dynamic price;
  final String description;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RequestSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  service,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (price != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 18,
                  color: scheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  price.toString(),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes, size: 18, color: scheme.onSurface),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    description,
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
          ],
          const SizedBox(height: 10),
          Text(
            'ID: $requestId',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: scheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}


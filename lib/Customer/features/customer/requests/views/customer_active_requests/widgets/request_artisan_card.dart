import 'package:flutter/material.dart';

class RequestArtisanCard extends StatelessWidget {
  const RequestArtisanCard({
    super.key,
    required this.name,
    required this.profession,
    required this.rating,
    required this.phone,
    required this.email,
    this.onTap,
  });

  final String name;
  final String profession;
  final dynamic rating;
  final String? phone;
  final String? email;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primary.withOpacity(0.12),
              child: Icon(Icons.person, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profession,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (rating != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withOpacity(0.55),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (phone != null || email != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (phone != null)
                Expanded(
                  child: Text(
                    phone.toString(),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              if (email != null)
                Expanded(
                  child: Text(
                    email.toString(),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );

    if (onTap == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      );
    }

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: content),
      ),
    );
  }
}

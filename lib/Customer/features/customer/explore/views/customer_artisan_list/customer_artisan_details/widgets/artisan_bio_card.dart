import 'package:flutter/material.dart';
import 'package:usta/Customer/features/customer/explore/views/customer_artisan_list/customer_artisan_details/widgets/artisan_card.dart';

class ArtisanBioCard extends StatelessWidget {
  final String bio;
  final Color borderColor;

  const ArtisanBioCard({
    super.key,
    required this.bio,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ArtisanCard(
      borderColor: borderColor,
      child: Text(
        bio,
        style: const TextStyle(
          fontFamily: 'Cairo',
          height: 1.7,
        ),
      ),
    );
  }
}


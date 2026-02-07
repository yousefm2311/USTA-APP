import 'package:flutter/material.dart';

class ReviewRatingStars extends StatelessWidget {
  const ReviewRatingStars({
    super.key,
    required this.rating,
    required this.onSelect,
  });

  final double rating;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => IconButton(
          onPressed: () => onSelect(i + 1),
          icon: Icon(
            Icons.star,
            size: 32,
            color: (i < rating) ? Colors.amber : Colors.white30,
          ),
        ),
      ),
    );
  }
}

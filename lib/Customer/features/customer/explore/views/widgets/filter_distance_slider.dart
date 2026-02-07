import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExploreFilterDistanceSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  const ExploreFilterDistanceSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      min: 1,
      max: 50,
      activeColor: activeColor,
      label: "${value.toStringAsFixed(0)} ${'كم'.tr}",
      onChanged: onChanged,
    );
  }
}

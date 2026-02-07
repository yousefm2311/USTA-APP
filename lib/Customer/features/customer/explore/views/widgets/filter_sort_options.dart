import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExploreFilterSortOptions extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color activeColor;

  const ExploreFilterSortOptions({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return RadioListTile(
          value: item,
          groupValue: selected,
          activeColor: activeColor,
          onChanged: (v) => onChanged(v.toString()),
          title: Text(
            item.tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExploreSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final bool showClear;

  const ExploreSearchField({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
    required this.onSubmitted,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontFamily: "Cairo"),
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: "ابحث عن فني أو خدمة...".tr,
                hintStyle: const TextStyle(fontFamily: "Cairo"),
                border: InputBorder.none,
              ),
            ),
          ),
          if (showClear)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              tooltip: 'مسح'.tr,
            ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSearch,
            tooltip: 'بحث'.tr,
          ),
        ],
      ),
    );
  }
}

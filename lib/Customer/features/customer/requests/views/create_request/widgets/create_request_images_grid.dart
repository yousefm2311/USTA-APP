import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateRequestImagesGrid extends StatelessWidget {
  const CreateRequestImagesGrid({
    super.key,
    required this.imagePaths,
    required this.onRemove,
  });

  final List<String> imagePaths;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: imagePaths.map((p) {
        final file = File(p);
        if (!file.existsSync()) {
          return GestureDetector(
            onTap: () => onRemove(p),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image),
            ),
          );
        }
        return Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                file,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            GestureDetector(
              onTap: () => onRemove(p),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Get.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

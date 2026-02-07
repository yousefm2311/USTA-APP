import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSkeletons {
  static Widget listTile({double height = 72, EdgeInsets? margin}) {
    return _wrap(
      margin,
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _box(width: 48, height: 48, radius: 12),
            const SizedBox(width: 12),
            SizedBox(
              width: 190,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  _box(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      height: height,
      width: 260,
    );
  }

  static Widget chatBubble({bool fromMe = false}) {
    return Align(
      alignment: fromMe ? Alignment.centerLeft : Alignment.centerRight,
      child: _wrap(
        const EdgeInsets.symmetric(vertical: 8),
        Column(
          crossAxisAlignment: fromMe
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            _box(width: 140, height: 12),
            const SizedBox(height: 8),
            _box(width: 220, height: 12),
          ],
        ),
      ),
    );
  }

  static Widget gridCard({double? height, double borderRadius = 12, context}) {
    final cardHeight = height ?? 190;
    if (cardHeight <= 120) {
      final imageSize = (cardHeight - 24).clamp(48, cardHeight).toDouble();
      return SizedBox(
        height: cardHeight,
        child: _wrap(
          const EdgeInsets.all(8),
          Row(
            children: [
              _box(width: imageSize, height: imageSize, radius: borderRadius),
              const SizedBox(width: 10),
              SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: double.infinity, height: 12),
                    const SizedBox(height: 6),
                    _box(width: 110, height: 10),
                    const SizedBox(height: 8),
                    _box(width: 70, height: 8),
                  ],
                ),
              ),
            ],
          ),
          height: cardHeight,
          width: 300,
        ),
      );
    }

    final imageHeight = (cardHeight - 70).clamp(60, cardHeight).toDouble();
    return SizedBox(
      height: cardHeight,
      child: _wrap(
        const EdgeInsets.all(8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _box(
                  width: double.infinity,
                  height: imageHeight,
                  radius: borderRadius,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Row(
                    children: [
                      _circle(12, context),
                      const SizedBox(width: 6),
                      _box(width: 50, height: 10, radius: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _box(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            _box(width: 140, height: 10),
            const SizedBox(height: 8),
            _box(width: 90, height: 8),
          ],
        ),
        height: cardHeight,
      ),
    );
  }

  static Widget artisanHorizontalCard({
    double width = 170,
    double height = 170,
    double radius = 14,
    context,
  }) {
    final schema = Theme.of(context).colorScheme;
    return _wrap(
      const EdgeInsets.only(right: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: schema.surface.withOpacity(.15),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _circle(36, context),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: schema.surface.withOpacity(.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _box(width: 36, height: 10, radius: 8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _box(width: width * 0.65, height: 12),
            const SizedBox(height: 6),
            _box(width: width * 0.85, height: 10),
            const Spacer(),
            _box(width: 60, height: 12, radius: 10),
          ],
        ),
      ),
      height: height,
      width: width,
    );
  }

  static Widget mapPlaceholder({double height = 180}) {
    return _wrap(
      const EdgeInsets.symmetric(vertical: 8),
      _box(width: double.infinity, height: height, radius: 16),
    );
  }

  static Widget timelineItem(context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [_circle(14, context), _box(width: 2, height: 36)]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 160, height: 12),
              const SizedBox(height: 6),
              _box(width: 100, height: 10),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _wrap(
    EdgeInsets? margin,
    Widget child, {
    double? height,
    double? width,
    context,
  }) {
    return Container(
      margin: margin,
      height: height,
      width: width,
      child: _shimmer(child, context),
    );
  }

  static Widget _box({
    required double width,
    required double height,
    double radius = 8,
    context,
  }) {
    final schema = Theme.of(Get.context!).colorScheme;
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Get.isDarkMode ? schema.surface : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  static Widget _circle(double size, context) {
    final schema = Theme.of(Get.context!).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Get.isDarkMode ? schema.surface : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget _shimmer(Widget child, context) {
    final schema = Theme.of(Get.context!).colorScheme;
    return Shimmer.fromColors(
      baseColor: schema.surface.withOpacity(0.3),
      highlightColor: schema.surface,
      child: child,
    );
  }
}

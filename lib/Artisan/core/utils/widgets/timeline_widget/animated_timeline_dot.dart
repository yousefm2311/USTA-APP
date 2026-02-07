import 'package:flutter/material.dart';

class AnimatedTimelineDot extends StatefulWidget {
  const AnimatedTimelineDot({super.key, required this.color, this.size = 14});
  final Color color;
  final double size;

  @override
  State<AnimatedTimelineDot> createState() => _AnimatedTimelineDotState();
}

class _AnimatedTimelineDotState extends State<AnimatedTimelineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value; // 0..1
        final scale = 1.0 + (t * 0.2);
        final glow = 0.20 + (t * 0.35);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(glow),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

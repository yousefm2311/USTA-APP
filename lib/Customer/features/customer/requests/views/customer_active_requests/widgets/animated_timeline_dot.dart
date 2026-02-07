import 'package:flutter/material.dart';

class AnimatedTimelineDot extends StatefulWidget {
  const AnimatedTimelineDot({
    super.key,
    required this.color,
    required this.icon,
    this.size = 20,
    this.iconSizeFactor = 0.42,
  });

  final Color color;
  final IconData icon;
  final double size;
  final double iconSizeFactor;

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
        final t = _c.value;
        final scale = 1.0 + (t * 0.15);
        final glow = 0.15 + (t * 0.3);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(glow),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 30 * widget.iconSizeFactor,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

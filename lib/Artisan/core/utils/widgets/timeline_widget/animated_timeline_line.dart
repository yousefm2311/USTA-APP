import 'package:flutter/material.dart';

class AnimatedTimelineLine extends StatefulWidget {
  const AnimatedTimelineLine({
    super.key,
    required this.color,
    required this.height,
    this.width = 2,
  });

  final Color color;
  final double height;
  final double width;

  @override
  State<AnimatedTimelineLine> createState() => _AnimatedTimelineLineState();
}

class _AnimatedTimelineLineState extends State<AnimatedTimelineLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

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
        final y = _c.value; // 0..1
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(0, -1 + (y * 2)),
              end: Alignment(0, -0.2 + (y * 2)),
              colors: [
                widget.color.withOpacity(0.05),
                widget.color.withOpacity(0.80),
                widget.color.withOpacity(0.10),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(rect);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            color: widget.color.withOpacity(0.35),
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The pulsing "arc reactor" that signals whether Jarvis is on duty.
class JarvisCore extends StatefulWidget {
  const JarvisCore({super.key, required this.active, this.size = 160});

  final bool active;
  final double size;

  @override
  State<JarvisCore> createState() => _JarvisCoreState();
}

class _JarvisCoreState extends State<JarvisCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppTheme.accent : Colors.white24;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final pulse = widget.active ? 0.5 + 0.5 * math.sin(t * 2 * math.pi) : 0;
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _CorePainter(color: color, pulse: pulse.toDouble()),
          child: SizedBox.square(
            dimension: widget.size,
            child: Center(
              child: Icon(
                widget.active ? Icons.visibility : Icons.visibility_off,
                color: color,
                size: widget.size * 0.28,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CorePainter extends CustomPainter {
  _CorePainter({required this.color, required this.pulse});

  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.12 + 0.18 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius * (0.8 + 0.15 * pulse), glow);

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: 0.5);
    canvas.drawCircle(center, radius * 0.82, outer);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = color.withValues(alpha: 0.75 + 0.25 * pulse);
    canvas.drawCircle(center, radius * 0.6, inner);

    // Tick marks around the ring.
    final ticks = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    const count = 24;
    for (var i = 0; i < count; i++) {
      final a = (i / count) * 2 * math.pi;
      final r1 = radius * 0.86;
      final r2 = radius * 0.94;
      canvas.drawLine(
        center + Offset(math.cos(a) * r1, math.sin(a) * r1),
        center + Offset(math.cos(a) * r2, math.sin(a) * r2),
        ticks,
      );
    }
  }

  @override
  bool shouldRepaint(_CorePainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.color != color;
}

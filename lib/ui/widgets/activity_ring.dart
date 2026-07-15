import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An Apple-Fitness-style progress ring: a dim track with a thick, round-capped
/// progress arc. Values over 1.0 wrap into a second, slightly shadowed lap so
/// "over budget" reads at a glance.
class ActivityRing extends StatelessWidget {
  const ActivityRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 92,
    this.stroke = 11,
    this.child,
  });

  /// Usage ÷ budget. May exceed 1.0.
  final double progress;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 2.0),
          color: color,
          stroke: stroke,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    const start = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    final firstSweep = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      firstSweep,
      false,
      arc,
    );

    // Overshoot: a second lap, with a soft shadow under its leading cap.
    if (progress > 1.0) {
      final extra = (progress - 1.0).clamp(0.0, 1.0) * 2 * math.pi;
      final shadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        extra,
        false,
        shadow,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        extra,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}

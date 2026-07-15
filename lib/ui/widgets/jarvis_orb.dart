import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A colorful glowing orb that pulses gently, and more energetically while
/// Jarvis is speaking.
class JarvisOrb extends StatefulWidget {
  const JarvisOrb({super.key, required this.speaking, this.size = 120});

  final bool speaking;
  final double size;

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final wave = math.sin(_controller.value * 2 * math.pi);
        final intensity = widget.speaking ? 1.0 : 0.45;
        final scale = 1 + 0.06 * wave * intensity;
        final glow = 0.35 + 0.35 * ((wave + 1) / 2) * intensity;

        return SizedBox.square(
          dimension: widget.size,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size * 0.82,
                height: widget.size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFF2EC5FF),
                      Color(0xFF7A5CFF),
                      Color(0xFFFF5CA8),
                      Color(0xFF2EC5FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2EC5FF).withValues(alpha: glow),
                      blurRadius: widget.size * 0.35,
                      spreadRadius: widget.size * 0.02,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7A5CFF).withValues(alpha: glow),
                      blurRadius: widget.size * 0.4,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: widget.size * 0.4,
                    height: widget.size * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

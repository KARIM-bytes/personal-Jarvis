import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Frosted surface. [blur] enables a real backdrop blur — reserve it for hero
/// surfaces (input bars, the overlay card); list cards use the lightweight
/// tint, which reads identically over a dark background at a fraction of the
/// GPU cost.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.s2),
    this.radius = AppTheme.rMd,
    this.blur = false,
    this.fill,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final Color? fill;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final core = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill ?? AppTheme.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppTheme.glassBorder),
      ),
      child: child,
    );
    if (!blur) return core;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: core,
      ),
    );
  }
}

/// Faint aurora glows over black — gives the glass something to catch without
/// ever competing with content.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(top: -140, left: -100, child: _glow(AppTheme.accent, 320)),
        Positioned(top: 60, right: -120, child: _glow(AppTheme.accentAlt, 280)),
        Positioned(bottom: -160, left: 20, child: _glow(AppTheme.pink, 300)),
        child,
      ],
    );
  }

  static Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.09),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercase micro-label above a section — quiet, wide-tracked.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppTheme.s1 / 2, bottom: AppTheme.s1, top: AppTheme.s1),
      child: Row(
        children: [
          Text(text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small frosted pill with a state dot — "Guide active", "Paused".
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.glassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 0.5),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.s1),
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

/// Fades + lifts its child in once on mount; stagger sections with [delayMs].
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final total = delayMs + 420;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: AppTheme.ease),
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Three softly pulsing dots — the chat's "thinking" indicator.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Opacity(
              opacity: 0.25 +
                  0.65 *
                      ((math.sin(2 *
                                      math.pi *
                                      (_c.value - i * 0.18)) +
                                  1) /
                              2)
                          .clamp(0.0, 1.0),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

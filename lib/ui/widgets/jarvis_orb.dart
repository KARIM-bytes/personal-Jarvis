import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// What the orb is doing. Every mood is expressed purely through motion and
/// light; transitions between moods are smoothed, never cut.
enum OrbMood {
  /// Breathing softly. Never completely still.
  idle,

  /// The user is typing — brighter, with a pulse per keystroke.
  listening,

  /// Streams of light orbit the core while the brain works.
  thinking,

  /// Rhythmic outward pulses while Jarvis talks.
  speaking,
}

/// Lets the owner poke the orb about discrete events (keystrokes, message
/// sent) without rebuilding the widget tree.
class JarvisOrbController {
  _JarvisOrbState? _state;

  /// A subtle pulse from the center — call once per keystroke. Pulse speed
  /// follows the typing rhythm.
  void pulse() => _state?.keystrokePulse();

  /// The 150–200 ms inward compression when a message is sent: the glow
  /// gathers toward the core as if absorbing the words.
  void absorb() => _state?.absorb();
}

/// A tiny artificial star in a glass sphere.
///
/// It breathes while waiting, brightens and ripples when listened to,
/// gathers inward when it receives a message, circulates light while it
/// thinks, and radiates in a slow cadence when it speaks. All motion is
/// eased — targets are approached exponentially, so no state ever snaps.
class JarvisOrb extends StatefulWidget {
  const JarvisOrb({
    super.key,
    this.mood = OrbMood.idle,
    this.size = 120,
    this.dormant = false,
    this.controller,
  });

  final OrbMood mood;
  final double size;

  /// Dimmer, slower presence (e.g. the guide is paused). Still alive.
  final bool dormant;

  final JarvisOrbController? controller;

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _Pulse {
  _Pulse({required this.start, required this.duration, required this.big});

  final double start;
  final double duration;

  /// Speaking pulses travel further than keystroke ripples.
  final bool big;
}

class _JarvisOrbState extends State<JarvisOrb>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0);

  // Smoothed levels, eased toward per-mood targets every frame.
  double _brightness = 1.0;
  double _listen = 0.0;
  double _think = 0.0;
  double _speak = 0.0;

  // One-shot absorb envelope.
  double? _absorbStart;

  // Discrete events.
  final List<_Pulse> _pulses = [];
  double _lastKeystrokeAt = -10;
  double _lastAutoPulseAt = -10;

  double _lastTick = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(JarvisOrb old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (t - _lastTick).clamp(0.0, 0.1);
    _lastTick = t;

    // Ease every level toward its mood target — organic, never a jump.
    final k = 1 - math.exp(-dt / 0.35);
    final dormant = widget.dormant;
    final mood = widget.mood;

    final targetBrightness = dormant
        ? 0.5
        : switch (mood) {
            OrbMood.idle => 1.0,
            OrbMood.listening => 1.12,
            OrbMood.thinking => 1.15,
            OrbMood.speaking => 1.18,
          };
    _brightness += (targetBrightness - _brightness) * k;
    _listen += ((mood == OrbMood.listening ? 1.0 : 0.0) - _listen) * k;
    _think += ((mood == OrbMood.thinking ? 1.0 : 0.0) - _think) * k;
    _speak += ((mood == OrbMood.speaking ? 1.0 : 0.0) - _speak) * k;

    // Speaking cadence: one soft outward pulse per "sentence".
    if (_speak > 0.5 && t - _lastAutoPulseAt > 1.15) {
      _lastAutoPulseAt = t;
      _pulses.add(_Pulse(start: t, duration: 1.5, big: true));
    }

    _pulses.removeWhere((p) => t - p.start > p.duration);
    if (_absorbStart != null && t - _absorbStart! > 0.2) _absorbStart = null;

    _time.value = t; // repaints the painter only
  }

  void keystrokePulse() {
    final t = _lastTick;
    // Pulse tempo follows the typing rhythm: quick typing, quick ripples.
    final interval = (t - _lastKeystrokeAt).clamp(0.12, 0.9);
    _lastKeystrokeAt = t;
    _pulses.add(_Pulse(start: t, duration: (interval * 1.6).clamp(0.3, 0.9), big: false));
  }

  void absorb() => _absorbStart = _lastTick;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          willChange: true,
          painter: _OrbPainter(
            time: _time,
            state: this,
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.time, required this.state}) : super(repaint: time);

  final ValueNotifier<double> time;
  final _JarvisOrbState state;

  static const _cyan = Color(0xFF2EC5FF);
  static const _violet = Color(0xFF7A5CFF);
  static const _pink = Color(0xFFFF5CA8);

  double _ease(double p) => 1 - math.pow(1 - p, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final b = state._brightness;
    final think = state._think;
    final speak = state._speak;

    // Breathing: 2.5% over ~3 s, plus a slower secondary drift so the rhythm
    // never feels metronomic. Softer while busy.
    final breathAmp = 0.025 - 0.010 * math.max(think, speak);
    final breath = 1 +
        breathAmp * math.sin(t * 2 * math.pi / 3.0) +
        0.006 * math.sin(t * 2 * math.pi / 7.3);

    // Absorb envelope: ease-in-out compression over ~200 ms.
    double compress = 0;
    final a0 = state._absorbStart;
    if (a0 != null) {
      final p = ((t - a0) / 0.2).clamp(0.0, 1.0);
      compress = math.sin(math.pi * p); // in and back out, no corners
    }

    // Word-level shimmer while speaking.
    final shimmer = 1 + 0.06 * speak * math.sin(t * 2.1 * 2 * math.pi / 2.2);

    final center = size.center(Offset.zero);
    final radius = (size.width / 2) * breath * (1 - 0.12 * compress);
    final glow = (b * shimmer).clamp(0.0, 1.6);

    // Internal color slowly flows cyan → violet while thinking.
    final flow = 0.5 + 0.5 * math.sin(t * 2 * math.pi / 5.0);
    final coreTint =
        Color.lerp(_cyan, _violet, think * flow * 0.7) ?? _cyan;

    // --- Outer halo (fades under compression: light gathers inward) ---------
    canvas.drawCircle(
      center,
      radius * 0.95,
      Paint()
        ..color = _cyan.withValues(
            alpha: (0.15 * glow * (1 - 0.6 * compress)).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45),
    );
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()
        ..color = coreTint.withValues(
            alpha: (0.26 * glow * (1 - 0.4 * compress)).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.25),
    );

    // --- Pulses: keystroke ripples and speaking cadence ---------------------
    for (final pulse in state._pulses) {
      final p = ((t - pulse.start) / pulse.duration).clamp(0.0, 1.0);
      final e = _ease(p);
      final reach = pulse.big ? 1.02 : 0.72;
      final r = radius * (0.22 + (reach - 0.22) * e);
      final alpha = math.pow(1 - p, 2).toDouble() *
          (pulse.big ? 0.34 : 0.26) *
          glow;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * (pulse.big ? 0.05 : 0.035)
          ..color = _cyan.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.04),
      );
    }

    // --- Thinking: streams of light orbiting the core -----------------------
    if (think > 0.01) {
      const speeds = [0.34, 0.26, 0.42]; // rev/s — deliberate, unhurried
      const phases = [0.0, 2.1, 4.2];
      const palette = [_cyan, _violet, _pink];
      for (var i = 0; i < 3; i++) {
        final ang = 2 * math.pi * (t * speeds[i] + phases[i] / (2 * math.pi));
        final orbitR = radius * (0.30 + 0.04 * i);
        final pos = center +
            Offset(math.cos(ang) * orbitR, math.sin(ang) * orbitR * 0.82);
        canvas.drawCircle(
          pos,
          radius * (0.10 + 0.02 * i),
          Paint()
            ..color = palette[i]
                .withValues(alpha: (0.42 * think * glow).clamp(0.0, 1.0))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.10),
        );
      }
    }

    // --- Core: white-hot heart of the star ----------------------------------
    final coreR = radius * (0.50 - 0.16 * compress);
    final coreAlpha = (0.92 * glow + 0.25 * compress).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      coreR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: coreAlpha),
            coreTint.withValues(alpha: (0.70 * glow).clamp(0.0, 1.0)),
            coreTint.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreR)),
    );

    // --- Glass sphere: rim and a soft specular highlight --------------------
    canvas.drawCircle(
      center,
      radius * 0.98,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.07 * glow),
    );
    canvas.drawCircle(
      center + Offset(-radius * 0.32, -radius * 0.36),
      radius * 0.16,
      Paint()
        ..color = Colors.white.withValues(alpha: (0.10 * glow).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.12),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => false;
}

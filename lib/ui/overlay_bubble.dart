import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'widgets/jarvis_orb.dart';

/// The floating card shown over other apps when a budget is blown. Runs in the
/// overlay isolate (entry point `overlayMain`). Deliberately plugin-light:
/// it only shows text, launches the app, and closes itself.
class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble> {
  String _message = 'You have drifted from your goals. Let\'s talk.';
  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map && event['message'] is String) {
        setState(() => _message = event['message'] as String);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openApp() async {
    try {
      const intent = AndroidIntent(
        action: 'action_main',
        package: 'com.karim.personal_jarvis',
        componentName: 'com.karim.personal_jarvis.MainActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK, Flag.FLAG_ACTIVITY_SINGLE_TOP],
      );
      await intent.launch();
    } catch (_) {
      // If launching isn't available in this isolate, the app's notification is
      // the fallback way in.
    }
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0C1524), Color(0xFF120A22)],
            ),
            border: Border.all(color: const Color(0xFF2EC5FF), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x552EC5FF), blurRadius: 40, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speaking cadence: the overlay voices its opener as it appears.
              const JarvisOrb(mood: OrbMood.speaking, size: 96),
              const SizedBox(height: 16),
              const Text('JARVIS',
                  style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, height: 1.4, fontSize: 15.5),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => FlutterOverlayWindow.closeOverlay(),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2EC5FF), Color(0xFF7A5CFF)],
                        ),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _openApp,
                        child: const Text('Talk to Jarvis',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

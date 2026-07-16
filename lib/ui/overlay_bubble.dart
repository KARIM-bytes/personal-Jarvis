import 'dart:async';
import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../theme/app_theme.dart';
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
        // Ease the card in: slight lift + scale, never a pop.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: AppTheme.ease,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.scale(
              scale: 0.94 + 0.06 * v,
              child: Transform.translate(
                  offset: Offset(0, 20 * (1 - v)), child: child),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.rLg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(AppTheme.s3),
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(AppTheme.rLg),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        blurRadius: 60,
                        spreadRadius: 4),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const JarvisOrb(mood: OrbMood.speaking, size: 96),
                    const SizedBox(height: AppTheme.s2),
                    const Text('JARVIS',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            letterSpacing: 4,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppTheme.s2),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          height: 1.45,
                          fontSize: 15),
                    ),
                    const SizedBox(height: AppTheme.s3),
                    Row(
                      children: [
                        Expanded(
                          child: _pillButton(
                            label: 'Dismiss',
                            onTap: () => FlutterOverlayWindow.closeOverlay(),
                          ),
                        ),
                        const SizedBox(width: AppTheme.s2),
                        Expanded(
                          child: _pillButton(
                            label: 'Talk to Jarvis',
                            onTap: _openApp,
                            hero: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required VoidCallback onTap,
    bool hero = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: hero ? AppTheme.heroGradient : null,
        color: hero ? null : const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(AppTheme.rSm + 2),
        border: hero ? null : Border.all(color: AppTheme.glassBorder),
        boxShadow: hero
            ? [
                BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 16),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.rSm + 2),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: hero ? FontWeight.w700 : FontWeight.w600,
                color: hero
                    ? const Color(0xFF03121C)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

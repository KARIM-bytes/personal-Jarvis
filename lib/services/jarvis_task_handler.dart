import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../config/app_config.dart';
import '../models/nag_event.dart';
import '../models/nag_rule.dart';
import 'foreground_app_service.dart';
import 'llm_client.dart';
import 'monitor_engine.dart';
import 'tts_service.dart';

/// Entry point for the background isolate that flutter_foreground_task spins up.
/// Must be a top-level function annotated for AOT retention.
@pragma('vm:entry-point')
void startJarvisCallback() {
  FlutterForegroundTask.setTaskHandler(JarvisTaskHandler());
}

/// Runs the whole nag loop inside the foreground service isolate:
/// sample foreground app → evaluate the rule → on breach, generate a line,
/// speak it, mirror it to the notification, and report it to the UI isolate.
class JarvisTaskHandler extends TaskHandler {
  final ForegroundAppService _apps = ForegroundAppService();
  final LlmClient _llm = LlmClient();
  final TtsService _tts = TtsService();
  final MonitorEngine _engine = MonitorEngine(
    rule: NagRule.defaultRule,
    cooldown: AppConfig.nagCooldown,
  );

  /// Guards against a new tick starting while a slow LLM/TTS pipeline runs.
  bool _busy = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _engine.reset();
    await _tts.init();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _tick(timestamp);
  }

  Future<void> _tick(DateTime now) async {
    if (_busy) return;

    final package = await _apps.currentForegroundPackage();
    final decision = _engine.evaluate(package, now);

    _updateNotification(decision);

    if (!decision.shouldNag) return;

    // Record immediately so overlapping ticks don't double-fire.
    _engine.markNagged(now);
    await _fireNag(decision.continuousUsage, now);
  }

  Future<void> _fireNag(Duration usage, DateTime now) async {
    _busy = true;
    try {
      final line = await _llm.generateNag(
        appLabel: _engine.rule.appLabel,
        usage: usage,
      );
      await _tts.speak(line);

      FlutterForegroundTask.updateService(
        notificationTitle: 'Jarvis: ${_engine.rule.appLabel}',
        notificationText: line,
      );

      final event = NagEvent(
        appLabel: _engine.rule.appLabel,
        appPackage: _engine.rule.appPackage,
        message: line,
        timestamp: now,
        continuousUsage: usage,
      );
      FlutterForegroundTask.sendDataToMain(event.toWire());
    } finally {
      _busy = false;
    }
  }

  void _updateNotification(MonitorDecision decision) {
    if (decision.onWatchedApp) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Jarvis is watching',
        notificationText:
            '${_engine.rule.appLabel}: ${_format(decision.continuousUsage)} and counting…',
      );
    } else {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Jarvis is watching',
        notificationText: 'On duty. Behave yourself.',
      );
    }
  }

  @override
  void onReceiveData(Object data) {
    // Manual trigger from the UI so the loop can be demoed without waiting.
    if (data is String && data.contains('"type":"test"') && !_busy) {
      _fireNag(_engine.rule.threshold, DateTime.now());
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _tts.stop();
    _llm.dispose();
  }

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

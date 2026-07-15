import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../config/app_config.dart';
import '../models/guide_message.dart';
import '../models/message_state.dart';
import '../models/watched_app.dart';
import 'goals_repository.dart';
import 'guide_brain.dart';
import 'llm_client.dart';
import 'usage_stats_service.dart';

@pragma('vm:entry-point')
void startGuideCallback() {
  FlutterForegroundTask.setTaskHandler(GuideTaskHandler());
}

/// Runs the periodic goal-check in the foreground-service isolate: read today's
/// usage totals → let [GuideBrain] decide which watched apps are over budget →
/// compose a tutor message for each and deliver it as a notification, recording
/// state so the Guide never over-messages.
class GuideTaskHandler extends TaskHandler {
  final UsageStatsService _usage = UsageStatsService();
  final GoalsRepository _repo = GoalsRepository();
  final LlmClient _llm = LlmClient();
  final GuideBrain _brain = GuideBrain(cooldown: AppConfig.perAppCooldown);

  bool _busy = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    _check(timestamp);
  }

  Future<void> _check(DateTime now) async {
    if (_busy) return;
    _busy = true;
    try {
      final watched = await _repo.loadWatchedApps();
      if (watched.isEmpty) return;

      final snapshot = await _usage.todayUsage();
      final state = await _repo.loadMessageState();
      final decisions = _brain.evaluate(
        snapshot: snapshot,
        watchedApps: watched,
        state: state,
        now: now,
      );

      for (final decision in decisions) {
        await _deliver(decision.app, decision.usage, now, record: state);
      }
      if (decisions.isNotEmpty) {
        await _repo.saveMessageState(state);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _deliver(
    WatchedApp app,
    Duration usage,
    DateTime now, {
    required Map<String, AppMessageState> record,
  }) async {
    final minutes = usage.inMinutes;
    final budget = app.dailyBudget.inMinutes;
    final text = await _llm.composeGuideMessage(
      appLabel: app.label,
      minutesSpent: minutes,
      budgetMinutes: budget,
    );

    FlutterForegroundTask.updateService(
      notificationTitle: 'Your guide',
      notificationText: text,
    );
    FlutterForegroundTask.sendDataToMain(
      GuideMessage(
        appLabel: app.label,
        appPackage: app.packageName,
        text: text,
        timestamp: now,
        minutesSpent: minutes,
        budgetMinutes: budget,
      ).toWire(),
    );

    record[app.packageName] =
        GuideBrain.recordSent(record[app.packageName], now);
  }

  @override
  void onReceiveData(Object data) {
    // Manual trigger from the UI to preview a message without waiting.
    if (data is String && data.contains('"type":"test"') && !_busy) {
      _testMessage(DateTime.now());
    }
  }

  Future<void> _testMessage(DateTime now) async {
    _busy = true;
    try {
      final watched = await _repo.loadWatchedApps();
      final app = watched.isNotEmpty
          ? watched.first
          : const WatchedApp(
              packageName: 'com.instagram.android',
              label: 'Instagram',
              dailyBudget: Duration(minutes: 30),
            );
      final actual = (await _usage.todayUsage()).usageFor(app.packageName);
      final usage = actual > app.dailyBudget
          ? actual
          : app.dailyBudget + const Duration(minutes: 15);
      // Deliver but do not record state — it's only a preview.
      final scratch = <String, AppMessageState>{};
      await _deliver(app, usage, now, record: scratch);
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _llm.dispose();
  }
}

import '../models/app_usage.dart';
import '../models/message_state.dart';
import '../models/watched_app.dart';

/// A decision to message the user about one over-budget app.
class GuideDecision {
  const GuideDecision({required this.app, required this.usage});

  final WatchedApp app;
  final Duration usage;
}

/// The brain. Given today's usage totals, the user's watched apps (with their
/// budgets) and how the Guide has already messaged today, it decides which apps
/// warrant a nudge right now.
///
/// Pure and I/O-free so it can be unit-tested and run safely in the background
/// isolate. Rules:
///  - only apps at or over their daily budget qualify;
///  - at most 2 messages per app per day;
///  - the 2nd message only once usage doubles the budget (real backsliding);
///  - never two messages about the same app within [cooldown].
class GuideBrain {
  GuideBrain({this.cooldown = Duration.zero});

  final Duration cooldown;

  List<GuideDecision> evaluate({
    required UsageSnapshot snapshot,
    required List<WatchedApp> watchedApps,
    required Map<String, AppMessageState> state,
    required DateTime now,
  }) {
    final today = dateKey(now);
    final decisions = <GuideDecision>[];

    for (final app in watchedApps) {
      final usage = snapshot.usageFor(app.packageName);
      if (usage < app.dailyBudget) continue;

      final existing = state[app.packageName];
      final isNewDay = existing == null || existing.date != today;
      final count = isNewDay ? 0 : existing.count;
      final lastAt = isNewDay ? null : existing.lastAt;

      if (count >= 2) continue;
      if (count == 1 && usage < app.dailyBudget * 2) continue;
      if (lastAt != null && now.difference(lastAt) < cooldown) continue;

      decisions.add(GuideDecision(app: app, usage: usage));
    }

    return decisions;
  }

  /// Advances an app's message state after a message is actually sent.
  static AppMessageState recordSent(
    AppMessageState? previous,
    DateTime now,
  ) {
    final today = dateKey(now);
    final sameDay = previous != null && previous.date == today;
    return AppMessageState(
      date: today,
      count: (sameDay ? previous.count : 0) + 1,
      lastAt: now,
    );
  }

  static String dateKey(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '${t.year}-$m-$d';
  }
}

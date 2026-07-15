import '../models/nag_rule.dart';

/// The outcome of one sampling tick.
class MonitorDecision {
  const MonitorDecision({
    required this.onWatchedApp,
    required this.continuousUsage,
    required this.shouldNag,
  });

  /// Whether the watched app is currently in the foreground.
  final bool onWatchedApp;

  /// How long the watched app has been continuously foregrounded (zero when
  /// it is not the current app).
  final Duration continuousUsage;

  /// Whether this tick crosses the threshold and a nag should fire.
  final bool shouldNag;
}

/// Pure rule-evaluation state machine.
///
/// Feed it the foreground package on every tick via [evaluate]; it tracks how
/// long the watched app has been continuously in front and decides when to
/// nag. It holds no timers and does no I/O, which keeps it unit-testable and
/// safe to run inside the background isolate. Call [markNagged] right after a
/// nag actually fires so the same session is not scolded twice.
class MonitorEngine {
  MonitorEngine({
    required this.rule,
    this.cooldown = Duration.zero,
  });

  final NagRule rule;

  /// Minimum time between nags, measured across foreground sessions.
  final Duration cooldown;

  String? _currentPackage;
  DateTime? _enteredAt;
  bool _naggedThisSession = false;
  DateTime? _lastNagAt;

  MonitorDecision evaluate(String? foregroundPackage, DateTime now) {
    // A change of foreground app starts a fresh continuous session.
    if (foregroundPackage != _currentPackage) {
      _currentPackage = foregroundPackage;
      _enteredAt = foregroundPackage == null ? null : now;
      _naggedThisSession = false;
    }

    final onWatched = foregroundPackage == rule.appPackage;
    final enteredAt = _enteredAt;
    if (!onWatched || enteredAt == null) {
      return const MonitorDecision(
        onWatchedApp: false,
        continuousUsage: Duration.zero,
        shouldNag: false,
      );
    }

    final elapsed = now.difference(enteredAt);
    final thresholdBreached = elapsed >= rule.threshold;
    final cooldownElapsed =
        _lastNagAt == null || now.difference(_lastNagAt!) >= cooldown;
    final shouldNag =
        thresholdBreached && !_naggedThisSession && cooldownElapsed;

    return MonitorDecision(
      onWatchedApp: true,
      continuousUsage: elapsed,
      shouldNag: shouldNag,
    );
  }

  /// Records that a nag fired at [now]; blocks re-nagging this session and
  /// starts the cooldown window.
  void markNagged(DateTime now) {
    _naggedThisSession = true;
    _lastNagAt = now;
  }

  /// Clears session state (e.g. when monitoring restarts).
  void reset() {
    _currentPackage = null;
    _enteredAt = null;
    _naggedThisSession = false;
    _lastNagAt = null;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_jarvis/models/nag_rule.dart';
import 'package:personal_jarvis/services/monitor_engine.dart';

void main() {
  const watched = 'com.instagram.android';
  const rule = NagRule(
    id: 'test',
    appPackage: watched,
    appLabel: 'Instagram',
    threshold: Duration(minutes: 2),
  );

  DateTime t(int seconds) => DateTime(2026, 1, 1).add(Duration(seconds: seconds));

  test('does not nag before the threshold is reached', () {
    final engine = MonitorEngine(rule: rule);
    expect(engine.evaluate(watched, t(0)).shouldNag, isFalse);
    expect(engine.evaluate(watched, t(60)).shouldNag, isFalse);
    final decision = engine.evaluate(watched, t(119));
    expect(decision.onWatchedApp, isTrue);
    expect(decision.shouldNag, isFalse);
  });

  test('nags exactly once when continuous usage crosses the threshold', () {
    final engine = MonitorEngine(rule: rule);
    engine.evaluate(watched, t(0));
    final breach = engine.evaluate(watched, t(120));
    expect(breach.shouldNag, isTrue);
    expect(breach.continuousUsage, const Duration(minutes: 2));

    engine.markNagged(t(120));
    // Still on the app, but the same session must not nag again.
    expect(engine.evaluate(watched, t(180)).shouldNag, isFalse);
  });

  test('leaving and returning starts a fresh session and can nag again', () {
    final engine = MonitorEngine(rule: rule);
    engine.evaluate(watched, t(0));
    expect(engine.evaluate(watched, t(120)).shouldNag, isTrue);
    engine.markNagged(t(120));

    // Switch away — timer resets.
    final away = engine.evaluate('com.android.launcher', t(130));
    expect(away.onWatchedApp, isFalse);
    expect(away.continuousUsage, Duration.zero);

    // Come back — must build up 2 more minutes before nagging.
    engine.evaluate(watched, t(140));
    expect(engine.evaluate(watched, t(200)).shouldNag, isFalse);
    expect(engine.evaluate(watched, t(260)).shouldNag, isTrue);
  });

  test('cooldown suppresses a nag from a new session too soon after the last',
      () {
    final engine = MonitorEngine(
      rule: rule,
      cooldown: const Duration(minutes: 5),
    );
    engine.evaluate(watched, t(0));
    expect(engine.evaluate(watched, t(120)).shouldNag, isTrue);
    engine.markNagged(t(120));

    // New session, threshold met, but within cooldown of the last nag.
    engine.evaluate('com.android.launcher', t(130));
    engine.evaluate(watched, t(140));
    expect(engine.evaluate(watched, t(260)).shouldNag, isFalse);

    // After the cooldown elapses, a fresh breach nags again.
    engine.evaluate('com.android.launcher', t(500));
    engine.evaluate(watched, t(510));
    expect(engine.evaluate(watched, t(630)).shouldNag, isTrue);
  });

  test('non-watched apps never nag', () {
    final engine = MonitorEngine(rule: rule);
    for (var s = 0; s <= 600; s += 30) {
      expect(engine.evaluate('com.whatsapp', t(s)).shouldNag, isFalse);
    }
  });
}

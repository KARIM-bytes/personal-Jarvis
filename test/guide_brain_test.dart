import 'package:flutter_test/flutter_test.dart';
import 'package:personal_jarvis/models/app_usage.dart';
import 'package:personal_jarvis/models/watched_app.dart';
import 'package:personal_jarvis/services/guide_brain.dart';

void main() {
  const pkg = 'com.instagram.android';
  const app = WatchedApp(
    packageName: pkg,
    label: 'Instagram',
    dailyBudget: Duration(minutes: 30),
  );

  UsageSnapshot snapshotOf(int minutes) => UsageSnapshot([
        AppUsage(
          packageName: pkg,
          label: 'Instagram',
          usage: Duration(minutes: minutes),
        ),
      ]);

  final now = DateTime(2026, 3, 10, 14, 0);
  final brain = GuideBrain(cooldown: const Duration(hours: 3));

  test('no decision while under budget', () {
    final d = brain.evaluate(
      snapshot: snapshotOf(20),
      watchedApps: const [app],
      state: const {},
      now: now,
    );
    expect(d, isEmpty);
  });

  test('one decision when first crossing budget', () {
    final d = brain.evaluate(
      snapshot: snapshotOf(35),
      watchedApps: const [app],
      state: const {},
      now: now,
    );
    expect(d, hasLength(1));
    expect(d.first.app.packageName, pkg);
    expect(d.first.usage, const Duration(minutes: 35));
  });

  test('after first message, no second until usage doubles the budget', () {
    final state = {pkg: GuideBrain.recordSent(null, now)};
    final later = now.add(const Duration(hours: 4)); // past cooldown

    // 50m: over budget but under 2x (60m) -> still silent.
    expect(
      brain.evaluate(
          snapshot: snapshotOf(50),
          watchedApps: const [app],
          state: state,
          now: later),
      isEmpty,
    );

    // 65m: past 2x -> a second message is warranted.
    expect(
      brain.evaluate(
          snapshot: snapshotOf(65),
          watchedApps: const [app],
          state: state,
          now: later),
      hasLength(1),
    );
  });

  test('cooldown suppresses a second message even past 2x budget', () {
    final state = {pkg: GuideBrain.recordSent(null, now)};
    final soon = now.add(const Duration(minutes: 30)); // within 3h cooldown
    expect(
      brain.evaluate(
          snapshot: snapshotOf(90),
          watchedApps: const [app],
          state: state,
          now: soon),
      isEmpty,
    );
  });

  test('caps at two messages per day', () {
    var state = {pkg: GuideBrain.recordSent(null, now)};
    state = {pkg: GuideBrain.recordSent(state[pkg], now)}; // count == 2
    final later = now.add(const Duration(hours: 6));
    expect(
      brain.evaluate(
          snapshot: snapshotOf(200),
          watchedApps: const [app],
          state: state,
          now: later),
      isEmpty,
    );
  });

  test('a new day resets the counter', () {
    final state = {pkg: GuideBrain.recordSent(null, now)};
    state[pkg] = GuideBrain.recordSent(state[pkg], now); // 2 today
    final tomorrow = DateTime(2026, 3, 11, 9, 0);
    expect(
      brain.evaluate(
          snapshot: snapshotOf(35),
          watchedApps: const [app],
          state: state,
          now: tomorrow),
      hasLength(1),
    );
  });

  test('recordSent increments within a day and resets across days', () {
    final first = GuideBrain.recordSent(null, now);
    expect(first.count, 1);
    final second = GuideBrain.recordSent(first, now);
    expect(second.count, 2);
    final nextDay = GuideBrain.recordSent(second, DateTime(2026, 3, 11, 8));
    expect(nextDay.count, 1);
  });
}

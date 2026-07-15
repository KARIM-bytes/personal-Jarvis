import 'package:flutter/services.dart';

import '../models/app_usage.dart';

/// Bridge to native Android UsageStats — the same aggregated data the built-in
/// Digital Wellbeing screen shows. Requires the special "Usage access"
/// permission, granted from a system settings screen.
class UsageStatsService {
  static const MethodChannel _channel = MethodChannel('jarvis/usage');

  Future<bool> hasUsageAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openUsageAccessSettings');
    } on PlatformException {
      // Nothing to do if the intent cannot be launched.
    }
  }

  /// Total foreground time per app since local midnight.
  Future<UsageSnapshot> todayUsage() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getUsageToday');
      final apps = (raw ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map(AppUsage.fromChannel)
          .where((a) => a.usage > Duration.zero)
          .toList()
        ..sort((a, b) => b.usage.compareTo(a.usage));
      return UsageSnapshot(apps);
    } on PlatformException {
      return UsageSnapshot(const []);
    }
  }
}

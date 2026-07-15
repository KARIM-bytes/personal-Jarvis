/// One app's total foreground time today, as reported by UsageStats.
class AppUsage {
  const AppUsage({
    required this.packageName,
    required this.label,
    required this.usage,
  });

  final String packageName;
  final String label;
  final Duration usage;

  factory AppUsage.fromChannel(Map<dynamic, dynamic> map) => AppUsage(
        packageName: (map['packageName'] ?? '') as String,
        label: (map['label'] ?? map['packageName'] ?? '') as String,
        usage: Duration(milliseconds: (map['totalTimeMs'] as num).toInt()),
      );
}

/// Today's usage totals, keyed by package name for quick lookup.
class UsageSnapshot {
  UsageSnapshot(this.apps)
      : _byPackage = {for (final a in apps) a.packageName: a};

  final List<AppUsage> apps;
  final Map<String, AppUsage> _byPackage;

  Duration usageFor(String packageName) =>
      _byPackage[packageName]?.usage ?? Duration.zero;

  String? labelFor(String packageName) => _byPackage[packageName]?.label;
}

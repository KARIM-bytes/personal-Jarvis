import '../config/app_config.dart';

/// A single "you shouldn't be doing this" rule.
///
/// v1 ships exactly one hardcoded rule (see [NagRule.defaultRule]); the model
/// is kept general so a rules engine can be layered on in v2.
class NagRule {
  const NagRule({
    required this.id,
    required this.appPackage,
    required this.appLabel,
    required this.threshold,
  });

  final String id;
  final String appPackage;
  final String appLabel;

  /// Continuous foreground time on [appPackage] that triggers a nag.
  final Duration threshold;

  /// The one rule Jarvis enforces in v1.
  static const NagRule defaultRule = NagRule(
    id: 'instagram-2min',
    appPackage: AppConfig.watchedPackage,
    appLabel: AppConfig.watchedLabel,
    threshold: AppConfig.nagThreshold,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'appPackage': appPackage,
        'appLabel': appLabel,
        'thresholdMs': threshold.inMilliseconds,
      };

  factory NagRule.fromJson(Map<String, dynamic> json) => NagRule(
        id: json['id'] as String,
        appPackage: json['appPackage'] as String,
        appLabel: json['appLabel'] as String,
        threshold: Duration(milliseconds: json['thresholdMs'] as int),
      );
}

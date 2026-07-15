import '../config/app_config.dart';

/// An app the user has flagged as a distraction, with a daily time budget.
class WatchedApp {
  const WatchedApp({
    required this.packageName,
    required this.label,
    required this.dailyBudget,
  });

  final String packageName;
  final String label;
  final Duration dailyBudget;

  WatchedApp copyWith({String? label, Duration? dailyBudget}) => WatchedApp(
        packageName: packageName,
        label: label ?? this.label,
        dailyBudget: dailyBudget ?? this.dailyBudget,
      );

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'label': label,
        'budgetMinutes': dailyBudget.inMinutes,
      };

  factory WatchedApp.fromJson(Map<String, dynamic> json) => WatchedApp(
        packageName: json['packageName'] as String,
        label: json['label'] as String,
        dailyBudget: Duration(
          minutes: (json['budgetMinutes'] as num?)?.toInt() ??
              AppConfig.defaultBudgetMinutes,
        ),
      );
}

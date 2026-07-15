import 'dart:convert';

/// A message the Guide sent, kept for the in-app history.
///
/// Travels from the background isolate to the UI isolate as a JSON envelope.
class GuideMessage {
  const GuideMessage({
    required this.appLabel,
    required this.appPackage,
    required this.text,
    required this.timestamp,
    required this.minutesSpent,
    required this.budgetMinutes,
  });

  final String appLabel;
  final String appPackage;
  final String text;
  final DateTime timestamp;
  final int minutesSpent;
  final int budgetMinutes;

  Map<String, dynamic> toJson() => {
        'appLabel': appLabel,
        'appPackage': appPackage,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'minutesSpent': minutesSpent,
        'budgetMinutes': budgetMinutes,
      };

  factory GuideMessage.fromJson(Map<String, dynamic> json) => GuideMessage(
        appLabel: json['appLabel'] as String,
        appPackage: json['appPackage'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        minutesSpent: (json['minutesSpent'] as num).toInt(),
        budgetMinutes: (json['budgetMinutes'] as num).toInt(),
      );

  String toWire() => jsonEncode({'type': 'guide_message', 'payload': toJson()});

  static GuideMessage? fromWire(Object data) {
    if (data is! String) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic> &&
          decoded['type'] == 'guide_message') {
        return GuideMessage.fromJson(decoded['payload'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Not our payload.
    }
    return null;
  }
}

import 'dart:convert';

/// A record of one time Jarvis called the user out.
///
/// Instances travel from the background isolate to the UI isolate encoded as
/// JSON (see [toWire]/[fromWire]), so keep every field primitive.
class NagEvent {
  const NagEvent({
    required this.appLabel,
    required this.appPackage,
    required this.message,
    required this.timestamp,
    required this.continuousUsage,
  });

  final String appLabel;
  final String appPackage;

  /// The scold line that was spoken.
  final String message;

  /// When the nag fired.
  final DateTime timestamp;

  /// How long the app had been continuously in the foreground at nag time.
  final Duration continuousUsage;

  Map<String, dynamic> toJson() => {
        'appLabel': appLabel,
        'appPackage': appPackage,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'continuousUsageMs': continuousUsage.inMilliseconds,
      };

  factory NagEvent.fromJson(Map<String, dynamic> json) => NagEvent(
        appLabel: json['appLabel'] as String,
        appPackage: json['appPackage'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        continuousUsage:
            Duration(milliseconds: json['continuousUsageMs'] as int),
      );

  /// Envelope so the UI isolate can tell a nag payload apart from any other
  /// data the task handler might send later.
  String toWire() => jsonEncode({'type': 'nag', 'payload': toJson()});

  /// Returns a [NagEvent] if [data] is a nag envelope, otherwise null.
  static NagEvent? fromWire(Object data) {
    if (data is! String) return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic> && decoded['type'] == 'nag') {
        return NagEvent.fromJson(decoded['payload'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Not our payload; ignore.
    }
    return null;
  }
}

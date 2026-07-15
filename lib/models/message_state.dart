/// Per-app record of how the Guide has messaged about an app *today*, used to
/// enforce the daily cap and cooldown so the Guide never spams.
class AppMessageState {
  const AppMessageState({
    required this.date,
    required this.count,
    required this.lastAt,
  });

  /// Local calendar day, "yyyy-mm-dd".
  final String date;

  /// How many times the Guide has messaged about this app on [date].
  final int count;

  final DateTime? lastAt;

  Map<String, dynamic> toJson() => {
        'date': date,
        'count': count,
        'lastAtMs': lastAt?.millisecondsSinceEpoch,
      };

  factory AppMessageState.fromJson(Map<String, dynamic> json) =>
      AppMessageState(
        date: json['date'] as String,
        count: (json['count'] as num).toInt(),
        lastAt: json['lastAtMs'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (json['lastAtMs'] as num).toInt()),
      );

  static Map<String, AppMessageState> decodeMap(Map<String, dynamic> raw) {
    return raw.map(
      (key, value) => MapEntry(
        key,
        AppMessageState.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  static Map<String, dynamic> encodeMap(Map<String, AppMessageState> map) {
    return map.map((key, value) => MapEntry(key, value.toJson()));
  }
}

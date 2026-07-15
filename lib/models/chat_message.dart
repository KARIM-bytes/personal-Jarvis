/// One line in the Jarvis conversation.
class ChatMessage {
  const ChatMessage({required this.fromJarvis, required this.text});

  final bool fromJarvis;
  final String text;

  /// Role string for the Anthropic messages API.
  String get role => fromJarvis ? 'assistant' : 'user';
}

/// The context that seeds a conversation — the breach that triggered it.
class ConversationSeed {
  const ConversationSeed({
    required this.appLabel,
    required this.appPackage,
    required this.minutesSpent,
    required this.budgetMinutes,
    required this.opener,
  });

  final String appLabel;
  final String appPackage;
  final int minutesSpent;
  final int budgetMinutes;

  /// Jarvis's first line (the nudge).
  final String opener;

  Map<String, dynamic> toJson() => {
        'appLabel': appLabel,
        'appPackage': appPackage,
        'minutesSpent': minutesSpent,
        'budgetMinutes': budgetMinutes,
        'opener': opener,
      };

  factory ConversationSeed.fromJson(Map<String, dynamic> json) =>
      ConversationSeed(
        appLabel: json['appLabel'] as String,
        appPackage: json['appPackage'] as String,
        minutesSpent: (json['minutesSpent'] as num).toInt(),
        budgetMinutes: (json['budgetMinutes'] as num).toInt(),
        opener: json['opener'] as String,
      );
}

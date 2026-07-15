/// Central configuration for the Guide.
///
/// The Guide reads the phone's own aggregated usage (the Digital Wellbeing
/// numbers, via UsageStats), compares each watched app against a daily budget,
/// and — when a budget is crossed — has an AI tutor message the user, tying the
/// overuse back to the goals they set.
class AppConfig {
  AppConfig._();

  /// How often the background check samples today's usage totals.
  static const Duration checkInterval = Duration(minutes: 15);

  /// Minimum gap between two guide messages about the *same* app in one day.
  static const Duration perAppCooldown = Duration(hours: 3);

  /// Budget applied to a newly added watched app until the user changes it.
  static const int defaultBudgetMinutes = 30;

  /// A short curated list to seed the "add distraction" picker, so the user
  /// isn't starting from a blank slate.
  static const Map<String, String> commonDistractions = {
    'com.instagram.android': 'Instagram',
    'com.google.android.youtube': 'YouTube',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.twitter.android': 'X',
    'com.reddit.frontpage': 'Reddit',
    'com.facebook.katana': 'Facebook',
    'com.snapchat.android': 'Snapchat',
    'com.netflix.mediaclient': 'Netflix',
  };

  // --- Persistence keys -----------------------------------------------------

  static const String prefsGoals = 'life_goals';
  static const String prefsWatchedApps = 'watched_apps';
  static const String prefsMessageState = 'message_state';
  static const String prefsApiKey = 'llm_api_key';

  /// A nudge waiting to open as a conversation (written by the background check
  /// on a breach, read by the app when it comes to the front).
  static const String prefsPendingConversation = 'pending_conversation';

  // --- LLM (optional) -------------------------------------------------------

  static const String llmEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String llmModel = 'claude-haiku-4-5';
  static const String llmApiVersion = '2023-06-01';
  static const int llmMaxTokens = 120;

  /// Builds the prompt that turns raw usage + goals into a tutor's nudge.
  static String guidePrompt({
    required String goals,
    required String appLabel,
    required int minutesSpent,
    required int budgetMinutes,
  }) {
    final goalsBlock = goals.trim().isEmpty
        ? 'The user has not written specific goals; speak to general focus and '
            'intentional time.'
        : 'The user\'s stated goals in life:\n$goals';

    return 'You are the user\'s personal guide and tutor — warm, direct, and '
        'invested in their growth, like a mentor who actually cares. '
        '$goalsBlock\n\n'
        'Today they have spent $minutesSpent minutes on $appLabel, past their '
        'self-set budget of $budgetMinutes minutes. In 1-2 sentences, gently '
        'but firmly point out the gap between this and what they said they want '
        'to achieve, and nudge them back. Address them directly. No preamble, '
        'no quotes, no emoji.';
  }

  /// System framing for the back-and-forth conversation after the pop-up. The
  /// user types; Jarvis replies out loud.
  static String conversationSystem({
    required String goals,
    required String appLabel,
    required int minutesSpent,
    required int budgetMinutes,
  }) {
    final goalsBlock = goals.trim().isEmpty
        ? 'The user has not written specific goals; speak to focus and '
            'intentional time.'
        : 'The user\'s stated goals:\n$goals';

    return 'You are Jarvis, the user\'s personal guide — warm, witty, and '
        'genuinely on their side, like a mentor who wants them to win. '
        'You just pulled them aside because they have spent $minutesSpent '
        'minutes on $appLabel today, past their $budgetMinutes-minute budget. '
        '$goalsBlock\n\n'
        'Have a short spoken conversation. Keep every reply to 1-2 sentences, '
        'natural and human — this is being read aloud. Take them seriously, '
        'help them decide what to do next, and do not lecture. No emoji, no '
        'stage directions, no markdown.';
  }
}

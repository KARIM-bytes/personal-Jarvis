/// Central configuration for the Jarvis Wellbeing Nagger.
///
/// v1 keeps everything hardcoded here (per the PRD MVP scope) except the
/// optional LLM API key, which the user can set at runtime in Settings.
class AppConfig {
  AppConfig._();

  /// Package name of the app Jarvis watches in v1.
  static const String watchedPackage = 'com.instagram.android';

  /// Human-friendly label for the watched app.
  static const String watchedLabel = 'Instagram';

  /// How long the watched app must stay continuously in the foreground
  /// before Jarvis scolds you.
  static const Duration nagThreshold = Duration(minutes: 2);

  /// How often the background service samples the foreground app.
  static const Duration pollInterval = Duration(seconds: 5);

  /// Minimum gap between two nags for the same app, so Jarvis does not
  /// turn into a broken record.
  static const Duration nagCooldown = Duration(minutes: 3);

  /// Foreground-service notification channel.
  static const String notificationChannelId = 'jarvis_monitor';
  static const String notificationChannelName = 'Jarvis Monitoring';
  static const String notificationChannelDescription =
      'Keeps Jarvis watching over your shoulder in the background.';

  // --- LLM (optional) -------------------------------------------------------

  /// SharedPreferences key under which the optional API key is stored.
  static const String prefsApiKey = 'llm_api_key';

  /// Anthropic Messages API endpoint. The client only calls this when an API
  /// key has been provided; otherwise it falls back to built-in scold lines.
  static const String llmEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String llmModel = 'claude-haiku-4-5';
  static const String llmApiVersion = '2023-06-01';
  static const int llmMaxTokens = 80;

  /// Prompt template used to generate a scold line.
  static String nagPrompt(String appLabel, Duration usage) {
    final minutes = usage.inMinutes;
    return 'You are Jarvis, a dry, witty AI assistant. In ONE short sentence, '
        'scold the user for wasting about $minutes minutes on $appLabel right '
        'now. Be cheeky but not cruel. No quotes, no emoji, no preamble.';
  }
}

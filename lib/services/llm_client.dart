import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Produces a one-line Jarvis scold.
///
/// If the user has saved an API key (Settings → LLM key), it asks an Anthropic
/// model for a fresh line. Otherwise — and whenever the network call fails — it
/// falls back to a built-in pool so the loop always completes. Per the PRD,
/// proving the plumbing matters more than the wit.
class LlmClient {
  LlmClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Random _random = Random();

  static const List<String> _fallbackLines = [
    'Really? {app} again? Your future self is filing a complaint.',
    "That's {minutes} minutes of {app} you're never getting back, sir.",
    'I calculate a 0 percent chance this scroll improves your life.',
    'Still on {app}? I was built for greatness, and yet here we are.',
    "Put it down. {app} will survive without your undivided attention.",
    'Fascinating. {minutes} minutes and counting. Shall I alert the biographers?',
    "This is the part where a responsible assistant intervenes. So: stop.",
    'You have now out-scrolled {minutes} minutes of your own ambitions.',
  ];

  Future<String> generateNag({
    required String appLabel,
    required Duration usage,
  }) async {
    final apiKey = await _readApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      final line = await _generateViaAnthropic(
        apiKey: apiKey,
        appLabel: appLabel,
        usage: usage,
      );
      if (line != null && line.isNotEmpty) return line;
    }
    return _fallbackLine(appLabel, usage);
  }

  Future<String?> _readApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConfig.prefsApiKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _generateViaAnthropic({
    required String apiKey,
    required String appLabel,
    required Duration usage,
  }) async {
    try {
      final response = await _http
          .post(
            Uri.parse(AppConfig.llmEndpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': AppConfig.llmApiVersion,
            },
            body: jsonEncode({
              'model': AppConfig.llmModel,
              'max_tokens': AppConfig.llmMaxTokens,
              'messages': [
                {
                  'role': 'user',
                  'content': AppConfig.nagPrompt(appLabel, usage),
                }
              ],
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['content'];
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map && first['type'] == 'text') {
          return (first['text'] as String).trim();
        }
      }
      return null;
    } catch (_) {
      // Network/timeout/parse issues all fall back to a canned line.
      return null;
    }
  }

  String _fallbackLine(String appLabel, Duration usage) {
    final template = _fallbackLines[_random.nextInt(_fallbackLines.length)];
    return template
        .replaceAll('{app}', appLabel)
        .replaceAll('{minutes}', usage.inMinutes.toString());
  }

  void dispose() => _http.close();
}

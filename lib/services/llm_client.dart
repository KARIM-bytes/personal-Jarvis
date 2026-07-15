import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/chat_message.dart';
import 'goals_repository.dart';

/// Turns "app X is over budget, here are the user's goals" into a short,
/// tutor-style nudge.
///
/// Uses an Anthropic model when the user has saved an API key; otherwise — and
/// whenever the call fails — it falls back to built-in lines so a message is
/// always produced.
class LlmClient {
  LlmClient({http.Client? httpClient, GoalsRepository? repository})
      : _http = httpClient ?? http.Client(),
        _repo = repository ?? GoalsRepository();

  final http.Client _http;
  final GoalsRepository _repo;
  final Random _random = Random();

  static const List<String> _fallbackWithGoals = [
    'You wanted to work toward your goals today — {minutes} minutes on {app} is '
        'time that could go there instead. Come back to it.',
    "That's {minutes} minutes on {app}. Your future self, the one chasing what "
        'you wrote down, is waiting. Let\'s redirect.',
    'Be honest: is {app} moving you closer to what you said matters? {minutes} '
        'minutes in, probably not. Small course-correct now.',
  ];

  static const List<String> _fallbackNoGoals = [
    "{minutes} minutes on {app} today, past your {budget}-minute budget. Worth "
        'a pause?',
    'You set a {budget}-minute limit on {app} for a reason. You\'re at '
        '{minutes}. Time to step away.',
    'Gentle check-in: {app} is at {minutes} minutes. Let\'s spend the next hour '
        'on something you\'ll be glad you did.',
  ];

  Future<String> composeGuideMessage({
    required String appLabel,
    required int minutesSpent,
    required int budgetMinutes,
  }) async {
    final goals = await _repo.loadGoals();
    final apiKey = await _repo.loadApiKey();

    if (apiKey != null && apiKey.isNotEmpty) {
      final line = await _viaAnthropic(
        apiKey: apiKey,
        goals: goals,
        appLabel: appLabel,
        minutesSpent: minutesSpent,
        budgetMinutes: budgetMinutes,
      );
      if (line != null && line.isNotEmpty) return line;
    }

    return _fallback(goals, appLabel, minutesSpent, budgetMinutes);
  }

  Future<String?> _viaAnthropic({
    required String apiKey,
    required String goals,
    required String appLabel,
    required int minutesSpent,
    required int budgetMinutes,
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
                  'content': AppConfig.guidePrompt(
                    goals: goals,
                    appLabel: appLabel,
                    minutesSpent: minutesSpent,
                    budgetMinutes: budgetMinutes,
                  ),
                }
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

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
      return null;
    }
  }

  String _fallback(
    String goals,
    String appLabel,
    int minutesSpent,
    int budgetMinutes,
  ) {
    final pool = goals.trim().isEmpty ? _fallbackNoGoals : _fallbackWithGoals;
    return pool[_random.nextInt(pool.length)]
        .replaceAll('{app}', appLabel)
        .replaceAll('{minutes}', minutesSpent.toString())
        .replaceAll('{budget}', budgetMinutes.toString());
  }

  // --- Conversation ---------------------------------------------------------

  static const List<String> _fallbackReplies = [
    "Fair enough. What's one thing you could do in the next ten minutes that "
        'you\'d actually be proud of?',
    'I hear you. Let\'s make a deal: close it now, come back to it tonight if '
        'you still want to.',
    'Okay. But be honest with yourself — is this the break you needed, or the '
        'one you\'re hiding in?',
    'That\'s okay, no guilt. Just put the phone down for now and take the win.',
  ];

  /// Continues the conversation. [history] starts with Jarvis's opener, then
  /// alternates user/Jarvis. Returns Jarvis's next line.
  Future<String> converse({
    required ConversationSeed seed,
    required List<ChatMessage> history,
  }) async {
    final goals = await _repo.loadGoals();
    final apiKey = await _repo.loadApiKey();

    if (apiKey != null && apiKey.isNotEmpty) {
      final reply = await _converseViaAnthropic(apiKey, goals, seed, history);
      if (reply != null && reply.isNotEmpty) return reply;
    }
    return _fallbackReplies[_random.nextInt(_fallbackReplies.length)];
  }

  Future<String?> _converseViaAnthropic(
    String apiKey,
    String goals,
    ConversationSeed seed,
    List<ChatMessage> history,
  ) async {
    try {
      final system = '${AppConfig.conversationSystem(
        goals: goals,
        appLabel: seed.appLabel,
        minutesSpent: seed.minutesSpent,
        budgetMinutes: seed.budgetMinutes,
      )}\n\nYou already opened with: "${seed.opener}"';

      // Drop the opener so the message list starts with the user's reply, as
      // the API requires.
      final turns = history
          .skip(1)
          .map((m) => {'role': m.role, 'content': m.text})
          .toList();
      if (turns.isEmpty) return null;

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
              'system': system,
              'messages': turns,
            }),
          )
          .timeout(const Duration(seconds: 12));

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
      return null;
    }
  }

  void dispose() => _http.close();
}

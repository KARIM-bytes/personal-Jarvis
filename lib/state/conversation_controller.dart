import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/llm_client.dart';
import '../services/tts_service.dart';

/// Drives one Jarvis conversation: seeds it with the opener (spoken aloud),
/// takes typed replies, asks the brain for Jarvis's next line, and speaks it.
class ConversationController extends ChangeNotifier {
  ConversationController({
    required this.seed,
    LlmClient? llm,
    TtsService? tts,
  })  : _llm = llm ?? LlmClient(),
        _tts = tts ?? TtsService() {
    _tts.onStart = () {
      _speaking = true;
      notifyListeners();
    };
    _tts.onComplete = () {
      _speaking = false;
      notifyListeners();
    };
    _messages.add(ChatMessage(fromJarvis: true, text: seed.opener));
  }

  final ConversationSeed seed;
  final LlmClient _llm;
  final TtsService _tts;

  final List<ChatMessage> _messages = [];
  bool _thinking = false;
  bool _speaking = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get thinking => _thinking;
  bool get speaking => _speaking;

  /// Speaks the opener. Call once when the screen appears.
  Future<void> start() async {
    await _tts.speak(seed.opener);
  }

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _thinking) return;

    _messages.add(ChatMessage(fromJarvis: false, text: trimmed));
    _thinking = true;
    notifyListeners();

    final reply = await _llm.converse(seed: seed, history: _messages);

    _messages.add(ChatMessage(fromJarvis: true, text: reply));
    _thinking = false;
    notifyListeners();

    await _tts.speak(reply);
  }

  Future<void> silence() => _tts.stop();

  @override
  void dispose() {
    _tts.stop();
    _llm.dispose();
    super.dispose();
  }
}

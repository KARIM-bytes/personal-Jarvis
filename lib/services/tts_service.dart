import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper around Android's built-in TextToSpeech, with speaking-state
/// callbacks so the UI can animate while Jarvis talks.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  void Function()? onStart;
  void Function()? onComplete;

  Future<void> init() async {
    if (_ready) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() => onStart?.call());
    _tts.setCompletionHandler(() => onComplete?.call());
    _tts.setCancelHandler(() => onComplete?.call());
    _ready = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}

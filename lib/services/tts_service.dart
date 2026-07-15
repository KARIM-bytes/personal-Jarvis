import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper around Android TextToSpeech. Prefers the Google TTS engine and a
/// higher-quality network voice when available, with speaking-state callbacks
/// so the UI can animate while Jarvis talks.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  void Function()? onStart;
  void Function()? onComplete;

  Future<void> init() async {
    if (_ready) return;
    // Prefer Google's engine (nicer voices than the stock one).
    try {
      await _tts.setEngine('com.google.android.tts');
    } catch (_) {
      // Keep the device default if Google TTS isn't installed.
    }
    await _tts.setLanguage('en-US');
    await _pickBestVoice();
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.02);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() => onStart?.call());
    _tts.setCompletionHandler(() => onComplete?.call());
    _tts.setCancelHandler(() => onComplete?.call());
    _ready = true;
  }

  /// Picks a natural-sounding English voice, favouring Google's network voices.
  Future<void> _pickBestVoice() async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final en = voices
          .whereType<Map>()
          .where((v) =>
              (v['locale']?.toString().toLowerCase().startsWith('en') ?? false))
          .toList();
      if (en.isEmpty) return;

      Map? pick;
      for (final v in en) {
        final name = v['name']?.toString().toLowerCase() ?? '';
        // Google's higher-quality voices are tagged like "en-us-x-...-network".
        if (name.contains('-network') || name.contains('network')) {
          pick = v;
          break;
        }
      }
      pick ??= en.first;
      await _tts.setVoice({
        'name': pick['name'].toString(),
        'locale': pick['locale'].toString(),
      });
    } catch (_) {
      // Fall back to the default voice for the language.
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}

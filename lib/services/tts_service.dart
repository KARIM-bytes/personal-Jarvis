import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// One selectable TTS voice.
class VoiceOption {
  const VoiceOption({required this.name, required this.locale});

  final String name;
  final String locale;

  /// Google's higher-quality voices are tagged "network" (need internet).
  bool get isNetwork => name.toLowerCase().contains('network');

  /// Human-friendly label: "en-us-x-tpf-network" → "TPF · en-US · HD".
  String get label {
    var core = name.toLowerCase();
    core = core.replaceAll(RegExp(r'-?network$'), '');
    core = core.replaceAll(RegExp(r'-?local$'), '');
    final prefix = locale.toLowerCase().replaceAll('_', '-');
    if (core.startsWith('$prefix-x-')) {
      core = core.substring(prefix.length + 3);
    } else if (core.startsWith(prefix)) {
      core = core.substring(prefix.length);
    }
    core = core.replaceAll(RegExp(r'^[-#_]+|[-#_]+$'), '');
    final tag = core.isEmpty ? name : core.toUpperCase();
    return '$tag · $locale${isNetwork ? ' · HD' : ''}';
  }
}

/// The user's saved speech settings.
class VoiceSettings {
  const VoiceSettings({this.voiceName, required this.rate, required this.pitch});

  final String? voiceName;
  final double rate;
  final double pitch;
}

/// Wrapper around Android TextToSpeech. Prefers the Google TTS engine, honours
/// the voice/speed/pitch the user picked in Settings (re-read before every
/// utterance so changes apply everywhere, including the background isolate),
/// and exposes engine/voice discovery for the picker UI.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  void Function()? onStart;
  void Function()? onComplete;

  Future<void> init() async {
    if (_ready) return;
    // Prefer Google's engine (nicer voices than most stock ones).
    try {
      await _tts.setEngine(AppConfig.googleTtsEngine);
    } catch (_) {
      // Keep the device default if Google TTS isn't installed.
    }
    await _tts.setLanguage('en-US');
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() => onStart?.call());
    _tts.setCompletionHandler(() => onComplete?.call());
    _tts.setCancelHandler(() => onComplete?.call());
    _ready = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await init();
    await _applyPreferences();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  /// Re-reads the saved voice/rate/pitch before speaking. Prefs are cached per
  /// isolate, so reload() ensures the background service hears a voice change
  /// made in Settings without a restart.
  Future<void> _applyPreferences() async {
    String? name;
    String? locale;
    var rate = AppConfig.defaultTtsRate;
    var pitch = AppConfig.defaultTtsPitch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      name = prefs.getString(AppConfig.prefsTtsVoiceName);
      locale = prefs.getString(AppConfig.prefsTtsVoiceLocale);
      rate = prefs.getDouble(AppConfig.prefsTtsRate) ?? rate;
      pitch = prefs.getDouble(AppConfig.prefsTtsPitch) ?? pitch;
    } catch (_) {
      // Fall through to defaults.
    }

    if (name != null && locale != null) {
      try {
        await _tts.setVoice({'name': name, 'locale': locale});
      } catch (_) {
        await _pickBestVoice();
      }
    } else {
      await _pickBestVoice();
    }
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
  }

  /// Auto-pick fallback when the user hasn't chosen: favour a Google network
  /// (higher-quality) English voice.
  Future<void> _pickBestVoice() async {
    try {
      final voices = await englishVoices();
      if (voices.isEmpty) return;
      final pick =
          voices.firstWhere((v) => v.isNetwork, orElse: () => voices.first);
      await _tts.setVoice({'name': pick.name, 'locale': pick.locale});
    } catch (_) {
      // Keep the engine's default voice.
    }
  }

  // --- Discovery (for the Settings picker) ----------------------------------

  /// Whether the Google TTS engine is actually installed on this device.
  Future<bool> isGoogleEngineAvailable() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List) {
        return engines.any((e) => e.toString() == AppConfig.googleTtsEngine);
      }
    } catch (_) {
      // Treat errors as "not available".
    }
    return false;
  }

  /// English voices offered by the current engine, HD/network voices first.
  Future<List<VoiceOption>> englishVoices() async {
    await init();
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return [];
      final seen = <String>{};
      final voices = <VoiceOption>[];
      for (final v in raw) {
        if (v is! Map) continue;
        final name = v['name']?.toString() ?? '';
        final locale = v['locale']?.toString() ?? '';
        if (name.isEmpty || !locale.toLowerCase().startsWith('en')) continue;
        if (seen.add(name)) {
          voices.add(VoiceOption(name: name, locale: locale));
        }
      }
      voices.sort((a, b) {
        if (a.isNetwork != b.isNetwork) return a.isNetwork ? -1 : 1;
        return a.label.compareTo(b.label);
      });
      return voices;
    } catch (_) {
      return [];
    }
  }

  /// Speaks the sample line with [voice] at the given settings, without saving.
  Future<void> preview(VoiceOption voice,
      {required double rate, required double pitch}) async {
    await init();
    try {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    } catch (_) {
      // Voice may have vanished; speak with whatever is active.
    }
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.stop();
    await _tts.speak(AppConfig.ttsSampleLine);
  }

  // --- Persistence ----------------------------------------------------------

  static Future<VoiceSettings> loadVoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return VoiceSettings(
      voiceName: prefs.getString(AppConfig.prefsTtsVoiceName),
      rate: prefs.getDouble(AppConfig.prefsTtsRate) ?? AppConfig.defaultTtsRate,
      pitch:
          prefs.getDouble(AppConfig.prefsTtsPitch) ?? AppConfig.defaultTtsPitch,
    );
  }

  /// Persists the chosen voice + speech settings. A null [voice] returns to
  /// automatic voice selection.
  static Future<void> saveVoiceSettings({
    VoiceOption? voice,
    required double rate,
    required double pitch,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (voice == null) {
      await prefs.remove(AppConfig.prefsTtsVoiceName);
      await prefs.remove(AppConfig.prefsTtsVoiceLocale);
    } else {
      await prefs.setString(AppConfig.prefsTtsVoiceName, voice.name);
      await prefs.setString(AppConfig.prefsTtsVoiceLocale, voice.locale);
    }
    await prefs.setDouble(AppConfig.prefsTtsRate, rate);
    await prefs.setDouble(AppConfig.prefsTtsPitch, pitch);
  }
}

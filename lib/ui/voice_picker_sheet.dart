import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// Pick Jarvis's voice: checks whether Google TTS is installed, lists its
/// English voices (HD first), previews each on tap, and saves the choice plus
/// speed/pitch so every Jarvis line — including the background pop-up — uses it.
class VoicePickerSheet extends StatefulWidget {
  const VoicePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const VoicePickerSheet(),
    );
  }

  @override
  State<VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends State<VoicePickerSheet> {
  final TtsService _tts = TtsService();

  bool _loading = true;
  bool _googleAvailable = false;
  List<VoiceOption> _voices = [];
  VoiceOption? _selected;
  double _rate = AppConfig.defaultTtsRate;
  double _pitch = AppConfig.defaultTtsPitch;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final google = await _tts.isGoogleEngineAvailable();
    final voices = await _tts.englishVoices();
    final saved = await TtsService.loadVoiceSettings();
    VoiceOption? selected;
    if (saved.voiceName != null) {
      for (final v in voices) {
        if (v.name == saved.voiceName) {
          selected = v;
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _googleAvailable = google;
      _voices = voices;
      _selected = selected;
      _rate = saved.rate;
      _pitch = saved.pitch;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _tapVoice(VoiceOption voice) async {
    setState(() => _selected = voice);
    await _tts.preview(voice, rate: _rate, pitch: _pitch);
  }

  Future<void> _save() async {
    await TtsService.saveVoiceSettings(
        voice: _selected, rate: _rate, pitch: _pitch);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                children: [
                  Text("Jarvis's voice",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap a voice to hear it. HD voices need internet.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  _engineStatus(),
                  const SizedBox(height: 14),
                  _slider(
                    label: 'Speed',
                    value: _rate,
                    min: 0.2,
                    max: 0.8,
                    onChanged: (v) => setState(() => _rate = v),
                  ),
                  _slider(
                    label: 'Pitch',
                    value: _pitch,
                    min: 0.7,
                    max: 1.4,
                    onChanged: (v) => setState(() => _pitch = v),
                  ),
                  const SizedBox(height: 8),
                  if (_voices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No voices reported by the speech engine. Check '
                        'Settings → Accessibility → Text-to-speech on the phone.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    for (final voice in _voices) _voiceTile(voice),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() => _selected = null);
                        _save();
                      },
                      child: const Text('Auto (recommended)'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Save voice'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _engineStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            _googleAvailable ? Icons.check_circle : Icons.error_outline,
            color: _googleAvailable ? AppTheme.ringExercise : AppTheme.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _googleAvailable
                  ? 'Google Text-to-Speech is installed — its voices are listed below.'
                  : 'Google Text-to-Speech not found. Using the device\'s default '
                      'engine; install "Speech Recognition & Synthesis" from the '
                      'Play Store for better voices.',
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
            width: 48,
            child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppTheme.accent,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _voiceTile(VoiceOption voice) {
    final selected = _selected?.name == voice.name;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppTheme.accent : Colors.white38,
      ),
      title: Text(voice.label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      trailing: const Icon(Icons.volume_up_outlined,
          color: Colors.white38, size: 20),
      onTap: () => _tapVoice(voice),
    );
  }
}

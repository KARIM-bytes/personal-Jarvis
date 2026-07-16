import 'package:flutter_test/flutter_test.dart';
import 'package:personal_jarvis/services/tts_service.dart';

void main() {
  test('network voices are flagged HD and prettified', () {
    const v = VoiceOption(name: 'en-us-x-tpf-network', locale: 'en-US');
    expect(v.isNetwork, isTrue);
    expect(v.label, 'TPF · en-US · HD');
  });

  test('local voices drop the -local suffix and get no HD tag', () {
    const v = VoiceOption(name: 'en-us-x-iom-local', locale: 'en-US');
    expect(v.isNetwork, isFalse);
    expect(v.label, 'IOM · en-US');
  });

  test('names without the locale prefix fall back to the raw core', () {
    const v = VoiceOption(name: 'english-rp', locale: 'en-GB');
    expect(v.isNetwork, isFalse);
    expect(v.label, 'ENGLISH-RP · en-GB');
  });

  test('a name that is only the locale keeps the original name as label', () {
    const v = VoiceOption(name: 'en-us', locale: 'en-US');
    expect(v.label, 'en-us · en-US');
  });
}

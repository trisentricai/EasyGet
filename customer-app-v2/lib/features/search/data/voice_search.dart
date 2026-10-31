import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voice-to-text for the search field (faked in tests — the plugin never
/// runs under flutter_test, and the Android RECORD_AUDIO runtime grant is
/// requested on first use).
abstract class VoiceSearchService {
  /// Plugin init + mic grant. False means "don't even try listening".
  Future<bool> ensurePermission();

  /// Starts listening; interim and final transcripts stream back. Final
  /// results submit the search.
  Future<void> listen({
    required void Function(String text, bool finalResult) onResult,
  });

  Future<void> stop();
}

class SpeechVoiceSearchService implements VoiceSearchService {
  SpeechVoiceSearchService(this._speech);

  final SpeechToText _speech;

  @override
  Future<bool> ensurePermission() async {
    try {
      final available = await _speech.initialize();
      if (!available) return false;
      return await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> listen({
    required void Function(String text, bool finalResult) onResult,
  }) async {
    try {
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: 'en_IN',
          partialResults: true,
          listenFor: const Duration(seconds: 30),
        ),
        onResult: (result) =>
            onResult(result.recognizedWords, result.finalResult),
      );
    } catch (_) {
      // Treated as silence by the caller.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }
}

final voiceSearchProvider = Provider<VoiceSearchService>((_) {
  return SpeechVoiceSearchService(SpeechToText());
});
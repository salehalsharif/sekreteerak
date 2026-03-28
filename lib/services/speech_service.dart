import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-Text service for on-device or cloud transcription
class SpeechService {
  static SpeechService? _instance;
  static SpeechService get instance => _instance ??= SpeechService._();
  SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Initialize the speech recognition engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
      },
      onError: (error) {
        _isListening = false;
      },
    );

    return _isInitialized;
  }

  /// Get available locales (looking for Arabic)
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return _speech.locales();
  }

  /// Start listening for speech
  /// Returns transcribed text via the [onResult] callback
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    String localeId = 'ar_SA',
  }) async {
    if (!_isInitialized) {
      final ready = await initialize();
      if (!ready) {
        throw Exception('تعذر تهيئة خدمة التعرف على الصوت');
      }
    }

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        onResult(
          result.recognizedWords,
          result.finalResult,
        );
      },
      localeId: localeId,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    _isListening = false;
    await _speech.cancel();
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized;
}

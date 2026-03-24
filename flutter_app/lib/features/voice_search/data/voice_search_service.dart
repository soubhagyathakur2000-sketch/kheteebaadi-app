import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';

class VoiceSearchService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) print('Speech to text error: $error');
        },
        onStatus: (status) {
          if (kDebugMode) print('Speech to text status: $status');
        },
      );

      if (available) {
        _isInitialized = true;
      }
    } catch (e) {
      if (kDebugMode) print('Failed to initialize speech to text: $e');
      _isInitialized = false;
    }
  }

  void startListening({
    required Function(String) onResult,
    required Function(String) onPartial,
    String? locale,
  }) {
    if (!_isInitialized) {
      throw Exception('VoiceSearchService not initialized');
    }

    final selectedLocale = locale ?? AppConstants.defaultSpeechLocale;

    try {
      _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else {
            onPartial(result.recognizedWords);
          }
        },
        localeId: selectedLocale,
        listenMode: stt.ListenMode.search,
        cancelOnError: true,
        partialResults: true,
        onSoundLevelChange: (level) {
          // Sound level changes can be used for UI feedback
        },
      );
    } catch (e) {
      if (kDebugMode) print('Error starting listening: $e');
      throw Exception('Failed to start voice search: $e');
    }
  }

  void stopListening() {
    if (_isInitialized && _speechToText.isListening) {
      _speechToText.stop();
    }
  }

  bool get isAvailable => _isInitialized;

  bool get isListening => _speechToText.isListening;

  Future<void> dispose() async {
    if (_isInitialized) {
      await _speechToText.stop();
      _isInitialized = false;
    }
  }
}

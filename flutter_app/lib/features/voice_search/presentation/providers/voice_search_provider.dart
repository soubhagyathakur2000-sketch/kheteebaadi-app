import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/features/voice_search/data/voice_search_service.dart';

final voiceSearchServiceProvider =
    Provider<VoiceSearchService>((ref) {
  final service = VoiceSearchService();
  service.initialize();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class VoiceSearchState {
  final bool isListening;
  final String partialText;
  final String finalText;
  final String? error;
  final String selectedLocale;

  VoiceSearchState({
    this.isListening = false,
    this.partialText = '',
    this.finalText = '',
    this.error,
    this.selectedLocale = 'hi_IN',
  });

  VoiceSearchState copyWith({
    bool? isListening,
    String? partialText,
    String? finalText,
    String? error,
    String? selectedLocale,
  }) {
    return VoiceSearchState(
      isListening: isListening ?? this.isListening,
      partialText: partialText ?? this.partialText,
      finalText: finalText ?? this.finalText,
      error: error ?? this.error,
      selectedLocale: selectedLocale ?? this.selectedLocale,
    );
  }
}

class VoiceSearchNotifier extends StateNotifier<VoiceSearchState> {
  final VoiceSearchService _voiceSearchService;

  VoiceSearchNotifier(this._voiceSearchService)
      : super(const VoiceSearchState());

  Future<void> startSearch() async {
    if (!_voiceSearchService.isAvailable) {
      state = state.copyWith(
        error: 'Voice search not available on this device',
      );
      return;
    }

    state = state.copyWith(isListening: true, error: null, partialText: '');

    try {
      _voiceSearchService.startListening(
        onResult: (finalText) {
          state = state.copyWith(
            isListening: false,
            finalText: finalText,
            partialText: '',
          );
        },
        onPartial: (partialText) {
          state = state.copyWith(partialText: partialText);
        },
        locale: state.selectedLocale,
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
      );
    }
  }

  void stopSearch() {
    _voiceSearchService.stopListening();
    state = state.copyWith(isListening: false);
  }

  void clearResults() {
    state = state.copyWith(
      finalText: '',
      partialText: '',
      error: null,
    );
  }

  void setLocale(String locale) {
    state = state.copyWith(selectedLocale: locale);
  }
}

final voiceSearchStateProvider =
    StateNotifierProvider<VoiceSearchNotifier, VoiceSearchState>((ref) {
  final voiceSearchService = ref.watch(voiceSearchServiceProvider);
  return VoiceSearchNotifier(voiceSearchService);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/theme/app_theme.dart';
import 'package:kheteebaadi/features/voice_search/presentation/providers/voice_search_provider.dart';

class VoiceSearchBar extends ConsumerStatefulWidget {
  final Function(String) onSearch;
  final String hintText;

  const VoiceSearchBar({
    Key? key,
    required this.onSearch,
    this.hintText = 'Search crops, prices...',
  }) : super(key: key);

  @override
  ConsumerState<VoiceSearchBar> createState() => _VoiceSearchBarState();
}

class _VoiceSearchBarState extends ConsumerState<VoiceSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceSearchState = ref.watch(voiceSearchStateProvider);
    final voiceSearchNotifier = ref.read(voiceSearchStateProvider.notifier);

    // Update text from voice search
    if (voiceSearchState.finalText.isNotEmpty &&
        _textController.text != voiceSearchState.finalText) {
      _textController.text = voiceSearchState.finalText;
      widget.onSearch(voiceSearchState.finalText);
      voiceSearchNotifier.clearResults();
    }

    // Animate pulse when listening
    if (voiceSearchState.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!voiceSearchState.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Main search bar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            widget.onSearch(value);
                          }
                        },
                      ),
                    ),
                    // Animated microphone button
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (voiceSearchState.isListening) {
                            voiceSearchNotifier.stopSearch();
                          } else {
                            voiceSearchNotifier.startSearch();
                          }
                        },
                        child: ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.2).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.elasticInOut,
                            ),
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: voiceSearchState.isListening
                                  ? AppTheme.errorRed
                                  : AppTheme.primaryGreen,
                            ),
                            child: Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Language selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLanguageChip('hi', 'हिन्दी', voiceSearchState,
                        voiceSearchNotifier),
                    const SizedBox(width: 8),
                    _buildLanguageChip('en', 'English', voiceSearchState,
                        voiceSearchNotifier),
                    const SizedBox(width: 8),
                    _buildLanguageChip('mr', 'मराठी', voiceSearchState,
                        voiceSearchNotifier),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Partial text display
        if (voiceSearchState.partialText.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              voiceSearchState.partialText,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        // Error display
        if (voiceSearchState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.errorRed.withOpacity(0.1),
            child: Text(
              voiceSearchState.error!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.errorRed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLanguageChip(
    String code,
    String label,
    VoiceSearchState state,
    VoiceSearchNotifier notifier,
  ) {
    final localeMap = {'hi': 'hi_IN', 'en': 'en_IN', 'mr': 'mr_IN'};
    final locale = localeMap[code]!;
    final isSelected = state.selectedLocale == locale;

    return GestureDetector(
      onTap: () => notifier.setLocale(locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

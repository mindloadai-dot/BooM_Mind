import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mindload/services/token_estimation_service.dart';
import 'package:mindload/core/youtube_utils.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/services/youtube_service.dart';
import 'package:mindload/widgets/token_estimation_display.dart';
import 'package:mindload/widgets/youtube_preview_card.dart';
import 'package:mindload/widgets/scifi_loading_bar.dart';

import 'package:mindload/theme.dart';

/// Enhanced Upload Panel
/// Supports text input and YouTube links with token estimation and long-press confirmation
class EnhancedUploadPanel extends StatefulWidget {
  final Function(String text, String depth) onTextSubmit;
  final Function(String videoId, String depth) onYouTubeSubmit;
  final int availableTokens;
  final VoidCallback? onInsufficientTokens;

  const EnhancedUploadPanel({
    super.key,
    required this.onTextSubmit,
    required this.onYouTubeSubmit,
    required this.availableTokens,
    this.onInsufficientTokens,
  });

  @override
  State<EnhancedUploadPanel> createState() => _EnhancedUploadPanelState();
}

class _EnhancedUploadPanelState extends State<EnhancedUploadPanel> {
  final TextEditingController _textController = TextEditingController();
  String _inputType = 'text'; // 'text' or 'youtube'
  String _selectedDepth = 'standard';
  bool _isProcessing = false;
  String? _errorMessage;

  // YouTube integration state
  String? _currentVideoId;
  YouTubePreview? _currentPreview;
  bool _isLoadingPreview = false;

  final List<String> _depths = ['quick', 'standard', 'deep'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Detect if input is a YouTube link
  bool _isYouTubeLink(String input) {
    return YouTubeUtils.extractYouTubeId(input) != null;
  }

  /// Extract YouTube video ID
  String? _extractYouTubeId(String input) {
    return YouTubeUtils.extractYouTubeId(input);
  }

  /// Fetch YouTube preview
  Future<void> _fetchYouTubePreview(String videoId) async {
    if (_currentVideoId == videoId) return;

    setState(() {
      _currentVideoId = videoId;
      _isLoadingPreview = true;
      _errorMessage = null;
    });

    try {
      final preview = await YouTubeService().getPreview(videoId);
      if (mounted && _currentVideoId == videoId) {
        setState(() {
          _currentPreview = preview;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted && _currentVideoId == videoId) {
        setState(() {
          _errorMessage = 'Failed to load video preview: ${e.toString()}';
          _isLoadingPreview = false;
        });
      }
    }
  }

  /// Perform basic validation
  Future<void> _performValidation() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (_isYouTubeLink(_textController.text)) {
        final videoId = _extractYouTubeId(_textController.text);
        if (videoId == null) {
          setState(() {
            _errorMessage = 'Invalid YouTube link';
            _isProcessing = false;
          });
          return;
        }

        // Fetch actual preview data
        if (_currentPreview == null) {
          await _fetchYouTubePreview(videoId);
          if (_currentPreview == null) {
            setState(() {
              _errorMessage = 'Failed to load video information';
              _isProcessing = false;
            });
            return;
          }
        }
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate input: $e';
        _isProcessing = false;
      });
    }
  }

  /// Handle input change
  void _onInputChanged(String value) {
    final newType = _isYouTubeLink(value) ? 'youtube' : 'text';
    if (newType != _inputType) {
      setState(() {
        _inputType = newType;
      });
    }

    // Auto-perform validation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _textController.text == value) {
        _performValidation();
      }
    });
  }

  /// Handle depth change
  void _onDepthChanged(String? depth) {
    if (depth != null && depth != _selectedDepth) {
      setState(() {
        _selectedDepth = depth;
      });
      _performValidation();
    }
  }

  /// Check if input is valid
  bool _isValid() {
    return _textController.text.trim().isNotEmpty && _errorMessage == null;
  }

  /// Handle submission
  void _handleSubmit() {
    if (!_isValid()) return;

    if (_inputType == 'youtube') {
      widget.onYouTubeSubmit(_currentVideoId!, _selectedDepth);
    } else {
      widget.onTextSubmit(_textController.text, _selectedDepth);
    }
  }

  /// Show insufficient tokens dialog
  void _showInsufficientTokensDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Tokens'),
        content: Text(
          'You need more tokens for this operation, '
          'but you only have ${widget.availableTokens} tokens available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onInsufficientTokens?.call();
            },
            child: const Text('Get More Tokens'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _inputType == 'youtube'
                    ? Icons.play_circle_outline
                    : Icons.edit_note,
                size: 24,
                color: tokens.primary,
              ),
              const SizedBox(width: 12),
              Text(
                _inputType == 'youtube' ? 'YouTube Video' : 'Text Input',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Input field
          TextField(
            controller: _textController,
            maxLines: 4,
            onChanged: _onInputChanged,
            style: TextStyle(color: tokens.textPrimary),
            decoration: InputDecoration(
              hintText: _inputType == 'youtube'
                  ? 'Paste YouTube URL here...'
                  : 'Enter or paste your text here...',
              hintStyle: TextStyle(color: tokens.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderDefault),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Depth selection
          Row(
            children: [
              Text(
                'Analysis Depth:',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepth,
                  onChanged: _onDepthChanged,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tokens.borderDefault),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _depths.map((depth) {
                    return DropdownMenuItem(
                      value: depth,
                      child: Text(
                        depth.toUpperCase(),
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // YouTube preview card (when YouTube link is detected)
          if (_inputType == 'youtube') ...[
            if (_isLoadingPreview) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: tokens.borderDefault.withValues(alpha: 0.3)),
                ),
                child: AIProcessingLoadingBar(
                  progress: 0.5, // Default progress for loading
                  statusText: 'Loading video preview...',
                  primaryColor: tokens.primary,
                  height: 10.0,
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_currentPreview != null) ...[
              YouTubePreviewCard(
                preview: _currentPreview!,
                onIngest: () => _handleSubmit(),
                isLoading: _isProcessing,
                errorMessage: _errorMessage,
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Token estimation display
          if (_isValid() &&
              _inputType == 'youtube' &&
              _currentPreview != null) ...[
            _buildTokenEstimationDisplay(),
            const SizedBox(height: 16),
          ],

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: tokens.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: tokens.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isValid() ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: AIProcessingLoadingBar(
                            progress: 0.5, // Default progress for processing
                            statusText: 'Processing...',
                            primaryColor: tokens.onPrimary,
                            height: 6.0,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _inputType == 'youtube'
                              ? Icons.play_arrow
                              : Icons.send,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _inputType == 'youtube'
                              ? 'Process YouTube'
                              : 'Process Text',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenEstimationDisplay() {
    if (_inputType == 'youtube' && _currentPreview != null) {
      // YouTube token estimation
      final estimation = TokenEstimationService.instance.estimateYouTubeContent(
        videoId: _currentVideoId!,
        durationSeconds: _currentPreview!.durationSeconds,
        hasCaptions: _currentPreview!.captionsAvailable,
        depth: _selectedDepth,
      );

      return TokenEstimationDisplay(
        estimation: estimation,
        showProceedButton: false,
      );
    } else {
      // Text token estimation
      final estimation = TokenEstimationService.instance.estimateTextContent(
        text: _textController.text,
        depth: _selectedDepth,
      );

      return TokenEstimationDisplay(
        estimation: estimation,
        showProceedButton: false,
      );
    }
  }
}

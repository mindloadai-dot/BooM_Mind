import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:mindload/core/youtube_utils.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/services/youtube_service.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/credits_state_banners.dart';
import 'package:mindload/widgets/youtube_preview_card.dart';
import 'package:mindload/widgets/accessible_components.dart';

/// Enhanced Text Upload Screen
/// Supports both text input and YouTube links with debounced detection
class EnhancedTextUploadScreen extends StatefulWidget {
  final Function(String text) onTextSubmit;
  final Function(String materialId) onYouTubeIngestComplete;

  const EnhancedTextUploadScreen({
    super.key,
    required this.onTextSubmit,
    required this.onYouTubeIngestComplete,
  });

  @override
  State<EnhancedTextUploadScreen> createState() =>
      _EnhancedTextUploadScreenState();
}

class _EnhancedTextUploadScreenState extends State<EnhancedTextUploadScreen> {
  final TextEditingController _textController = TextEditingController();
  final YouTubeService _youtubeService = YouTubeService();

  String? _currentVideoId;
  YouTubePreview? _currentPreview;
  bool _isLoadingPreview = false;
  bool _isIngesting = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  // Debounce duration for YouTube link detection
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear previous preview if input changed
    if (_currentPreview != null) {
      setState(() {
        _currentPreview = null;
        _currentVideoId = null;
        _errorMessage = null;
      });
    }

    // Set new timer for debounced detection
    _debounceTimer = Timer(_debounceDuration, () {
      _detectAndHandleInput();
    });
  }

  void _detectAndHandleInput() {
    final input = _textController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _currentPreview = null;
        _currentVideoId = null;
        _errorMessage = null;
      });
      return;
    }

    // Check if input is a YouTube link
    final videoId = YouTubeUtils.extractYouTubeId(input);

    if (videoId != null && videoId != _currentVideoId) {
      _currentVideoId = videoId;
      _fetchYouTubePreview(videoId);
    } else if (videoId == null) {
      // Not a YouTube link, clear preview
      setState(() {
        _currentPreview = null;
        _currentVideoId = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _fetchYouTubePreview(String videoId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
    });

    try {
      final preview = await _youtubeService.getPreview(videoId);

      if (mounted) {
        setState(() {
          _currentPreview = preview;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingPreview = false;
        });
      }
    }
  }

  Future<void> _handleYouTubeIngest() async {
    if (_currentPreview == null || _isIngesting) return;

    setState(() {
      _isIngesting = true;
      _errorMessage = null;
    });

    try {
      final request = YouTubeIngestRequest(
        videoId: _currentPreview!.videoId,
        preferredLanguage: _currentPreview!.primaryLang,
      );

      final response = await _youtubeService.ingestTranscript(request);

      if (mounted) {
        if (response.isSuccess) {
          // Navigate to existing material if already exists
          if (response.isAlreadyExists) {
            widget.onYouTubeIngestComplete(response.materialId);
          } else {
            // Show success message and navigate
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('YouTube transcript ingested successfully!'),
                backgroundColor: context.tokens.success,
              ),
            );
            widget.onYouTubeIngestComplete(response.materialId);
          }
        } else {
          setState(() {
            _errorMessage = response.error ?? 'Ingest failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isIngesting = false;
        });
      }
    }
  }

  void _handleTextSubmit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onTextSubmit(text);
    }
  }

  void _clearInput() {
    _textController.clear();
    setState(() {
      _currentPreview = null;
      _currentVideoId = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final economy = context.read<MindloadEconomyService>();
    final availableTokens = economy.userEconomy?.creditsRemaining ?? 0;

    return Scaffold(
      appBar: MindloadAppBarFactory.standard(
        title: 'Upload Study Material',
        onBuyCredits: () {
          // Handle buy credits
        },
        onViewLedger: () {
          // Handle view ledger
        },
        onUpgrade: () {
          // Handle upgrade
        },
      ),
      body: Column(
        children: [
          // ML Tokens state banners - constrained to prevent overflow
          Flexible(
            child: const CreditsStateBanners(),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input section
                  _buildInputSection(tokens),

                  const SizedBox(height: 16),

                  // YouTube preview section
                  if (_isLoadingPreview) _buildLoadingPreview(tokens),
                  if (_currentPreview != null) _buildPreviewSection(tokens),
                  if (_errorMessage != null) _buildErrorSection(tokens),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(tokens, availableTokens),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Material',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),

        const SizedBox(height: 8),

        Text(
          'Paste study text or a YouTube link (youtube.com / youtu.be)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: _textController,
          maxLines: 8,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
              ),
          decoration: InputDecoration(
            hintText:
                'Paste your study material here...\n\n• Lecture notes\n• Textbook chapters\n• Articles\n• Course materials\n• YouTube video links',
            hintStyle: TextStyle(
              color: tokens.textTertiary,
              height: 1.5,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: tokens.borderDefault,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: tokens.borderDefault,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: tokens.borderFocus,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              _currentVideoId != null ? Icons.play_circle : Icons.text_fields,
              color: tokens.primary,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Character counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_textController.text.length} characters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textTertiary,
                  ),
            ),
            if (_textController.text.isNotEmpty)
              TextButton(
                onPressed: _clearInput,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingPreview(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderDefault),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading YouTube preview...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(SemanticTokens tokens) {
    if (_currentPreview == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YouTube Video Preview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        YouTubePreviewCard(
          preview: _currentPreview!,
          onIngest: _handleYouTubeIngest,
          isLoading: _isIngesting,
        ),
      ],
    );
  }

  Widget _buildErrorSection(SemanticTokens tokens) {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tokens.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: context.tokens.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.tokens.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SemanticTokens tokens, int availableTokens) {
    final hasText = _textController.text.trim().isNotEmpty;
    final isYouTubeLink = _currentVideoId != null;
    final canSubmitText = hasText && !isYouTubeLink;
    final canSubmitYouTube =
        _currentPreview?.canProceed == true && !_isIngesting;

    return Column(
      children: [
        // Text submit button (only show for non-YouTube content)
        if (canSubmitText)
          AccessibleButton(
            onPressed: _handleTextSubmit,
            fullWidth: true,
            size: ButtonSize.large,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.text_fields, color: context.tokens.onPrimary),
                const SizedBox(width: 8),
                Text('Process Text'),
              ],
            ),
          ),

        // YouTube ingest button (only show for YouTube content)
        if (isYouTubeLink && canSubmitYouTube) const SizedBox(height: 12),

        // Info text for YouTube links
        if (isYouTubeLink && !canSubmitYouTube)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderDefault),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: tokens.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use the preview card above to ingest this YouTube video',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),

        // Token information
        if (hasText)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: tokens.borderDefault.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.token,
                  color: tokens.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available MindLoad Tokens: $availableTokens',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

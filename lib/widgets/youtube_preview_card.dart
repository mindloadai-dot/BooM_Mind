import 'package:mindload/widgets/scifi_loading_bar.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mindload/models/youtube_preview_models.dart';
import 'package:mindload/theme.dart';

/// YouTube preview card widget
/// Displays video information and handles long-press confirmation for ingest
class YouTubePreviewCard extends StatefulWidget {
  final YouTubePreview preview;
  final VoidCallback? onIngest;
  final bool isLoading;
  final String? errorMessage;

  const YouTubePreviewCard({
    super.key,
    required this.preview,
    this.onIngest,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<YouTubePreviewCard> createState() => _YouTubePreviewCardState();
}

class _YouTubePreviewCardState extends State<YouTubePreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLongPressing = false;
  bool _hasTriggeredLongPress = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    // Don't handle long press if onIngest is null (automatic processing)
    if (widget.onIngest == null) return;

    setState(() {
      _isLongPressing = true;
    });
    _animationController.forward();

    // Trigger long press after 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_isLongPressing && mounted) {
        setState(() {
          _hasTriggeredLongPress = true;
        });
        _animationController.reverse();

        if (widget.onIngest != null) {
          widget.onIngest!();
        }
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isLongPressing = false;
    });
    _animationController.reverse();
  }

  void _onLongPressCancel() {
    setState(() {
      _isLongPressing = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(tokens),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.borderDefault.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail and status
                _buildThumbnailSection(tokens),

                // Video information
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.preview.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Channel and duration
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: tokens.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.preview.channel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: tokens.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.preview.formattedDuration,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: tokens.textSecondary,
                                    ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Status pill
                      _buildStatusPill(tokens),

                      const SizedBox(height: 12),

                      // Token information
                      _buildTokenInfo(tokens),

                      const SizedBox(height: 16),

                      // Ingest button
                      _buildIngestButton(tokens),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnailSection(SemanticTokens tokens) {
    return Stack(
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: widget.preview.thumbnail,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 180,
              color: tokens.surfaceAlt,
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: tokens.textTertiary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 180,
              color: tokens.surfaceAlt,
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
        ),

        // Play button overlay
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.textSecondary.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                size: 32,
                color: tokens.textInverse,
              ),
            ),
          ),
        ),

        // Duration badge
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tokens.textSecondary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.preview.formattedDuration,
              style: TextStyle(
                color: tokens.textInverse,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill(SemanticTokens tokens) {
    final statusColor = _getStatusColor(tokens);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            widget.preview.statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenInfo(SemanticTokens tokens) {
    return Row(
      children: [
        Icon(
          Icons.token,
          size: 16,
          color: tokens.primary,
        ),
        const SizedBox(width: 4),
        Text(
          'Estimated: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
        Text(
          '${widget.preview.estimatedMindLoadTokens} MindLoad Tokens',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildIngestButton(SemanticTokens tokens) {
    // If onIngest is null, show automatic processing status instead of button
    if (widget.onIngest == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: tokens.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tokens.success.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: tokens.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Content automatically extracted',
                style: TextStyle(
                  color: tokens.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDisabled = !widget.preview.canProceed || widget.isLoading;

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onLongPressStart: (isDisabled || widget.onIngest == null) ? null : _onLongPressStart,
        onLongPressEnd: (isDisabled || widget.onIngest == null) ? null : _onLongPressEnd,
        onLongPressCancel: (isDisabled || widget.onIngest == null) ? null : _onLongPressCancel,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDisabled
                ? tokens.surfaceAlt
                : (_isLongPressing
                    ? tokens.primary.withValues(alpha: 0.8)
                    : tokens.primary),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDisabled ? tokens.borderDefault : tokens.primary,
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: AIProcessingLoadingBar(
                      statusText: '',
                      progress: 0.6,
                      height: 20,
                    ),
                  )
                : Text(
                    _getButtonText(),
                    style: TextStyle(
                      color:
                          isDisabled ? tokens.textTertiary : tokens.textInverse,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    // If onIngest is null, this method shouldn't be called, but provide fallback
    if (widget.onIngest == null) {
      return 'Content automatically extracted';
    }

    if (_isLongPressing) {
      return 'Release to confirm';
    }

    if (!widget.preview.canProceed) {
      if (!widget.preview.captionsAvailable) {
        return 'No transcript available';
      }
      if (widget.preview.blocked) {
        return widget.preview.blockReason ?? 'Cannot proceed';
      }
      return 'Cannot proceed';
    }

    return 'Hold to spend ${widget.preview.estimatedMindLoadTokens} MindLoad Tokens';
  }

  Color _getBorderColor(SemanticTokens tokens) {
    if (widget.preview.blocked) {
      return tokens.error.withValues(alpha: 0.5);
    }
    if (!widget.preview.captionsAvailable) {
      return tokens.warning.withValues(alpha: 0.5);
    }
    return tokens.borderDefault;
  }

  Color _getStatusColor(SemanticTokens tokens) {
    switch (widget.preview.statusColor) {
      case 'success':
        return tokens.success;
      case 'warning':
        return tokens.warning;
      case 'error':
        return tokens.error;
      default:
        return tokens.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.preview.statusColor) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}

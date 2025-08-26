import 'package:flutter/material.dart';
import 'package:mindload/services/ultra_audio_controller.dart';
import 'package:mindload/theme.dart';

/// Enhanced audio controls specifically designed for Ultra Mode
class UltraModeAudioControls extends StatefulWidget {
  final bool showTitle;
  final bool showProgress;
  final bool showVolumeSlider;
  final bool showCrossfadeToggle;
  final EdgeInsets? padding;
  final VoidCallback? onHeadphoneWarning;

  const UltraModeAudioControls({
    super.key,
    this.showTitle = true,
    this.showProgress = true,
    this.showVolumeSlider = true,
    this.showCrossfadeToggle = true,
    this.padding,
    this.onHeadphoneWarning,
  });

  @override
  State<UltraModeAudioControls> createState() => _UltraModeAudioControlsState();
}

class _UltraModeAudioControlsState extends State<UltraModeAudioControls>
    with TickerProviderStateMixin {
  late UltraAudioController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  bool _showHeadphoneWarning = true;
  bool _isVolumeExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = UltraAudioController.instance;
    
    // Setup pulse animation for play button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Listen for playing state changes
    _controller.playingStream.listen((isPlaying) {
      if (isPlaying) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
    
    // Listen for errors and show warnings
    _controller.errorStream.listen((error) {
      if (error.type == UltraAudioErrorType.routeChange) {
        _showHeadphoneDisconnectedWarning();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showHeadphoneDisconnectedWarning() {
    final tokens = ThemeManager.instance.currentTokens;
    if (widget.onHeadphoneWarning != null) {
      widget.onHeadphoneWarning!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.headset_off, color: ThemeManager.instance.currentTokens.warning),
              const SizedBox(width: 8),
              const Text('Headphones disconnected - audio paused'),
            ],
          ),
          backgroundColor: tokens.surface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeManager.instance.currentTokens.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeManager.instance.currentTokens.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Headphone recommendation (dismissible)
          if (_showHeadphoneWarning && !_controller.isPlaying) ...[
            _buildHeadphoneRecommendation(),
            const SizedBox(height: 16),
          ],
          
          // Track title and session info
          if (widget.showTitle) ...[
            _buildTrackInfo(),
            const SizedBox(height: 16),
          ],
          
          // Progress indicator with session countdown
          if (widget.showProgress) ...[
            _buildProgressSection(),
            const SizedBox(height: 16),
          ],
          
          // Main control buttons
          _buildMainControls(),
          
          // Volume and settings
          if (widget.showVolumeSlider || widget.showCrossfadeToggle) ...[
            const SizedBox(height: 16),
            _buildVolumeAndSettings(),
          ],
          
          // Session status
          _buildSessionStatus(),
        ],
      ),
    );
  }

  Widget _buildHeadphoneRecommendation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeManager.instance.currentTokens.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeManager.instance.currentTokens.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.headset, color: ThemeManager.instance.currentTokens.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Headphones recommended for optimal binaural beats experience',
              style: TextStyle(
                color: ThemeManager.instance.currentTokens.primary,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: ThemeManager.instance.currentTokens.primary,
            onPressed: () {
              setState(() {
                _showHeadphoneWarning = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo() {
    return StreamBuilder<UltraPlaybackState>(
      stream: _controller.processingStateStream,
      builder: (context, snapshot) {
        final preset = _controller.currentPreset;
        if (preset == null) {
          return Text(
            'No preset loaded',
            style: TextStyle(color: ThemeManager.instance.currentTokens.textTertiary ?? Colors.grey),
          );
        }
        
        // Handle dynamic preset object
        String name = 'Unknown';
        String description = '';
        
        // Check if preset has properties we can access
        try {
          if (preset is Map<String, dynamic>) {
            final presetMap = preset as Map<String, dynamic>;
            name = presetMap['name'] as String? ?? 'Unknown';
            description = presetMap['description'] as String? ?? '';
          } else {
            // Handle typed UltraPreset object - access properties directly
            name = preset.name;
            description = preset.description;
          }
        } catch (e) {
          name = 'Audio Preset';
          description = 'Binaural beats for focus';
        }
        
        return Column(
          children: [
            Text(
              name,
              style: TextStyle(
                color: ThemeManager.instance.currentTokens.textInverse,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_controller.isLooping) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeManager.instance.currentTokens.accent.withValues(alpha:  0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Repeat to fill session',
                  style: TextStyle(
                    color: ThemeManager.instance.currentTokens.accent,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return StreamBuilder<Duration>(
      stream: _controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _controller.duration;
        final sessionProgress = _controller.sessionProgress;
        final sessionRemaining = _controller.sessionRemaining;
        
        return Column(
          children: [
            // Track progress bar
            if (duration > Duration.zero) ...[
              Row(
                children: [
                  Text(
                    position.mmss,
                    style: TextStyle(
                      color: ThemeManager.instance.currentTokens.textTertiary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: position.inMilliseconds / duration.inMilliseconds,
                      backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha:  0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeManager.instance.currentTokens.accent.withValues(alpha:  0.6),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    duration.mmss,
                    style: TextStyle(
                      color: ThemeManager.instance.currentTokens.textTertiary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Session progress bar
            if (_controller.hasSession) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Session Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Remaining: ${sessionRemaining.mmss}',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: sessionProgress,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha:  0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                minHeight: 6,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Skip back
        IconButton(
          icon: const Icon(Icons.skip_previous),
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
          iconSize: 32,
          onPressed: _controller.hasSession 
            ? () => _controller.seek(Duration.zero)
            : null,
        ),
        
        // Main play/pause button with pulse animation
        StreamBuilder<bool>(
          stream: _controller.playingStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data ?? false;
            final isLoading = _controller.state == UltraPlaybackStateEnum.loading;
            
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isPlaying ? _pulseAnimation.value : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ThemeManager.instance.currentTokens.accent.withValues(alpha:  0.3),
                          ThemeManager.instance.currentTokens.accent.withValues(alpha:  0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isLoading 
                          ? Icons.hourglass_empty
                          : (isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      color: ThemeManager.instance.currentTokens.accent,
                      iconSize: 48,
                      onPressed: _controller.hasSession
                        ? (isLoading
                            ? null
                            : (isPlaying
                                ? _controller.pause
                                : _controller.play))
                        : null,
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // Stop
        IconButton(
          icon: const Icon(Icons.stop),
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
          iconSize: 32,
          onPressed: _controller.isPlaying ? _controller.stop : null,
        ),
      ],
    );
  }

  Widget _buildVolumeAndSettings() {
    return Column(
      children: [
        // Volume control
        if (widget.showVolumeSlider) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                _isVolumeExpanded = !_isVolumeExpanded;
              });
            },
            child: Row(
              children: [
                Icon(
                  _controller.volume == 0 
                    ? Icons.volume_off
                    : (_controller.volume < 0.5 
                        ? Icons.volume_down 
                        : Icons.volume_up),
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _isVolumeExpanded ? 40 : 20,
                    child: _isVolumeExpanded
                      ? Slider(
                          value: _controller.volume,
                          onChanged: _controller.setVolume,
                          activeColor: ThemeManager.instance.currentTokens.accent,
                          inactiveColor: Theme.of(context).colorScheme.outline,
                          thumbColor: ThemeManager.instance.currentTokens.accent,
                        )
                      : Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _controller.volume,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: ThemeManager.instance.currentTokens.accent,
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_controller.volume * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Crossfade toggle
        if (widget.showCrossfadeToggle) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.tune, color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Crossfade',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${_controller.crossfadeDuration.inMilliseconds}ms',
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSessionStatus() {
    return StreamBuilder<UltraPlaybackState>(
      stream: _controller.processingStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _controller.currentState;
        
        String statusText = 'Unknown state';
        Color statusColor = Colors.grey;
        
        if (_controller.state == UltraPlaybackStateEnum.idle) {
          statusText = _controller.hasSession ? 'Ready to play' : 'No session loaded';
          statusColor = Colors.grey;
        } else if (_controller.state == UltraPlaybackStateEnum.loading) {
          statusText = 'Loading audio...';
          statusColor = Colors.orange;
        } else if (_controller.state == UltraPlaybackStateEnum.buffering) {
          statusText = 'Buffering...';
          statusColor = Colors.yellow;
        } else if (_controller.state == UltraPlaybackStateEnum.playing) {
          statusText = 'Ultra Mode active';
          statusColor = ThemeManager.instance.currentTokens.accent;
        } else if (_controller.state == UltraPlaybackStateEnum.paused) {
          statusText = 'Paused';
          statusColor = Colors.orange;
        } else if (_controller.state == UltraPlaybackStateEnum.completed) {
          statusText = 'Session completed!';
          statusColor = Colors.green;
        } else if (_controller.state == UltraPlaybackStateEnum.error) {
          statusText = 'Audio error occurred';
          statusColor = Colors.red;
        }
        
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha:  0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha:  0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Duration extension for Ultra Mode audio controls
extension UltraControlsDurationFormatting on Duration {
  String get mmss {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
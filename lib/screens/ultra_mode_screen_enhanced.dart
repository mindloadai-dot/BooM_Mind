import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/services/credit_service.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/services/achievement_tracker_service.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/screens/study_screen.dart';
import 'package:mindload/screens/study_set_selection_screen.dart';
import 'package:mindload/services/ultra_audio_controller.dart';
import 'package:mindload/widgets/ultra_mode_audio_controls.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/ultra_mode_guide.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'package:mindload/theme.dart';

class UltraModeScreenEnhanced extends StatefulWidget {
  const UltraModeScreenEnhanced({super.key});

  @override
  State<UltraModeScreenEnhanced> createState() =>
      _UltraModeScreenEnhancedState();
}

class _UltraModeScreenEnhancedState extends State<UltraModeScreenEnhanced>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  final UltraAudioController _audioController = UltraAudioController.instance;
  final CreditService _creditService = CreditService.instance;

  bool _isSessionActive = false;
  bool _isPaused = false;
  List<StudySet> _recentStudySets = [];
  StudySet? _selectedStudySet;
  UltraPreset? _selectedPreset;
  Duration _sessionDuration = const Duration(minutes: 25);

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _loadRecentStudySets();
    _checkAndShowOnboarding();
    _setupAnimations();
    _setupAudioListeners();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioController.initialize();
    } catch (e) {
      debugPrint('Audio initialization failed: $e');
      _showErrorSnackBar('Audio system initialization failed');
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  void _setupAudioListeners() {
    // Listen for playback state changes
    _audioController.playingStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isSessionActive = isPlaying;
          _isPaused = !isPlaying && _audioController.hasSession;
        });

        if (isPlaying) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      }
    });

    // Listen for session completion
    _audioController.processingStateStream.listen((state) {
      if (mounted &&
          state.position >= state.sessionLength &&
          state.sessionLength > Duration.zero) {
        _onSessionCompleted();
      }
    });

    // Listen for audio errors
    _audioController.errorStream.listen((error) {
      if (mounted) {
        _handleAudioError(error);
      }
    });
  }

  void _onSessionCompleted() {
    setState(() {
      _isSessionActive = false;
      _isPaused = false;
    });

    // Show completion celebration
    _showSessionCompletionDialog();

    // Track achievement
    AchievementTrackerService.instance.trackUltraSessionCompletion(
      _sessionDuration.inMinutes,
    );

    // Update telemetry
    TelemetryService.instance.trackEvent(
      'ultra_session_completed',
      parameters: {
        'duration_minutes': _sessionDuration.inMinutes,
        'preset': _selectedPreset?.key ?? 'none',
        'with_study_set': _selectedStudySet != null,
      },
    );
  }

  void _handleAudioError(UltraAudioError error) {
    String message;
    switch (error.type) {
      case UltraAudioErrorType.fileMissing:
        message = 'Audio file not found. Please check your installation.';
        break;
      case UltraAudioErrorType.routeChange:
        message = 'Audio device disconnected. Session paused.';
        break;
      case UltraAudioErrorType.focusLoss:
        message = 'Audio focus lost. Session paused.';
        break;
      case UltraAudioErrorType.playbackFail:
        message = 'Playback failed. Please try again.';
        break;
      default:
        message = 'Audio error occurred: ${error.message}';
    }

    _showErrorSnackBar(message);
  }

  Future<void> _checkAndShowOnboarding() async {
    final shouldShow = await UltraModeOnboarding.shouldShow();
    if (shouldShow && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          UltraModeOnboarding.show(context);
        }
      });
    }
  }

  Future<void> _loadRecentStudySets() async {
    try {
      final studySets = await UnifiedStorageService.instance.getAllStudySets();
      setState(() {
        _recentStudySets =
            studySets.take(5).toList(); // studySets is already List<StudySet>
      });
    } catch (e) {
      debugPrint('Failed to load study sets: $e');
    }
  }

  void _showHelpGuide() {
    showDialog(
      context: context,
      builder: (context) => const UltraModeGuide(),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSessionCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.cyan, size: 28),
            const SizedBox(width: 12),
            Text(
              'Session Complete!',
              style: TextStyle(color: context.tokens.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You\'ve completed a ${_sessionDuration.inMinutes}-minute Ultra Mode session.',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            if (_selectedStudySet != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.quiz, color: Colors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ready to test your knowledge?',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Continue with ${_selectedStudySet!.title}',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_selectedStudySet != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startStudySession();
              },
              child:
                  const Text('Study Now', style: TextStyle(color: Colors.cyan)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close',
                style: TextStyle(color: context.tokens.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _startUltraSession() async {
    if (_selectedPreset == null) {
      _showErrorSnackBar('Please select an audio preset first');
      return;
    }

    try {
      // Load the preset with session duration
      await _audioController.load(_selectedPreset!, _sessionDuration);

      // Start playback
      await _audioController.play();

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Track session start
      TelemetryService.instance.trackEvent(
        'ultra_session_started',
        parameters: {
          'preset': _selectedPreset!.key,
          'duration_minutes': _sessionDuration.inMinutes,
          'with_study_set': _selectedStudySet != null,
        },
      );
    } catch (e) {
      _showErrorSnackBar('Failed to start session: $e');
    }
  }

  Future<void> _pauseResumeSession() async {
    try {
      if (_isSessionActive) {
        await _audioController.pause();
      } else if (_isPaused) {
        await _audioController.play();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pause/resume session: $e');
    }
  }

  Future<void> _stopSession() async {
    try {
      await _audioController.stop();
      setState(() {
        _isSessionActive = false;
        _isPaused = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to stop session: $e');
    }
  }

  void _startStudySession() {
    if (_selectedStudySet == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudySetSelectionScreen(
            onStudySetSelected: (StudySet studySet) {
              setState(() {
                _selectedStudySet = studySet;
              });
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudyScreen(
            studySet: _selectedStudySet!,
            isUltraMode: true,
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    // Ensure Ultra Mode audio fully stops when leaving this screen
    try {
      _audioController.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: MindloadAppBar(
        title: 'Ultra Mode',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpGuide,
            tooltip: 'Ultra Mode Guide',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Neural Wave Visualization
              _buildNeuralWaveVisualizer(tokens),

              const SizedBox(height: 24),

              // Preset Selection
              _buildPresetSelection(tokens),

              const SizedBox(height: 24),

              // Session Duration Selection
              _buildDurationSelection(tokens),

              const SizedBox(height: 24),

              // Study Set Selection
              _buildStudySetSelection(tokens),

              const SizedBox(height: 24),

              // Audio Controls
              if (_audioController.hasSession || _isSessionActive) ...[
                UltraModeAudioControls(
                  onHeadphoneWarning: () {
                    _showErrorSnackBar(
                        'Headphones disconnected - session paused');
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Main Action Button
              _buildMainActionButton(tokens),

              const SizedBox(height: 24),

              // Session Stats
              if (_isSessionActive || _isPaused) _buildSessionStats(tokens),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeuralWaveVisualizer(SemanticTokens tokens) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.elevatedSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSessionActive
              ? Colors.cyan.withValues(alpha: 0.5)
              : tokens.borderDefault,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated neural waves
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 200),
                painter: NeuralWavePainter(
                  progress: _waveAnimation.value,
                  isActive: _isSessionActive,
                  color: _isSessionActive ? Colors.cyan : tokens.textSecondary,
                ),
              );
            },
          ),

          // Center brain logo with pulse effect
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isSessionActive ? _pulseAnimation.value : 1.0,
                child: BrainLogo(
                  size: 80,
                  color: _isSessionActive ? Colors.cyan : tokens.textSecondary,
                  glowIntensity: _isSessionActive ? 0.8 : 0.3,
                ),
              );
            },
          ),

          // Status overlay
          if (_isSessionActive)
            Positioned(
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Neural enhancement active',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetSelection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Binaural Beats Preset',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: UltraPreset.defaultPresets.map((preset) {
            final isSelected = _selectedPreset?.key == preset.key;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPreset = preset;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.cyan.withValues(alpha: 0.2)
                      : tokens.elevatedSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.cyan : tokens.borderDefault,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: TextStyle(
                        color: isSelected ? Colors.cyan : tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: preset.trackKeys.map((key) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.bg.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            key.replaceAll('_', ' '),
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationSelection(SemanticTokens tokens) {
    final durations = [
      const Duration(minutes: 10),
      const Duration(minutes: 15),
      const Duration(minutes: 25),
      const Duration(minutes: 45),
      const Duration(minutes: 60),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Duration',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: durations.map((duration) {
            final isSelected = _sessionDuration == duration;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _sessionDuration = duration;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.cyan.withValues(alpha: 0.2)
                      : tokens.elevatedSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.cyan : tokens.borderDefault,
                  ),
                ),
                child: Text(
                  '${duration.inMinutes}min',
                  style: TextStyle(
                    color: isSelected ? Colors.cyan : tokens.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudySetSelection(SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Study Set (Optional)',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudySetSelectionScreen(
                      onStudySetSelected: (StudySet studySet) {
                        setState(() {
                          _selectedStudySet = studySet;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              child: const Text('Browse All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedStudySet != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.quiz, color: Colors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedStudySet!.title,
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          _selectedStudySet = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedStudySet!.flashcards.length} flashcards • ${_selectedStudySet!.quizzes.length} quizzes',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ] else if (_recentStudySets.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentStudySets.length,
              itemBuilder: (context, index) {
                final studySet = _recentStudySets[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStudySet = studySet;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.elevatedSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studySet.title,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '${studySet.flashcards.length} cards',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.elevatedSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderDefault),
            ),
            child: Text(
              'No study sets available. Create some content first!',
              style: TextStyle(color: tokens.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainActionButton(SemanticTokens tokens) {
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor;

    if (_isSessionActive) {
      buttonText = 'Pause Session';
      onPressed = _pauseResumeSession;
      buttonColor = Colors.orange;
    } else if (_isPaused) {
      buttonText = 'Resume Session';
      onPressed = _pauseResumeSession;
      buttonColor = Colors.cyan;
    } else {
      buttonText = 'Start Ultra Session';
      onPressed = _selectedPreset != null ? _startUltraSession : null;
      buttonColor = Colors.cyan;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  buttonColor.withValues(alpha: onPressed != null ? 1.0 : 0.3),
              foregroundColor: context.tokens.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Secondary actions
        if (_isSessionActive || _isPaused) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: _stopSession,
                icon: Icon(Icons.stop, color: context.tokens.error),
                label:
                    Text('Stop', style: TextStyle(color: context.tokens.error)),
              ),
              if (_selectedStudySet != null)
                TextButton.icon(
                  onPressed: _startStudySession,
                  icon: const Icon(Icons.quiz, color: Colors.cyan),
                  label:
                      const Text('Study', style: TextStyle(color: Colors.cyan)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSessionStats(SemanticTokens tokens) {
    return StreamBuilder<Duration>(
      stream: _audioController.positionStream,
      builder: (context, snapshot) {
        final remaining = _audioController.sessionRemaining;
        final progress = _audioController.sessionProgress;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.elevatedSurface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Session Progress',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: tokens.bg,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ${remaining.enhancedMmss}',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for neural wave visualization
class NeuralWavePainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final Color color;

  NeuralWavePainter({
    required this.progress,
    required this.isActive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.6 : 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final path = Path();

    // Generate neural wave pattern
    for (double x = 0; x < size.width; x += 2) {
      final normalizedX = x / size.width;
      final wave1 = math.sin((normalizedX + progress) * 4 * math.pi) * 20;
      final wave2 = math.sin((normalizedX + progress) * 8 * math.pi) * 10;
      final wave3 = math.sin((normalizedX + progress) * 12 * math.pi) * 5;

      final y = centerY + wave1 + wave2 + wave3;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw additional waves for active state
    if (isActive) {
      paint.color = color.withValues(alpha: 0.3);

      final path2 = Path();
      for (double x = 0; x < size.width; x += 3) {
        final normalizedX = x / size.width;
        final wave = math.sin((normalizedX - progress) * 6 * math.pi) * 15;
        final y = centerY + wave;

        if (x == 0) {
          path2.moveTo(x, y);
        } else {
          path2.lineTo(x, y);
        }
      }

      canvas.drawPath(path2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Extension for convenient duration formatting - Enhanced Screen version
extension EnhancedDurationFormatting on Duration {
  String get enhancedMmss {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

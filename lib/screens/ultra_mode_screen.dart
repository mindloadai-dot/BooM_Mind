import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:mindload/services/enhanced_storage_service.dart';
import 'package:mindload/services/ultra_audio_controller.dart';
import 'package:mindload/services/credit_service.dart';
import 'package:mindload/services/achievement_tracker_service.dart';
import 'package:mindload/services/mindload_notification_service.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/screens/study_screen.dart';
import 'package:mindload/screens/study_set_selection_screen.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/ultra_mode_guide.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'package:mindload/widgets/accessible_components.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/haptic_feedback_service.dart';
// Removed unused import: notification_service.dart

class UltraModeScreen extends StatefulWidget {
  const UltraModeScreen({super.key});

  @override
  State<UltraModeScreen> createState() => _UltraModeScreenState();
}

class _UltraModeScreenState extends State<UltraModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  final UltraAudioController _ultraAudioController =
      UltraAudioController.instance;
  final CreditService _creditService = CreditService.instance;
  Timer? _studyTimer;

  int _remainingSeconds = 0;
  int _selectedDurationMinutes = 25; // Default 25 minutes
  bool _isRunning = false;
  bool _isSoundEnabled = true;
  List<StudySet> _recentStudySets = [];
  StudySet? _selectedStudySet;
  bool _autoStartedAudio = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadRecentStudySets();
    _checkAndShowOnboarding();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

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

  Future<void> _initializeServices() async {
    try {
      // Initialize Ultra Audio Controller
      await _ultraAudioController.initialize();
      _remainingSeconds = _selectedDurationMinutes * 60; // Use local variable

      // Auto-start default Alpha track at low volume when entering Ultra Mode
      if (!_autoStartedAudio) {
        _autoStartedAudio = true;
        try {
          // Do not alter audio; play at current saved volume
          await _ultraAudioController.startSession(
            sessionLength: Duration(minutes: _selectedDurationMinutes),
            preset: const ['focus_alpha'],
          );
          await _ultraAudioController.play();
          debugPrint('[UltraMode] Auto-start audio successful');
        } catch (e) {
          debugPrint('[UltraMode] Auto-start audio failed: $e');
          // Show user-friendly error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Audio initialization failed: ${e.toString()}'),
                backgroundColor: context.tokens.warning,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // Listen to Ultra Audio Controller state changes
      _ultraAudioController.stateStream.listen((state) {
        if (mounted) {
          setState(() {
            // Sync UI state with Ultra Audio Controller
            _isRunning = state.isPlaying;
            if (state.remaining != Duration.zero) {
              _remainingSeconds = state.remaining.inSeconds;
            }
          });
        }
      });

      // Listen to detailed audio errors (with platform-specific messages)
      _ultraAudioController.errorStream.listen((ultraError) {
        if (!mounted) return;
        _showUltraAudioErrorDialog(ultraError);
      });

      debugPrint('[UltraMode] Services initialized successfully');
    } catch (e) {
      debugPrint('[UltraMode] Service initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  semanticLabel: 'Error',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio system initialization failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _checkAndShowOnboarding() async {
    final shouldShow = await UltraModeOnboarding.shouldShow();
    if (shouldShow && mounted) {
      // Show onboarding after a short delay to ensure UI is built
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          UltraModeOnboarding.show(context);
        }
      });
    }
  }

  void _showHelpGuide() {
    showDialog(
      context: context,
      builder: (context) => const UltraModeGuide(),
    );
  }

  /// Check audio system health and show status to user
  Future<void> _checkAudioSystemHealth() async {
    try {
      final availableTracks = _ultraAudioController.availableTracks;
      final isInitialized = _ultraAudioController.isInitialized;

      String statusMessage = '';
      Color statusColor = Colors.green;

      if (!isInitialized) {
        statusMessage = 'Audio system not initialized';
        statusColor = Colors.red;
      } else if (availableTracks.isEmpty) {
        statusMessage = 'No audio tracks available';
        statusColor = Colors.red;
      } else {
        statusMessage =
            '✅ Audio system healthy - ${availableTracks.length} tracks available';
        statusColor = Colors.green;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMessage),
            backgroundColor: statusColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Audio system check failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  AudioError _convertToAudioError(dynamic error) {
    // Convert UltraAudioError to AudioError
    if (error.runtimeType.toString().contains('UltraAudioError')) {
      final errorType = error.type.toString();
      if (errorType.contains('fileMissing')) return AudioError.fileNotFound;
      if (errorType.contains('focusLoss')) return AudioError.focusDenied;
      if (errorType.contains('routeChange')) return AudioError.routeChange;
      if (errorType.contains('startupFail')) {
        return AudioError.backendUnavailable;
      }
      if (errorType.contains('assetLoad')) return AudioError.decodeError;
      return AudioError.unknownError;
    }
    // If it's already AudioError, return as is
    return error as AudioError;
  }

  void _showAudioErrorDialog(AudioError error) {
    final tokens = context.tokens;
    String title = 'Audio Error';
    String message = 'An audio error occurred. Please try again.';
    IconData icon = Icons.error_outline;

    switch (error) {
      case AudioError.fileNotFound:
        title = 'Audio Files Missing';
        message = 'Some audio files are missing. Please reinstall the app.';
        icon = Icons.file_download_off;
        break;
      case AudioError.decodeError:
        title = 'Audio Format Error';
        message = 'Audio file format not supported or corrupted.';
        icon = Icons.audiotrack_outlined;
        break;
      case AudioError.focusDenied:
        title = 'Audio Focus Denied';
        message = 'Please close other audio apps and try again.';
        icon = Icons.volume_off;
        break;
      case AudioError.routeChange:
        title = 'Audio Route Changed';
        message = 'Audio device disconnected. Check your headphones.';
        icon = Icons.headphones_outlined;
        break;
      case AudioError.interruption:
        title = 'Audio Interrupted';
        message = 'Audio was interrupted by system. Tap to resume.';
        icon = Icons.pause_circle_outline;
        break;
      case AudioError.backendUnavailable:
        title = 'Audio System Unavailable';
        message = 'Please restart the app to reinitialize audio.';
        icon = Icons.restart_alt;
        break;
      case AudioError.unknownError:
        title = 'Unknown Audio Error';
        message = 'Please try restarting the session.';
        icon = Icons.help_outline;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: tokens.warning,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AccessibleButton(
                      onPressed: () => Navigator.pop(context),
                      variant: ButtonVariant.secondary,
                      size: ButtonSize.medium,
                      semanticLabel: 'Dismiss audio error dialog',
                      child: const Text('OK'),
                    ),
                  ),
                  if (error == AudioError.routeChange ||
                      error == AudioError.interruption) ...[
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: AccessibleButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _startTimer(); // Try to resume
                        },
                        variant: ButtonVariant.primary,
                        size: ButtonSize.medium,
                        semanticLabel: 'Resume audio session',
                        child: const Text('RESUME'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Improved error dialog that leverages UltraAudioController's rich errors
  void _showUltraAudioErrorDialog(dynamic ultraError) {
    // ultraError is UltraAudioError; avoid import coupling by duck-typing
    final String typeName = ultraError.type.toString();
    final String message = ultraError.message?.toString() ?? '';

    // Map to existing enum for base title/icon, but keep detailed message
    AudioError mapped;
    if (typeName.contains('fileMissing')) {
      mapped = AudioError.fileNotFound;
    } else if (typeName.contains('assetLoad')) {
      mapped = AudioError.decodeError;
    } else if (typeName.contains('focusLoss')) {
      mapped = AudioError.focusDenied;
    } else if (typeName.contains('routeChange')) {
      mapped = AudioError.routeChange;
    } else if (typeName.contains('startupFail')) {
      mapped = AudioError.backendUnavailable;
    } else {
      mapped = AudioError.unknownError;
    }

    // Build a clearer, actionable message
    String helpful = message;
    if (mapped == AudioError.decodeError) {
      if (message.toLowerCase().contains('timeout')) {
        helpful =
            'Playback took too long to start. On web this can be caused by browser autoplay policies or an ad/tracker blocker. Tap TRY AGAIN to retry.';
      } else if (message.isEmpty) {
        helpful =
            'Audio file format may not be supported by your browser. Try another track or use Chrome/Edge.';
      }
    }

    final tokens = context.tokens;
    String title;
    IconData icon;
    String description;
    if (mapped == AudioError.decodeError &&
        helpful.toLowerCase().contains('playback')) {
      title = 'Playback Timeout';
      icon = Icons.wifi_tethering_error_rounded;
      description = helpful;
    } else if (mapped == AudioError.decodeError) {
      title = 'Audio Format Error';
      icon = Icons.audiotrack_outlined;
      description = helpful.isNotEmpty
          ? helpful
          : 'Audio file format not supported or corrupted.';
    } else if (mapped == AudioError.fileNotFound) {
      title = 'Audio Files Missing';
      icon = Icons.file_download_off;
      description = 'Some audio files are missing. Please reinstall the app.';
    } else if (mapped == AudioError.backendUnavailable) {
      title = 'Audio System Unavailable';
      icon = Icons.restart_alt;
      description = 'Please restart the app to reinitialize audio.';
    } else {
      title = 'Audio Error';
      icon = Icons.error_outline;
      description = helpful.isNotEmpty
          ? helpful
          : 'An audio error occurred. Please try again.';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: tokens.warning),
              const SizedBox(height: Spacing.md),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AccessibleButton(
                      onPressed: () => Navigator.pop(context),
                      variant: ButtonVariant.secondary,
                      size: ButtonSize.medium,
                      semanticLabel: 'Dismiss audio error dialog',
                      child: const Text('OK'),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: AccessibleButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _ultraAudioController.resume();
                        } catch (_) {
                          await _ultraAudioController.play();
                        }
                      },
                      variant: ButtonVariant.primary,
                      size: ButtonSize.medium,
                      semanticLabel: 'Retry audio playback',
                      child: const Text('TRY AGAIN'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _studyTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    // Ensure Ultra Mode audio fully stops when leaving this screen
    try {
      _ultraAudioController.stop();
    } catch (_) {}
    // Note: Don't dispose Ultra Audio Controller as it's a singleton
    super.dispose();
  }

  void _showCompletionDialog() {
    // Update study time - using enhanced storage service
    // EnhancedStorageService.instance.updateStudyTime(_selectedDurationMinutes);
    final tokens = context.tokens;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brain icon from BrainLogo widget
              Semantics(
                label: 'Session completed successfully',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tokens.primary,
                        tokens.primary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: BrainLogo(
                    size: 64,
                    color: tokens.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Semantics(
                header: true,
                child: Text(
                  'ULTRA SESSION COMPLETE!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'You focused for $_selectedDurationMinutes minutes with binaural beats.\nNeural pathways strengthened!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                textAlign: TextAlign.center,
                semanticsLabel:
                    'Session completed successfully. You focused for $_selectedDurationMinutes minutes using binaural beats. Your neural pathways have been strengthened through this focused session.',
              ),
              const SizedBox(height: Spacing.lg),
              AccessibleButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Announce completion
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Ultra Mode session completed successfully!'),
                      backgroundColor: tokens.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                semanticLabel: 'Complete session and return to Ultra Mode',
                tooltip: 'Close completion dialog and return to main screen',
                fullWidth: true,
                child: const Text('EXCELLENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Session Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('25 minutes'),
              onTap: () => _changeDuration(25),
            ),
            ListTile(
              title: const Text('45 minutes'),
              onTap: () => _changeDuration(45),
            ),
            ListTile(
              title: const Text('60 minutes'),
              onTap: () => _changeDuration(60),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeDuration(int minutes) async {
    try {
      Navigator.of(context).pop();
      // Update selection and remaining time
      setState(() {
        _selectedDurationMinutes = minutes;
        _remainingSeconds = minutes * 60;
      });

      // If a session is running, restart it with the new length
      if (_isRunning) {
        _studyTimer?.cancel();

        try {
          await _ultraAudioController.stop();
          await _ultraAudioController.startSession(
            sessionLength: Duration(minutes: minutes),
            preset: const ['focus_alpha'],
          );
          if (_isSoundEnabled) {
            await _ultraAudioController.play();
          }
        } catch (e) {
          debugPrint(
              '[UltraMode] Failed to restart session with new duration: $e');
        }

        // Restart UI countdown timer
        _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_remainingSeconds > 0) {
            setState(() {
              _remainingSeconds--;
            });
          } else {
            _completeSession();
          }
        });

        setState(() {
          _isRunning = true;
        });
      }
    } catch (e) {
      debugPrint('[UltraMode] Change duration failed: $e');
    }
  }

  void _showAudioTrackDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Select Audio Track'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamically load all available tracks from the controller
              ..._ultraAudioController.availableTracks.map((track) => ListTile(
                    title: Text(track.title),
                    subtitle: Text(track.description),
                    trailing: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onTap: () async {
                      // Haptic feedback for track selection
                      HapticFeedbackService().selectionClick();

                      Navigator.of(context).pop();

                      try {
                        // Switch track and continue playback if active
                        await _ultraAudioController.selectTrack(track.key);

                        if (_isRunning) {
                          try {
                            await _ultraAudioController.play();
                          } catch (e) {
                            await _ultraAudioController.resume();
                          }
                        }

                        // Show success feedback
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Selected: ${track.title}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        // Show error feedback
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '❌ Failed to switch to ${track.title}: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadRecentStudySets() async {
    try {
      final studySets = await EnhancedStorageService.instance.getAllStudySets();
      final sortedSets = studySets
        ..sort((a, b) => (b.lastStudied ?? DateTime(1970))
            .compareTo(a.lastStudied ?? DateTime(1970)));
      // Note: getLastCustomStudySet method needs to be implemented in EnhancedStorageService
      // For now, we'll get the most recent study set
      final lastCustom = sortedSets.isNotEmpty ? sortedSets.first : null;

      setState(() {
        _recentStudySets =
            sortedSets.take(3).toList(); // sortedSets is already List<StudySet>
        if (lastCustom != null) {
          _selectedStudySet = lastCustom; // lastCustom is already a StudySet
        }
      });
    } catch (e) {
      debugPrint('Error loading study sets: $e');
    }
  }

  /// Start the Ultra Mode timer and audio session
  Future<void> _startTimer() async {
    try {
      // Haptic feedback for starting timer
      HapticFeedbackService().mediumImpact();

      setState(() {
        _isRunning = true;
      });

      // Auto-start Ultra Audio with default Alpha at low volume
      await _ultraAudioController.setVolume(0.25);
      // Start Ultra Audio Controller session with default track
      await _ultraAudioController.startSession(
        sessionLength: Duration(minutes: _selectedDurationMinutes),
        preset: ['focus_alpha'], // Use default track
      );

      // Start audio if enabled
      if (_isSoundEnabled) {
        await _ultraAudioController.play();
      }

      // Start the UI timer
      _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _completeSession();
        }
      });

      debugPrint(
          '[UltraMode] Timer started for $_selectedDurationMinutes minutes');
    } catch (e) {
      setState(() {
        _isRunning = false;
      });
      debugPrint('[UltraMode] Failed to start timer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                semanticLabel: 'Error',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Failed to start timer: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Pause the Ultra Mode session
  Future<void> _pauseTimer() async {
    try {
      // Haptic feedback for pausing timer
      HapticFeedbackService().lightImpact();

      _studyTimer?.cancel();

      setState(() {
        _isRunning = false;
      });

      // Pause Ultra Audio Controller
      await _ultraAudioController.pause();

      // Also pause binaural service
      await _ultraAudioController.pause();

      debugPrint('[UltraMode] Timer paused');
    } catch (e) {
      debugPrint('[UltraMode] Failed to pause timer: $e');
    }
  }

  /// Resume the Ultra Mode session
  Future<void> _resumeTimer() async {
    try {
      // Haptic feedback for resuming timer
      HapticFeedbackService().mediumImpact();

      setState(() {
        _isRunning = true;
      });

      // Resume Ultra Audio Controller
      await _ultraAudioController.resume();

      // Also resume binaural service
      if (_isSoundEnabled) {
        await _ultraAudioController.resume();
      }

      // Restart the UI timer
      _studyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _completeSession();
        }
      });

      debugPrint('[UltraMode] Timer resumed');
    } catch (e) {
      debugPrint('[UltraMode] Failed to resume timer: $e');
    }
  }

  /// Reset the timer to initial duration
  void _resetTimer() {
    _studyTimer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDurationMinutes * 60;
    });

    // Stop audio
    _ultraAudioController.stop();

    debugPrint('[UltraMode] Timer reset');
  }

  /// Complete the session (called when timer reaches zero)
  void _completeSession() {
    _studyTimer?.cancel();

    setState(() {
      _isRunning = false;
    });

    // Stop audio
    _ultraAudioController.stop();

    // Track comprehensive achievement metrics
    _trackUltraSessionCompletion();

    // Show completion dialog
    _showCompletionDialog();
  }

  /// Track Ultra Mode session completion with comprehensive metrics
  void _trackUltraSessionCompletion() async {
    try {
      final sessionDuration = _selectedDurationMinutes;
      final wasCompleted = true; // Session completed successfully
      final focusBreaks =
          0; // Simplified - could be enhanced with actual break tracking

      // Track the ultra session with enhanced metrics
      await AchievementTrackerService.instance.trackUltraSession(
        durationMinutes: sessionDuration,
        wasCompleted: wasCompleted,
        focusBreaks: focusBreaks,
      );

      // Track study time separately
      await AchievementTrackerService.instance.trackStudyTime(
        sessionDuration,
        context: 'ultra_mode',
      );

      // Track study session
      await AchievementTrackerService.instance.trackStudySession(
        durationMinutes: sessionDuration,
        studyType: 'ultra_mode',
        itemsStudied: _selectedStudySet?.flashcards.length ?? 0,
        accuracyRate: null, // Ultra mode doesn't track accuracy
      );

      // Check and fire first ultra mode session micro notification
      MindLoadNotificationService.checkAndFireFirstUltraModeNotification();

      debugPrint(
          'Ultra Mode session completion tracked: ${sessionDuration}min, completed: $wasCompleted');
    } catch (e) {
      debugPrint('Failed to track Ultra Mode session completion: $e');
    }
  }

  /// Start study session with achievement tracking
  void _startStudySession() async {
    if (_selectedStudySet == null) {
      _showErrorSnackBar('Please select a study set first');
      return;
    }

    try {
      // Track entering ultra mode
      await _trackUltraModeEntry();

      // Navigate to study screen
      if (mounted) {
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
    } catch (e) {
      debugPrint('Failed to start study session: $e');
      _showErrorSnackBar('Failed to start study session');
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Track entering ultra mode for achievements
  Future<void> _trackUltraModeEntry() async {
    try {
      // Track entering ultra mode
      await AchievementTrackerService.instance.trackUltraSession(
        durationMinutes: _selectedDurationMinutes,
        wasCompleted: false, // Just entering, not completed yet
        focusBreaks: 0,
      );

      debugPrint('Ultra Mode entry tracked');
    } catch (e) {
      debugPrint('Failed to track Ultra Mode entry: $e');
    }
  }

  Widget _buildStudySessionButtons() {
    final tokens = context.tokens;

    return AccessibleCard(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      semanticLabel: 'Study session setup',
      elevation: 2.0,
      child: Column(
        children: [
          Semantics(
            header: true,
            child: Text(
              'STUDY SESSION SETUP',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tokens.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Selected study set display
          if (_selectedStudySet != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: tokens.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tokens.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: tokens.success,
                    size: 16,
                    semanticLabel: 'Selected',
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedStudySet!.title}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_selectedStudySet!.quizzes.length}Q • ${_selectedStudySet!.flashcards.length}F',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                    semanticsLabel:
                        '${_selectedStudySet!.quizzes.length} quizzes and ${_selectedStudySet!.flashcards.length} flashcards available',
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: tokens.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tokens.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: tokens.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          'No study set selected',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select one to enable STUDY mode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],

          // Study set selection button
          SizedBox(
            width: double.infinity,
            child: AccessibleButton(
              onPressed: _showStudySetSelection,
              variant: ButtonVariant.secondary,
              size: ButtonSize.medium,
              semanticLabel: _selectedStudySet != null
                  ? 'Change current study set from ${_selectedStudySet!.title}'
                  : 'Select a study set to enable study mode',
              tooltip: 'Browse and select from your study sets',
              fullWidth: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 18,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    _selectedStudySet != null
                        ? 'CHANGE STUDY SET'
                        : 'SELECT STUDY SET',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

  void _showStudySetSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudySetSelectionScreen(
          onStudySetSelected: (studySet) {
            setState(() {
              _selectedStudySet = studySet;
            });
          },
        ),
      ),
    );
  }

  void _startFlashcardSession(StudySet studySet) {
    if (studySet.flashcards.isEmpty) {
      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No flashcards available in ${studySet.title}'),
          backgroundColor: tokens.warning,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyScreen(studySet: studySet),
      ),
    );
  }

  void _startQuizSession(StudySet studySet) {
    if (studySet.quizzes.isEmpty) {
      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No quizzes available in ${studySet.title}'),
          backgroundColor: tokens.warning,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyScreen(studySet: studySet),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SafeAreaWrapper(
      screenName: 'ultra_mode_screen',
      child: Scaffold(
        appBar: MindloadAppBarFactory.secondary(
          title: 'ULTRA MODE',
          actions: [
            // Help/Guide button
            Container(
              margin: const EdgeInsets.only(right: Spacing.sm),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.outline,
                ),
              ),
              child: AccessibleButton(
                onPressed: _showHelpGuide,
                variant: ButtonVariant.text,
                size: ButtonSize.small,
                semanticLabel: 'Ultra Mode Setup Guide',
                tooltip: 'Learn about Ultra Mode features and setup',
                child: Icon(
                  Icons.help_outline,
                  color: tokens.primary,
                  size: 20,
                ),
              ),
            ),
            StreamBuilder<bool>(
              stream: _ultraAudioController.playingStream,
              builder: (context, playingSnapshot) {
                final isPlaying = playingSnapshot.data ?? false;
                if (!isPlaying) return const SizedBox();

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        label: 'Audio playing indicator',
                        child: Icon(
                          Icons.graphic_eq,
                          color: tokens.primary,
                          size: 20,
                        ),
                      ),
                      Text(
                        'ON',
                        style: TextStyle(
                          color: tokens.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel: 'Audio is playing',
                      ),
                    ],
                  ),
                );
              },
            ),
            StreamBuilder<bool>(
              stream: _ultraAudioController.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return AccessibleButton(
                  onPressed: () {
                    setState(() => _isSoundEnabled = !_isSoundEnabled);
                    if (!_isSoundEnabled && isPlaying) {
                      _ultraAudioController.pause();
                    } else if (_isSoundEnabled && _isRunning) {
                      _ultraAudioController.play();
                    }

                    // Announce state change
                    final stateMessage =
                        _isSoundEnabled ? 'Audio enabled' : 'Audio disabled';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(stateMessage),
                        duration: const Duration(milliseconds: 1000),
                      ),
                    );
                  },
                  variant: ButtonVariant.text,
                  size: ButtonSize.medium,
                  semanticLabel: _isSoundEnabled
                      ? 'Audio enabled. Tap to disable audio'
                      : 'Audio disabled. Tap to enable audio',
                  tooltip: 'Toggle binaural beats audio',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                        color: tokens.primary,
                        size: 24,
                      ),
                      if (isPlaying && _isSoundEnabled)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tokens.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                tokens.primary.withValues(alpha: 0.1),
                tokens.bg,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                // First-time user tips (show when no study sets available)
                if (_recentStudySets.isEmpty && _selectedStudySet == null) ...[
                  Container(
                    margin: const EdgeInsets.all(Spacing.md),
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tokens.primary.withValues(alpha: 0.3),
                          tokens.primary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tokens.outline,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: tokens.primary,
                              size: 24,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                'New to Ultra Mode?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: tokens.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Learn how to set up distraction-free study sessions with binaural beats, customizable timers, and focus tracking.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: Spacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: AccessibleButton(
                            onPressed: _showHelpGuide,
                            variant: ButtonVariant.outline,
                            size: ButtonSize.large,
                            semanticLabel:
                                'Learn Ultra Mode features and setup',
                            tooltip: 'Open Ultra Mode tutorial and guide',
                            fullWidth: true,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.school, size: 18),
                                  const SizedBox(width: Spacing.xs),
                                  Text(
                                    'LEARN ULTRA MODE',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const SizedBox(height: Spacing.xl),

                // Neural wave visualization
                Semantics(
                  label: _isRunning
                      ? 'Neural wave visualization - session active'
                      : 'Neural wave visualization - session inactive',
                  child: AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) => Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: Spacing.xs),
                      constraints: const BoxConstraints(
                        maxWidth: double.infinity,
                        minHeight: 80,
                        maxHeight: 100,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tokens.outline,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: WavePainter(
                            animation: _waveAnimation.value,
                            color: tokens.primary,
                            isRunning: _isRunning,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: Spacing.xxxl),

                // Timer display
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _isRunning ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        ),
                        boxShadow: _isRunning
                            ? [
                                BoxShadow(
                                  color: tokens.primary.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: tokens.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 48,
                                  ),
                              semanticsLabel:
                                  '${_formatTime(_remainingSeconds)} remaining',
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              _isRunning
                                  ? 'NEURAL SYNC ACTIVE'
                                  : 'READY TO FOCUS',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: tokens.primary,
                                    letterSpacing: 1,
                                  ),
                              semanticsLabel: _isRunning
                                  ? 'Session is active, neural synchronization in progress'
                                  : 'Timer ready, tap start to begin focus session',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: Spacing.xxxl),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reset button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AccessibleButton(
                          onPressed: _resetTimer,
                          variant: ButtonVariant.secondary,
                          size: ButtonSize.large,
                          semanticLabel: 'Reset timer to initial duration',
                          tooltip: 'Reset the focus timer',
                          child: Icon(
                            Icons.refresh,
                            color: tokens.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'RESET',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                        ),
                      ],
                    ),
                    // Main action button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AccessibleButton(
                          onPressed: () {
                            if (_isRunning) {
                              _pauseTimer();
                            } else if (_selectedStudySet != null) {
                              _startStudySession();
                            } else {
                              _startTimer();
                            }
                          },
                          variant: ButtonVariant.primary,
                          size: ButtonSize.large,
                          semanticLabel: _isRunning
                              ? 'Pause focus session'
                              : (_selectedStudySet != null
                                  ? 'Start study session with ${_selectedStudySet!.title}'
                                  : 'Start focus timer'),
                          tooltip: _isRunning
                              ? 'Pause the current session'
                              : (_selectedStudySet != null
                                  ? 'Begin studying with selected study set'
                                  : 'Start focus timer with binaural beats'),
                          child: Icon(
                            _isRunning
                                ? Icons.pause
                                : (_selectedStudySet != null
                                    ? Icons.school
                                    : Icons.play_arrow),
                            color: tokens.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          _isRunning
                              ? 'PAUSE'
                              : (_selectedStudySet != null ? 'STUDY' : 'START'),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                        ),
                      ],
                    ),
                    // Configuration button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AccessibleButton(
                          onPressed: _showTimePickerDialog,
                          variant: ButtonVariant.secondary,
                          size: ButtonSize.large,
                          semanticLabel:
                              'Configure timer duration: currently $_selectedDurationMinutes minutes',
                          tooltip: 'Change timer duration and session settings',
                          child: Icon(
                            Icons.settings,
                            color: tokens.primary,
                            semanticLabel: 'Settings',
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'CONFIG',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: Spacing.xl),

                // Study session buttons (show when timer is not running)
                if (!_isRunning) _buildStudySessionButtons(),

                // Quick study options (show when study set is selected and timer not running)
                if (!_isRunning && _selectedStudySet != null) ...[
                  const SizedBox(height: Spacing.md),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    child: Row(
                      children: [
                        if (_selectedStudySet!.flashcards.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _startFlashcardSession(_selectedStudySet!),
                              icon: Icon(Icons.quiz_outlined, size: 16),
                              label: Text(
                                'FLASHCARDS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        if (_selectedStudySet!.flashcards.isNotEmpty &&
                            _selectedStudySet!.quizzes.isNotEmpty)
                          const SizedBox(width: Spacing.xs),
                        if (_selectedStudySet!.quizzes.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _startQuizSession(_selectedStudySet!),
                              icon: Icon(Icons.assignment, size: 16),
                              label: Text(
                                'QUIZ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: Spacing.lg),

                // Audio Controls (when playing)
                StreamBuilder<bool>(
                  stream: _ultraAudioController.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    if (!isPlaying || !_isRunning) return const SizedBox();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _ultraAudioController.pause(),
                          icon: const Icon(Icons.pause),
                          tooltip: 'Pause audio',
                        ),
                        IconButton(
                          onPressed: () => _ultraAudioController.play(),
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Play audio',
                        ),
                        IconButton(
                          onPressed: () => _ultraAudioController.stop(),
                          icon: const Icon(Icons.stop),
                          tooltip: 'Stop audio',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: Spacing.xxxl),

                // Settings cards
                AccessibleCard(
                  onTap: () {
                    _showTimePickerDialog();
                  },
                  semanticLabel:
                      'Focus duration settings: Currently $_selectedDurationMinutes minutes. Tap to change duration.',
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: tokens.primary,
                        semanticLabel: 'Timer',
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FOCUS DURATION',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: tokens.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '$_selectedDurationMinutes minutes',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                              semanticsLabel:
                                  'Duration set to $_selectedDurationMinutes minutes',
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: tokens.textSecondary,
                        size: 16,
                        semanticLabel: 'Tap to configure',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Spacing.sm),

                // Audio System Health Check
                AccessibleCard(
                  onTap: () {
                    HapticFeedbackService().lightImpact();
                    _checkAudioSystemHealth();
                  },
                  semanticLabel:
                      'Audio system health check. Tap to verify audio system status.',
                  child: Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: tokens.primary,
                        semanticLabel: 'Health Check',
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AUDIO SYSTEM HEALTH',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: tokens.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Tap to check audio system status',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                              semanticsLabel:
                                  'Tap to verify audio system is working properly',
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: tokens.textSecondary,
                        size: 16,
                        semanticLabel: 'Tap to check',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Spacing.sm),

                AccessibleCard(
                  onTap: () {
                    _showAudioTrackDialog();
                  },
                  semanticLabel:
                      'Audio track settings: Currently using Alpha Focus track. Tap to change audio track.',
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        color: tokens.primary,
                        semanticLabel: 'Audio Track',
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AUDIO TRACK',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: tokens.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            StreamBuilder<UltraAudioTrack?>(
                              stream: _ultraAudioController.stateStream
                                  .map((s) => s.currentTrack)
                                  .distinct(),
                              builder: (context, snapshot) {
                                final selectedTrack = snapshot.data;
                                final trackName =
                                    selectedTrack?.title ?? 'Alpha Focus';
                                final trackDesc = selectedTrack?.description ??
                                    'Enhanced focus and concentration';

                                return Text(
                                  '$trackName ($trackDesc)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: tokens.textSecondary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  semanticsLabel:
                                      'Currently using $trackName audio track for $trackDesc',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Volume indicator when playing
                      StreamBuilder<bool>(
                        stream: _ultraAudioController.playingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          if (isPlaying && _isRunning) {
                            return Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: tokens.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: tokens.onPrimary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Track Ultra Mode session for achievements
  void _trackUltraSession() async {
    try {
      await AchievementTrackerService.instance.trackUltraSession();
      debugPrint('Ultra Mode session tracked');
    } catch (e) {
      debugPrint('Failed to track Ultra Mode session: $e');
    }
  }

  /// Track study time for achievements
  void _trackStudyTime(int minutes) async {
    try {
      await AchievementTrackerService.instance.trackStudyTime(minutes);
      debugPrint('Study time tracked: $minutes minutes');
    } catch (e) {
      debugPrint('Failed to track study time: $e');
    }
  }

  // _buildControlButton method removed - replaced with accessible components
}

class WavePainter extends CustomPainter {
  final double animation;
  final Color color;
  final bool isRunning;

  WavePainter({
    required this.animation,
    required this.color,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isRunning ? 0.6 : 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    final waveHeight = isRunning ? 30 : 10;

    path.moveTo(0, centerY);

    for (double x = 0; x <= size.width; x += 4) {
      final normalizedX = x / size.width;
      final wavePhase = (animation * 2 * 3.14159) + (normalizedX * 4 * 3.14159);
      final y = centerY + (waveHeight * math.sin(wavePhase));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw secondary wave
    if (isRunning) {
      final paint2 = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final path2 = Path();
      path2.moveTo(0, centerY);

      for (double x = 0; x <= size.width; x += 4) {
        final normalizedX = x / size.width;
        final wavePhase =
            (animation * 2 * 3.14159 * 1.5) + (normalizedX * 6 * 3.14159);
        final y = centerY + (15 * math.sin(wavePhase));
        path2.lineTo(x, y);
      }

      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.isRunning != isRunning;
}

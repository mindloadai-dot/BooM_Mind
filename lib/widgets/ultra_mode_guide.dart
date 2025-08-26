import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'package:mindload/theme.dart';

class UltraModeGuide extends StatefulWidget {
  final VoidCallback? onDismiss;
  final bool showAsOnboarding;

  const UltraModeGuide({
    super.key,
    this.onDismiss,
    this.showAsOnboarding = false,
  });

  @override
  State<UltraModeGuide> createState() => _UltraModeGuideState();
}

class _UltraModeGuideState extends State<UltraModeGuide> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const String _guideShownKey = 'ultra_mode_guide_shown';

  List<GuideStep> _getSteps(BuildContext context) {
    final tokens = context.tokens;
    
    return [
    GuideStep(
      icon: BrainLogo(size: 40, color: tokens.primary),
      title: 'Enter Ultra Mode',
      description: 'Open the app and tap Ultra Mode from the home screen or study tab.\n\nUltra Mode is designed for distraction-free, high-focus study sessions with a combination of quizzes, flashcards, and optional binaural beats.',
      color: tokens.primary,
    ),
    GuideStep(
      icon: Icon(Icons.folder_open, color: context.tokens.success, size: 40),
      title: 'Select Your Study Set',
      description: 'Before starting, you\'ll see the "Select Your Study Set" screen with three options:\n\n• Use My Last Custom Set – loads your most recent configuration instantly\n• Choose From Saved Sets – select from any quiz or flashcard sets you\'ve saved\n• Create New Custom Set – opens the Customize Study Set modal',
      color: context.tokens.success,
    ),
    GuideStep(
      icon: Icon(Icons.tune, color: context.tokens.warning, size: 40),
      title: 'Adjust Study Preferences',
      description: 'If you choose to Create New Custom Set, you can:\n\n• Choose up to 30 quiz questions\n• Choose up to 50 flashcards\n• Use the AI "Optimal Count" recommendation for efficiency\n• Review credit cost before generating\n\nFor Free Tier users: each set uses 1 credit (quiz or flashcard). Generating both in the same session uses 2 credits. Pro Tier users have unlimited sets.',
      color: context.tokens.warning,
    ),
    GuideStep(
      icon: Icon(Icons.headphones, color: context.tokens.accent, size: 40),
      title: 'Add Focus Audio (Optional)',
      description: 'Select from the binaural beats library (unlimited access for all tiers):\n\n• Gamma Focus (40 Hz) – deep concentration\n• Memory Flow (8 Hz) – memory enhancement\n• Deep Reset (6 Hz) – relaxation reset\n• Calm Clarity (11 Hz Alpha) – relaxed focus\n• Creative Flow (10 Hz Alpha) – creative thinking\n• Power Focus (14 Hz Beta) – intense focus\n• Dream State (4 Hz Theta) – deep relaxation\n\nAudio loops seamlessly for your entire session.',
      color: context.tokens.accent,
    ),
    GuideStep(
      icon: Icon(Icons.timer, color: context.tokens.primary, size: 40),
      title: 'Choose Your Session Length',
      description: 'Available durations: 5, 10, 15, 30, 45, 60 minutes.\n\nYour selected quiz/flashcard set will repeat or rotate until the timer ends.\n\nThe neural visualization shows real-time brain wave patterns matching your selected binaural frequency.',
      color: context.tokens.primary,
    ),
    GuideStep(
      icon: Icon(Icons.play_arrow, color: context.tokens.error, size: 40),
      title: 'Start Ultra Mode',
      description: 'Press Start Session to activate Ultra Mode:\n\n• All notifications are silenced except urgent reminders\n• Screen stays active (optional toggle)\n• Progress is tracked in real-time\n• Neural sync visualization shows your focus state\n• Binaural beats play continuously with your selected track',
      color: context.tokens.error,
    ),
    GuideStep(
      icon: Icon(Icons.insights, color: tokens.success, size: 40),
      title: 'End or Extend Session',
      description: 'When your session completes:\n\n• You can end early and still save progress\n• At the end, you can extend time without leaving Ultra Mode\n• Progress is stored and influences future AI "Optimal Count" recommendations\n• Study streaks and XP are automatically updated',
      color: tokens.success,
    ),
    GuideStep(
      icon: Icon(Icons.tips_and_updates, color: tokens.warning, size: 40),
      title: 'Tips for Best Results',
      description: '• Use headphones if listening to binaural beats\n• Stick to a consistent daily Ultra Mode routine\n• Choose a study set that challenges you but is achievable within the session length\n• Review session summaries to see improvement trends\n• Start with shorter sessions (15-30 min) and gradually increase\n• Ensure good lighting and comfortable seating',
      color: tokens.warning,
    ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markGuideAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guideShownKey, true);
  }

  static Future<bool> shouldShowGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_guideShownKey) ?? false);
  }

  void _nextPage() {
    if (_currentPage < _getSteps(context).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeGuide();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeGuide() async {
    await _markGuideAsShown();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _skipGuide() async {
    // Skip just this time (do not mark as shown)
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _dontShowAgain() async {
    // Persist preference to never show again
    await _markGuideAsShown();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeManager.instance.currentTokens;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tokens.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.primary,
                    tokens.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      color: tokens.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ULTRA MODE GUIDE',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textInverse,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Master your focus sessions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textInverse.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.showAsOnboarding)
                    IconButton(
                      onPressed: _skipGuide,
                      icon: Icon(
                        Icons.close,
                        color: tokens.textInverse,
                      ),
                    ),
                ],
              ),
            ),

            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _getSteps(context).length,
                      backgroundColor: tokens.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentPage + 1} / ${_getSteps(context).length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _getSteps(context).length,
                itemBuilder: (context, index) {
                  final step = _getSteps(context)[index];
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Step icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: step.color.withValues(alpha:  0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: step.color.withValues(alpha:  0.3),
                              width: 2,
                            ),
                          ),
                          child: step.icon,
                        ),
                        const SizedBox(height: 16),

                        // Step title
                        Text(
                          'Step ${index + 1} – ${step.title}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: tokens.textEmphasis,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Step description
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              step.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: tokens.textMuted,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Left actions (wrapped and flexible to avoid overflow)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: _previousPage,
                              child: Text(
                                'PREVIOUS',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: tokens.primary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          else if (!widget.showAsOnboarding) ...[
                            TextButton(
                              onPressed: _skipGuide,
                              child: Text(
                                'EXIT',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: tokens.textMuted,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _dontShowAgain,
                              child: Text(
                                "DON'T SHOW AGAIN",
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.7),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ] else ...[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'EXIT',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: tokens.textMuted,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _dontShowAgain,
                              child: Text(
                                "DON'T SHOW AGAIN",
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.7),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Right primary action (scaled to avoid overflow)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primary,
                        foregroundColor: tokens.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        _currentPage < _getSteps(context).length - 1 ? 'NEXT' : 'GET STARTED',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 12,
                          color: tokens.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuideStep {
  final Widget icon;
  final String title;
  final String description;
  final Color color;

  const GuideStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// Static method to show the guide as a full-screen onboarding
class UltraModeOnboarding extends StatelessWidget {
  const UltraModeOnboarding({super.key});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('ultra_mode_guide_shown') ?? false);
  }

  static void show(BuildContext context, {VoidCallback? onComplete}) {
    showDialog(
      context: context,
      barrierDismissible: true, // allow exit by tapping outside
      builder: (context) => UltraModeGuide(
        showAsOnboarding: true,
        onDismiss: () {
          Navigator.of(context).pop();
          if (onComplete != null) onComplete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UltraModeGuide(showAsOnboarding: true);
  }
}
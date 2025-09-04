import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/theme.dart';

class CustomizeStudySetDialog extends StatefulWidget {
  final String topicDifficulty;
  final Function(int quizCount, int flashcardCount) onGenerate;
  final String? sourceContent;

  const CustomizeStudySetDialog({
    super.key,
    this.topicDifficulty = 'medium',
    required this.onGenerate,
    this.sourceContent,
  });

  @override
  State<CustomizeStudySetDialog> createState() =>
      _CustomizeStudySetDialogState();
}

class _CustomizeStudySetDialogState extends State<CustomizeStudySetDialog>
    with TickerProviderStateMixin {
  final MindloadEconomyService _economyService =
      MindloadEconomyService.instance;

  int _quizCount = 0;
  int _flashcardCount = 0;
  Map<String, int> _optimalCounts = {};
  bool _isLoading = true;
  bool _isGenerating = false;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  // Animations
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCountsWithOptimal();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeCountsWithOptimal() async {
    setState(() => _isLoading = true);

    // Simulate a brief delay for AI calculation
    await Future.delayed(const Duration(milliseconds: 300));

    _optimalCounts =
        _calculateOptimalCounts(_parseDifficulty(widget.topicDifficulty));

    setState(() {
      _quizCount = _optimalCounts['quiz'] ?? 10;
      _flashcardCount = _optimalCounts['flashcards'] ?? 15;
      _isLoading = false;
    });
  }

  DifficultyLevel _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'intermediate':
      case 'medium':
        return DifficultyLevel.intermediate;
      case 'advanced':
      case 'hard':
        return DifficultyLevel.advanced;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }

  Map<String, int> _calculateOptimalCounts(DifficultyLevel topicDifficulty) {
    // Base optimal counts based on current tier
    final tier = _economyService.currentTier;
    int optimalQuiz = _economyService.getQuizPerCredit(tier);
    int optimalFlashcards = _economyService.getFlashcardsPerCredit(tier);

    // Adjust based on topic difficulty
    switch (topicDifficulty) {
      case DifficultyLevel.beginner:
        optimalQuiz = (optimalQuiz * 0.7).round();
        optimalFlashcards = (optimalFlashcards * 0.8).round();
        break;
      case DifficultyLevel.advanced:
        optimalQuiz = (optimalQuiz * 1.2).round();
        optimalFlashcards = (optimalFlashcards * 1.3).round();
        break;
      case DifficultyLevel.intermediate:
      case DifficultyLevel.expert:
        // Use base values
        break;
    }

    // Adjust based on remaining credits for free users
    if (!_economyService.isPaidUser && _economyService.creditsRemaining < 2) {
      if (_economyService.creditsRemaining == 1) {
        // Only enough for one type
        optimalQuiz = optimalQuiz;
        optimalFlashcards = 0;
      } else {
        // No credits remaining
        optimalQuiz = 0;
        optimalFlashcards = 0;
      }
    }

    return {
      'quiz': optimalQuiz,
      'flashcards': optimalFlashcards,
    };
  }

  int get _totalCreditsNeeded {
    int credits = 0;
    if (_quizCount > 0) credits += 1;
    if (_flashcardCount > 0) credits += 1;
    return credits;
  }

  bool get _canGenerate {
    if (_totalCreditsNeeded == 0) return false;
    if (_economyService.isPaidUser) return true;
    return _economyService.creditsRemaining >= _totalCreditsNeeded;
  }

  String get _generateButtonText {
    if (_totalCreditsNeeded == 0) return 'Select at least one type';
    if (_totalCreditsNeeded == 1) return 'Generate (1 Credit)';
    return 'Generate ($_totalCreditsNeeded Credits)';
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        return Dialog(
          backgroundColor: tokens.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: tokens.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.tune,
                                color: tokens.primary,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customize Study Set',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose your quiz and flashcard counts',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isGenerating ? null : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: tokens.textSecondary,
                        ),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: tokens.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Calculating optimal counts...',
                                style: TextStyle(color: tokens.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _slideController,
                              curve: Curves.easeOutCubic,
                            )),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quiz Questions Slider
                                _buildSliderSection(
                                  'Quiz Questions',
                                  Icons.quiz,
                                  _quizCount,
                                  _optimalCounts['quiz'] ?? 0,
                                  (value) => setState(() {
                                    _quizCount = value.round();
                                    HapticFeedback.lightImpact();
                                  }),
                                ),
                                const SizedBox(height: 32),

                                // Flashcards Slider
                                _buildSliderSection(
                                  'Flashcards',
                                  Icons.style,
                                  _flashcardCount,
                                  _optimalCounts['flashcards'] ?? 0,
                                  (value) => setState(() {
                                    _flashcardCount = value.round();
                                    HapticFeedback.lightImpact();
                                  }),
                                ),
                                const SizedBox(height: 32),

                                // Credit Usage Display
                                _buildCreditUsageSection(),
                                const SizedBox(height: 32),

                                // Economy Status
                                _buildEconomyStatusSection(),
                              ],
                            ),
                          ),
                        ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isGenerating
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: AnimatedBuilder(
                          animation: _successAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isGenerating ? 0.95 : 1.0,
                              child: ElevatedButton(
                                onPressed: _canGenerate && !_isGenerating
                                    ? _onGenerate
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _canGenerate
                                      ? tokens.primary
                                      : tokens.borderMuted,
                                  foregroundColor: _canGenerate
                                      ? tokens.textInverse
                                      : tokens.textTertiary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: _canGenerate ? 2 : 0,
                                ),
                                child: _isGenerating
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: tokens.textInverse,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Generating...',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: tokens.textInverse,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _generateButtonText,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
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

  Widget _buildSliderSection(
    String title,
    IconData icon,
    int currentValue,
    int optimalValue,
    Function(double) onChanged,
  ) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: tokens.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                  ),
                  if (optimalValue > 0)
                    Text(
                      'Optimal: $optimalValue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.warning,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tokens.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                currentValue.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.primary,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: tokens.primary,
            inactiveTrackColor: tokens.borderMuted,
            thumbColor: tokens.primary,
            overlayColor: tokens.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: currentValue.toDouble(),
            min: 0,
            max: 50,
            divisions: 50,
            onChanged: onChanged,
          ),
        ),
        // Quick select buttons
        Row(
          children: [0, 5, 10, 15, 20, 25]
              .map(
                (count) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      onPressed: () {
                        onChanged(count.toDouble());
                        HapticFeedback.lightImpact();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        side: BorderSide(
                          color: currentValue == count
                              ? tokens.primary
                              : tokens.borderMuted,
                        ),
                        backgroundColor: currentValue == count
                            ? tokens.primary.withValues(alpha: 0.1)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: currentValue == count
                              ? tokens.primary
                              : tokens.textSecondary,
                          fontWeight: currentValue == count
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCreditUsageSection() {
    final tokens = context.tokens;
    final economy = _economyService.userEconomy;

    if (economy == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.borderMuted,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: tokens.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Credit Usage',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current credits
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available Credits:',
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
              Text(
                _economyService.isPaidUser
                    ? 'Unlimited'
                    : '${economy.creditsRemaining}/${economy.monthlyQuota}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _economyService.isPaidUser
                      ? tokens.success
                      : tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tier info
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Tier:',
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: economy.tier.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  economy.tier.displayName,
                  style: TextStyle(
                    color: economy.tier.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (_quizCount > 0 || _flashcardCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tokens.borderMuted,
                ),
              ),
              child: Column(
                children: [
                  // Quiz cost
                  if (_quizCount > 0) ...[
                    Row(
                      children: [
                        Icon(Icons.quiz, size: 16, color: tokens.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_quizCount Quiz Questions',
                            style: TextStyle(color: tokens.textPrimary),
                          ),
                        ),
                        Text(
                          '1 credit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Flashcard cost
                  if (_flashcardCount > 0) ...[
                    if (_quizCount > 0) const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.style, size: 16, color: tokens.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_flashcardCount Flashcards',
                            style: TextStyle(color: tokens.textPrimary),
                          ),
                        ),
                        Text(
                          '1 credit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tokens.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Total cost
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Cost:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tokens.textPrimary,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_totalCreditsNeeded Credit${_totalCreditsNeeded != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: tokens.textInverse,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEconomyStatusSection() {
    final tokens = context.tokens;
    final budgetState = _economyService.budgetState;

    if (budgetState == BudgetState.normal) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: budgetState == BudgetState.savingsMode
            ? tokens.warning.withValues(alpha: 0.1)
            : tokens.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: budgetState == BudgetState.savingsMode
              ? tokens.warning.withValues(alpha: 0.3)
              : tokens.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            budgetState == BudgetState.savingsMode
                ? Icons.warning_amber
                : Icons.pause_circle,
            color: budgetState == BudgetState.savingsMode
                ? tokens.warning
                : tokens.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              budgetState == BudgetState.savingsMode
                  ? 'Budget savings mode active - using efficient generation'
                  : 'Generation paused due to budget limits',
              style: TextStyle(
                color: budgetState == BudgetState.savingsMode
                    ? tokens.warning
                    : tokens.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerate() async {
    if (!_canGenerate) return;

    setState(() => _isGenerating = true);

    try {
      // Create generation request
      final request = GenerationRequest(
        sourceContent: widget.sourceContent ?? '',
        sourceCharCount: widget.sourceContent?.length ?? 0,
        isRecreate: false,
        lastAttemptFailed: false,
      );

      // Check if we can generate
      final enforcement = _economyService.canGenerateContent(request);
      if (!enforcement.canProceed) {
        _showErrorSnackBar(
            enforcement.blockReason ?? 'Cannot generate content');
        return;
      }

      // Use credits
      final creditsUsed =
          await _economyService.useCreditsForGeneration(request);
      if (!creditsUsed) {
        _showErrorSnackBar('Failed to consume credits for generation');
        return;
      }

      // Success animation
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 300));

      // Close dialog and call callback
      if (mounted) {
        Navigator.pop(context);
        widget.onGenerate(_quizCount, _flashcardCount);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Generation failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: context.tokens.textInverse),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: context.tokens.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

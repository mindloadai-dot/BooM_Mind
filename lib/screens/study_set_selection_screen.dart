import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/widgets/customize_study_set_dialog.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/theme.dart';

class StudySetSelectionScreen extends StatefulWidget {
  final Function(StudySet) onStudySetSelected;
  final String? sourceContent;
  final String? sourceTitle;

  const StudySetSelectionScreen({
    super.key,
    required this.onStudySetSelected,
    this.sourceContent,
    this.sourceTitle,
  });

  @override
  State<StudySetSelectionScreen> createState() =>
      _StudySetSelectionScreenState();
}

class _StudySetSelectionScreenState extends State<StudySetSelectionScreen>
    with TickerProviderStateMixin {
  final MindloadEconomyService _economyService =
      MindloadEconomyService.instance;
  List<StudySet> _savedStudySets = [];
  StudySet? _lastCustomSet;
  bool _isLoading = true;
  bool _isGenerating = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStudySets();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStudySets() async {
    try {
      final sets = await UnifiedStorageService.instance.getAllStudySets();
      // Note: getLastCustomStudySet method needs to be implemented in EnhancedStorageService
      // For now, we'll get the most recent study set
      final lastCustom = sets.isNotEmpty ? sets.first : null;

      setState(() {
        _savedStudySets = sets;
        _lastCustomSet = lastCustom;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: MindloadAppBarFactory.secondary(title: 'Select Study Set'),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: tokens.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading study sets...',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with brain icon
                      Center(
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color:
                                          tokens.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: tokens.primary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: BrainLogo(
                                      size: 40,
                                      color: tokens.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Choose your study material',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select from saved sets or create a new one',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Create New Custom Set Card
                      _buildCreateNewCard(),
                      const SizedBox(height: 24),

                      // Saved Study Sets Section
                      if (_savedStudySets.isNotEmpty) ...[
                        Text(
                          'Recent Study Sets',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _savedStudySets.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child:
                                    _buildStudySetCard(_savedStudySets[index]),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: tokens.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No saved study sets yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: tokens.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first study set to get started',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: tokens.textTertiary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCreateNewCard() {
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.borderMuted,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCustomizeDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add,
                    color: tokens.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Custom Set',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: tokens.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Design your own quiz and flashcard counts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tokens.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudySetCard(StudySet studySet) {
    final tokens = context.tokens;
    final totalItems =
        studySet.flashcards.length + studySet.quizQuestions.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderMuted,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onStudySetSelected(studySet),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStudySetColor(studySet).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStudySetIcon(studySet),
                    color: _getStudySetColor(studySet),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studySet.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalItems items • ${_formatDate(studySet.lastStudied)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: tokens.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStudySetColor(StudySet studySet) {
    final tokens = context.tokens;

    if (studySet.flashcards.isNotEmpty && studySet.quizQuestions.isNotEmpty) {
      return tokens.primary;
    } else if (studySet.flashcards.isNotEmpty) {
      return tokens.secondary;
    } else {
      return tokens.accent;
    }
  }

  IconData _getStudySetIcon(StudySet studySet) {
    if (studySet.flashcards.isNotEmpty && studySet.quizQuestions.isNotEmpty) {
      return Icons.auto_stories;
    } else if (studySet.flashcards.isNotEmpty) {
      return Icons.style;
    } else {
      return Icons.quiz;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showCustomizeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CustomizeStudySetDialog(
        topicDifficulty: 'medium',
        sourceContent: widget.sourceContent,
        onGenerate: (quizCount, flashcardCount) async {
          await _generateCustomStudySet(quizCount, flashcardCount);
        },
      ),
    );
  }

  Future<void> _generateCustomStudySet(
      int quizCount, int flashcardCount) async {
    setState(() => _isGenerating = true);

    try {
      // Create generation request
      final request = GenerationRequest(
        sourceContent: widget.sourceContent ?? '',
        sourceCharCount: widget.sourceContent?.length ?? 0,
        isRecreate: false,
        lastAttemptFailed: false,
      );

      // Check if user can generate this study set
      final enforcement = _economyService.canGenerateContent(request);
      if (!enforcement.canProceed) {
        _showErrorSnackBar(
            enforcement.blockReason ?? 'Cannot generate content');
        return;
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.tokens.textInverse,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Generating your custom study set...'),
                ),
              ],
            ),
            backgroundColor: context.tokens.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 10),
          ),
        );
      }

      // Use credits
      final creditsUsed =
          await _economyService.useCreditsForGeneration(request);
      if (!creditsUsed) {
        throw Exception('Failed to use credits');
      }

      // Generate sample study set (replace with actual generation logic)
      final studySet = StudySet(
        id: 'study_${DateTime.now().millisecondsSinceEpoch}',
        title: widget.sourceTitle ?? 'Custom Study Set',
        content: widget.sourceContent ?? '',
        flashcards: List.generate(
          flashcardCount,
          (index) => Flashcard(
            id: 'flashcard_$index',
            question: 'Sample question ${index + 1}?',
            answer: 'Sample answer ${index + 1}',
          ),
        ),
        quizQuestions: List.generate(
          quizCount,
          (index) => QuizQuestion(
            id: 'quiz_$index',
            question: 'Sample quiz question ${index + 1}?',
            options: ['Option A', 'Option B', 'Option C', 'Option D'],
            correctAnswer: 'Option A',
          ),
        ),
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        category: 'Custom',
        description: 'Custom generated study set',
        sourceType: 'text',
        sourceLength: widget.sourceContent?.length ?? 0,
        tags: ['custom', 'generated'],
        type: quizCount > 0 && flashcardCount > 0
            ? StudySetType.both
            : quizCount > 0
                ? StudySetType.quiz
                : StudySetType.flashcards,
      );

      // Save the study set
      await UnifiedStorageService.instance.addStudySet(studySet);

      // Reload study sets
      await _loadStudySets();

      // Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: context.tokens.textInverse),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Study set created successfully!'),
                ),
              ],
            ),
            backgroundColor: context.tokens.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to the new study set
        widget.onStudySetSelected(studySet);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to generate study set: ${e.toString()}');
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

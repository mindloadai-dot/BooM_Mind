import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/storage_service.dart';
import 'package:mindload/widgets/notification_settings_dialog.dart';
import 'package:mindload/services/pdf_export_service.dart';
import 'package:mindload/models/pdf_export_models.dart';
import 'package:mindload/services/notification_service.dart';
// Removed import: study_set_notification_service - service removed
import 'package:mindload/services/openai_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/accessible_components.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/services/achievement_tracker_service.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/services/haptic_feedback_service.dart';

class StudyScreen extends StatefulWidget {
  final StudySet studySet;
  final bool isUltraMode;

  const StudyScreen(
      {super.key, required this.studySet, this.isUltraMode = false});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;

  // Enhanced animation controllers
  late AnimationController _flipController;
  late AnimationController _cardSlideController;
  late AnimationController _quizSlideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _bounceController;
  late AnimationController _scaleController;

  // Enhanced animations
  late Animation<double> _flipAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<Offset> _quizSlideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  bool _showAnswer = false;
  int _currentCardIndex = 0;
  bool _isLoading = false;

  // Quiz state
  Quiz? _currentQuiz;
  int _currentQuestionIndex = 0;
  List<String> _userAnswers = [];
  bool _showResults = false;
  bool _isAnswerRevealed = false;
  late DateTime _quizStartTime;

  // Study set reference (to handle updates)
  late StudySet _currentStudySet;
  late DateTime _studyStartTime; // Track when study session starts

  @override
  void initState() {
    super.initState();
    _currentStudySet = widget.studySet;
    _studyStartTime = DateTime.now(); // Track when study session starts

    // Initialize enhanced animation controllers
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardSlideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _quizSlideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize enhanced animations with improved curves
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardSlideController,
      curve: Curves.easeOutQuart,
    ));

    _quizSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _quizSlideController,
      curve: Curves.easeOutQuart,
    ));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Track study session when user starts studying
    _trackStudySession();

    // Start all animations with staggered timing for smooth entrance
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardSlideController.forward();
      if (kDebugMode) debugPrint('🎬 Card slide animation started');
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _quizSlideController.forward();
      if (kDebugMode) debugPrint('🎬 Quiz slide animation started');
    });

    // Start shimmer animation
    _shimmerController.repeat();
    if (kDebugMode) debugPrint('🎬 All animations initialized successfully');

    // Add animation status listeners for debugging
    if (kDebugMode) {
      _cardSlideController.addStatusListener((status) {
        debugPrint('🎬 Card slide animation status: $status');
      });
      _quizSlideController.addStatusListener((status) {
        debugPrint('🎬 Quiz slide animation status: $status');
      });
      _bounceController.addStatusListener((status) {
        debugPrint('🎬 Bounce animation status: $status');
      });
    }

    // Log screen access for telemetry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TelemetryService.instance.logEvent(
        'screen_accessed',
        {
          'screen_name': 'study_screen',
          'study_set_id': _currentStudySet.id,
          'has_flashcards': _currentStudySet.flashcards.isNotEmpty,
          'has_quizzes': _currentStudySet.quizzes.isNotEmpty,
          'flashcard_count': _currentStudySet.flashcards.length,
          'quiz_count': _currentStudySet.quizzes.length,
        },
      );
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _cardSlideController.dispose();
    _quizSlideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _bounceController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedbackService().lightImpact();
    if (!_showAnswer) {
      _flipController.forward();
      _bounceController.forward().then((_) => _bounceController.reverse());
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _nextCard() {
    if (_currentCardIndex < _currentStudySet.flashcards.length - 1) {
      HapticFeedbackService().lightImpact();
      setState(() {
        _currentCardIndex++;
        _showAnswer = false;
      });
      _flipController.reset();
      // Trigger card slide animation with proper timing
      _cardSlideController.reset();
      _cardSlideController.forward();
      _scaleController.forward();
      // Trigger bounce animation for visual feedback
      _bounceController.forward().then((_) => _bounceController.reverse());
      if (kDebugMode) debugPrint('🎬 Next card animations triggered');
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      HapticFeedbackService().lightImpact();
      setState(() {
        _currentCardIndex--;
        _showAnswer = false;
      });
      _flipController.reset();
      // Trigger card slide animation with proper timing
      _cardSlideController.reset();
      _cardSlideController.forward();
      _scaleController.forward();
      // Trigger bounce animation for visual feedback
      _bounceController.forward().then((_) => _bounceController.reverse());
      if (kDebugMode) debugPrint('🎬 Previous card animations triggered');
    }
  }

  void _startQuiz(Quiz quiz) {
    HapticFeedbackService().mediumImpact();
    setState(() {
      _currentQuiz = quiz;
      _currentQuestionIndex = 0;
      _userAnswers = [];
      _showResults = false;
      _isAnswerRevealed = false;
      _quizStartTime = DateTime.now(); // Track when quiz starts
    });

    // Start animations for quiz start with proper timing
    _quizSlideController.reset();
    _quizSlideController.forward();
    _scaleController.forward();
    _pulseController.repeat();
    // Trigger bounce animation for visual feedback
    _bounceController.forward().then((_) => _bounceController.reverse());
    if (kDebugMode) debugPrint('🎬 Quiz start animations triggered');

    // Track quiz start for achievements
    _trackQuizStart(quiz);
  }

  /// Track quiz start for achievements
  void _trackQuizStart(Quiz quiz) {
    try {
      // For now, we'll just log the quiz start
      // In a future implementation, this could be tracked through a proper service
      if (kDebugMode) {
        debugPrint(
            'Quiz start tracked for achievements: ${quiz.title} (${quiz.questions.length} questions)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to track quiz start: $e');
      }
    }
  }

  void _submitAnswer(String answer) {
    HapticFeedbackService().selectionClick();
    try {
      if (_currentQuiz == null || _currentQuiz!.questions.isEmpty) {
        _showErrorSnackBar('Invalid quiz state');
        return;
      }

      setState(() {
        _userAnswers.add(answer);
        _isAnswerRevealed = false; // Reset reveal state for next question
        if (_currentQuestionIndex < _currentQuiz!.questions.length - 1) {
          _currentQuestionIndex++;
          // Animate to next question with proper timing
          _quizSlideController.reset();
          _quizSlideController.forward();
          _scaleController.forward();
          // Trigger bounce animation for visual feedback
          _bounceController.forward().then((_) => _bounceController.reverse());
          if (kDebugMode) {
            debugPrint('🎬 Quiz question transition animations triggered');
          }
        } else {
          _finishQuiz();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to submit answer: ${e.toString()}');
    }
  }

  void _finishQuiz() {
    HapticFeedbackService().success();
    final Quiz quiz = _currentQuiz!;
    int correctAnswers = 0;
    final List<String> incorrectQuestions = [];

    for (int i = 0; i < quiz.questions.length; i++) {
      if (_userAnswers[i] == quiz.questions[i].correctAnswer) {
        correctAnswers++;
      } else {
        incorrectQuestions.add(quiz.questions[i].id);
      }
    }

    final QuizResult result = QuizResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      score: correctAnswers,
      totalQuestions: quiz.questions.length,
      timeTaken: DateTime.now().difference(_quizStartTime),
      completedDate: DateTime.now(),
      incorrectAnswers: incorrectQuestions,
    );

    StorageService.instance.addQuizResult(result);

    setState(() {
      _showResults = true;
    });
  }

  void _resetQuiz() {
    HapticFeedbackService().lightImpact();
    setState(() {
      _currentQuiz = null;
      _showResults = false;
      _isAnswerRevealed = false;
    });
  }

  void _revealAnswer() {
    HapticFeedbackService().lightImpact();
    setState(() {
      _isAnswerRevealed = true;
    });
    // Trigger animations for answer reveal
    _bounceController.forward().then((_) => _bounceController.reverse());
    _pulseController.forward().then((_) => _pulseController.reverse());
    if (kDebugMode) debugPrint('🎬 Answer reveal animations triggered');
  }

  Future<void> _handleStudySetAction(String action) async {
    switch (action) {
      case 'notifications':
        _showNotificationSettings();
        break;
      case 'rename':
        _showRenameDialog();
        break;
      case 'refresh':
        await _refreshStudySet();
        break;
      case 'generate_more_quizzes':
        _showGenerateMoreDialog(StudySetType.quiz);
        break;
      case 'generate_more_flashcards':
        _showGenerateMoreDialog(StudySetType.flashcards);
        break;
      case 'generate_more_both':
        _showGenerateMoreDialog(StudySetType.both);
        break;
      case 'export_flashcards':
        await _exportFlashcards();
        break;
      case 'export_quizzes':
        await _exportQuizzes();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => NotificationSettingsDialog(
        studySet: _currentStudySet,
        onUpdateStudySet: _updateStudySet,
      ),
    );
  }

  Future<void> _updateStudySet(StudySet updatedStudySet) async {
    try {
      // Update the full study set to preserve all data including notificationsEnabled
      await StorageService.instance.updateFullStudySet(updatedStudySet);

      setState(() {
        _currentStudySet = updatedStudySet;
      });

      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Text('Notification settings updated'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update study set: $e');
      }
      _showErrorSnackBar('Failed to update notification settings');
    }
  }

  Future<void> _exportFlashcards() async {
    if (_currentStudySet.flashcards.isEmpty) {
      _showErrorSnackBar('No flashcards to export');
      return;
    }

    try {
      // Use the new PDF export system with MindLoad branding
      final pdfService = PdfExportService();
      final options = PdfExportOptions(
        setId: _currentStudySet.id,
        includeFlashcards: true,
        includeQuiz: false,
        style: 'standard',
        pageSize: 'Letter',
        includeMindloadBranding: true, // Default to including branding
      );

      final result = await pdfService.exportToPdf(
        uid: pdfService.getCurrentUserId(),
        setId: _currentStudySet.id,
        appVersion: pdfService.getAppVersion(),
        itemCounts: {'flashcards': _currentStudySet.flashcards.length},
        options: options,
        onProgress: (progress) {
          // Update progress in UI
          if (kDebugMode) {
            debugPrint('Export progress: ${progress.percentage}%');
          }
        },
        onCancelled: () {
          if (kDebugMode) {
            debugPrint('Export cancelled');
          }
        },
      );

      if (result.success) {
        // Show success message
        final tokens = context.tokens;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: tokens.onPrimary),
                const SizedBox(width: Spacing.sm),
                Text('Flashcards PDF exported successfully!'),
              ],
            ),
            backgroundColor: tokens.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open PDF viewer
                if (kDebugMode) {
                  debugPrint('Open PDF: ${result.filePath}');
                }
              },
            ),
          ),
        );
      } else {
        throw Exception('Export failed: ${result.errorMessage}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export flashcards: ${e.toString()}');
    }
  }

  Future<void> _exportQuizzes() async {
    if (_currentStudySet.quizzes.isEmpty) {
      _showErrorSnackBar('No quizzes to export');
      return;
    }

    try {
      // Use the new PDF export system with MindLoad branding
      final pdfService = PdfExportService();
      final options = PdfExportOptions(
        setId: _currentStudySet.id,
        includeFlashcards: false,
        includeQuiz: true,
        style: 'standard',
        pageSize: 'Letter',
        includeMindloadBranding: true, // Default to including branding
      );

      final result = await pdfService.exportToPdf(
        uid: pdfService.getCurrentUserId(),
        setId: _currentStudySet.id,
        appVersion: pdfService.getAppVersion(),
        itemCounts: {'quizzes': _currentStudySet.quizzes.length},
        options: options,
        onProgress: (progress) {
          // Update progress in UI
          if (kDebugMode) {
            debugPrint('Export progress: ${progress.percentage}%');
          }
        },
        onCancelled: () {
          if (kDebugMode) {
            debugPrint('Export cancelled');
          }
        },
      );

      if (result.success) {
        // Show success message
        final tokens = context.tokens;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: tokens.onPrimary),
                const SizedBox(width: Spacing.sm),
                Text('Quiz PDF exported successfully!'),
              ],
            ),
            backgroundColor: tokens.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open PDF viewer
                if (kDebugMode) {
                  debugPrint('Open PDF: ${result.filePath}');
                }
              },
            ),
          ),
        );
      } else {
        throw Exception('Export failed: ${result.errorMessage}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export quizzes: ${e.toString()}');
    }
  }

  void _showDeleteConfirmation() {
    final tokens = context.tokens;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: tokens.error),
            const SizedBox(width: Spacing.sm),
            Text(
              'DELETE STUDY SET',
              style: TextStyle(
                color: tokens.error,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_currentStudySet.title}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
              ),
        ),
        actions: [
          AccessibleButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
            semanticLabel: 'Cancel delete operation',
            child: const Text('CANCEL'),
          ),
          AccessibleButton(
            onPressed: _deleteStudySet,
            variant: ButtonVariant.primary,
            semanticLabel: 'Confirm delete study set',
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudySet() async {
    Navigator.pop(context); // Close dialog

    try {
      // Cancel any scheduled notifications
      await NotificationService.instance.cancelAllNotifications();

      // Delete from storage
      await StorageService.instance.deleteStudySet(_currentStudySet.id);

      // Navigate back to home
      Navigator.pop(context);

      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Text('Study set deleted successfully'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to delete study set');
    }
  }

  void _showRenameDialog() {
    final tokens = context.tokens;
    final renameController =
        TextEditingController(text: _currentStudySet.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: tokens.primary),
            const SizedBox(width: Spacing.sm),
            Text(
              'RENAME STUDY SET',
              style: TextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: AccessibleTextInput(
          controller: renameController,
          labelText: 'Study Set Name',
          semanticLabel: 'Enter new study set name',
        ),
        actions: [
          AccessibleButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
            semanticLabel: 'Cancel rename operation',
            child: const Text('CANCEL'),
          ),
          AccessibleButton(
            onPressed: () => _renameStudySet(renameController.text),
            variant: ButtonVariant.primary,
            semanticLabel: 'Confirm rename study set',
            child: const Text('RENAME'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameStudySet(String newTitle) async {
    Navigator.pop(context); // Close dialog

    if (newTitle.trim().isEmpty) {
      _showErrorSnackBar('Study set name cannot be empty');
      return;
    }

    try {
      final updatedStudySet = _currentStudySet.copyWith(title: newTitle.trim());
      await StorageService.instance
          .updateStudySet(updatedStudySet.toMetadata());

      setState(() {
        _currentStudySet = updatedStudySet;
      });

      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Text('Study set renamed successfully'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to rename study set');
    }
  }

  Future<void> _refreshStudySet() async {
    setState(() => _isLoading = true);

    try {
      // Show loading indicator
      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.onPrimary),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text('Refreshing study set with AI...'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );

      // Import OpenAI service and subscription service
      final openAIService = OpenAIService.instance;

      // Strong haptic feedback to indicate AI processing start
      HapticFeedbackService().heavyImpact();

      // Generate new flashcards and quizzes using the original content
      final newFlashcards = await openAIService.generateFlashcards(_currentStudySet.content, count: 10);
      final newQuizQuestions = await openAIService.generateQuiz(_currentStudySet.content, count: 10);

      // Create a Quiz from the quiz questions
      final newQuiz = Quiz(
        id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
        title: '${_currentStudySet.title} Quiz',
        questions: newQuizQuestions,
        type: QuizType.multipleChoice,
        results: [],
        createdDate: DateTime.now(),
      );

      // Update the study set with new content
      final updatedStudySet = _currentStudySet.copyWith(
        flashcards: newFlashcards,
        quizzes: newQuizQuestions.isNotEmpty ? [newQuiz] : const <Quiz>[],
        lastStudied: DateTime.now(),
      );

      await StorageService.instance
          .updateStudySet(updatedStudySet.toMetadata());

      setState(() {
        _currentStudySet = updatedStudySet;
        // Reset current positions
        _currentCardIndex = 0;
        _showAnswer = false;
        _currentQuiz = null;
        _showResults = false;
        _isAnswerRevealed = false;
      });

      // Hide loading and show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child:
                    Text('Study set refreshed with new AI-generated content!'),
              ),
            ],
          ),
          backgroundColor: tokens.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar('Failed to refresh study set: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showGenerateMoreDialog(StudySetType type) {
    final tokens = context.tokens;
    final economyService = MindloadEconomyService.instance;

    // Default values - use reasonable defaults since we don't have last used counts
    int quizCount = type == StudySetType.flashcards ? 0 : 5;
    int flashcardCount = type == StudySetType.quiz ? 0 : 10;

    final quizController = TextEditingController(text: quizCount.toString());
    final flashcardController =
        TextEditingController(text: flashcardCount.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final creditsNeeded =
              _calculateCreditsForGeneration(type, quizCount, flashcardCount);
          final canGenerate = economyService.hasCredits;

          return AlertDialog(
            backgroundColor: tokens.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline, color: tokens.primary),
                const SizedBox(width: Spacing.sm),
                Flexible(
                  child: Text(
                    'GENERATE MORE CONTENT',
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type != StudySetType.flashcards) ...[
                  AccessibleTextInput(
                    controller: quizController,
                    labelText: 'Number of Quizzes',
                    keyboardType: TextInputType.number,
                    semanticLabel: 'Enter number of quiz questions to generate',
                    onChanged: (value) {
                      setDialogState(() {
                        quizCount = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                if (type != StudySetType.quiz) ...[
                  AccessibleTextInput(
                    controller: flashcardController,
                    labelText: 'Number of Flashcards',
                    keyboardType: TextInputType.number,
                    semanticLabel: 'Enter number of flashcards to generate',
                    onChanged: (value) {
                      setDialogState(() {
                        flashcardCount = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: Spacing.md),
                ],

                // Credit information
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tokens.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: tokens.primary,
                            size: 20,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            'CREDIT COST',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: tokens.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'This will use:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: tokens.textPrimary,
                                ),
                          ),
                          Text(
                            economyService.isPaidUser
                                ? 'No cost (Premium)'
                                : '$creditsNeeded credit${creditsNeeded != 1 ? 's' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: economyService.isPaidUser
                                      ? tokens.secondary
                                      : tokens.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      if (!economyService.isPaidUser) ...[
                        const SizedBox(height: Spacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Credits remaining:',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                            ),
                            Text(
                              '${economyService.creditsRemaining}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: canGenerate
                                        ? tokens.secondary
                                        : tokens.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      if (!canGenerate) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          'Insufficient credits for this generation',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.error,
                                    fontStyle: FontStyle.italic,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              AccessibleButton(
                onPressed: () => Navigator.pop(context),
                variant: ButtonVariant.text,
                semanticLabel: 'Cancel generation',
                child: const Text('CANCEL'),
              ),
              AccessibleButton(
                onPressed: canGenerate
                    ? () =>
                        _generateMoreContent(type, quizCount, flashcardCount)
                    : null,
                variant: ButtonVariant.primary,
                disabled: !canGenerate,
                semanticLabel: canGenerate
                    ? 'Confirm generation of additional content'
                    : 'Cannot generate - insufficient credits',
                child: const Text('GENERATE'),
              ),
            ],
          );
        },
      ),
    );
  }

  int _calculateCreditsForGeneration(
      StudySetType type, int quizCount, int flashcardCount) {
    // All generation types cost 1 credit in the new economy system
    return 1;
  }

  Future<void> _generateMoreContent(
      StudySetType type, int quizCount, int flashcardCount) async {
    Navigator.pop(context); // Close dialog

    final economyService = MindloadEconomyService.instance;

    // Check if user can generate content
    final request = GenerationRequest(
      sourceContent: _currentStudySet.content,
      sourceCharCount: _currentStudySet.content.length,
    );

    final enforcement = economyService.canGenerateContent(request);
    if (!enforcement.canProceed) {
      _showErrorSnackBar(
          enforcement.blockReason ?? 'Cannot generate additional content');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Show loading indicator
      final tokens = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.onPrimary),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Text('Generating additional content with AI...'),
            ],
          ),
          backgroundColor: tokens.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 10),
        ),
      );

      // Use credits for generation
      final creditsUsed = await economyService.useCreditsForGeneration(request);
      if (!creditsUsed) {
        throw Exception('Failed to consume credits for generation');
      }

      final openAIService = OpenAIService.instance;
      List<Flashcard> newFlashcards = <Flashcard>[];
      List<Quiz> newQuizzes = <Quiz>[];

      // Strong haptic feedback to indicate AI processing start
      HapticFeedbackService().heavyImpact();

      // Generate new content based on type
      if (type == StudySetType.flashcards || type == StudySetType.both) {
        newFlashcards = await openAIService.generateFlashcards(
          _currentStudySet.content,
          count: flashcardCount,
        );
      }

      if (type == StudySetType.quiz || type == StudySetType.both) {
        final newQuizQuestions = await openAIService.generateQuiz(
          _currentStudySet.content,
          count: quizCount,
        );
        if (newQuizQuestions.isNotEmpty) {
          final newQuiz = Quiz(
            id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
            title: '${_currentStudySet.title} Quiz',
            questions: newQuizQuestions,
            type: QuizType.multipleChoice,
            results: [],
            createdDate: DateTime.now(),
          );
          newQuizzes.add(newQuiz);
        }
      }

      // Add new content to existing study set
      final updatedFlashcards = [
        ..._currentStudySet.flashcards,
        ...newFlashcards
      ];
      final updatedQuizzes = [..._currentStudySet.quizzes, ...newQuizzes];

      final updatedStudySet = _currentStudySet.copyWith(
        flashcards: updatedFlashcards,
        quizzes: updatedQuizzes,
        lastStudied: DateTime.now(),
      );

      await StorageService.instance
          .updateStudySet(updatedStudySet.toMetadata());

      setState(() {
        _currentStudySet = updatedStudySet;
        // Reset states if needed
        if (_currentCardIndex >= updatedFlashcards.length) {
          _currentCardIndex = 0;
        }
      });

      // Haptic feedback for successful AI generation completion
      HapticFeedbackService().success();

      // Hide loading and show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: tokens.onPrimary),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  'Generated ${newFlashcards.length} flashcards and ${newQuizzes.fold(0, (sum, quiz) => sum + quiz.questions.length)} quiz questions!',
                ),
              ),
            ],
          ),
          backgroundColor: tokens.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // Haptic feedback for AI generation failure
      HapticFeedbackService().error();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar(
          'Failed to generate additional content: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SafeAreaWrapper(
      screenName: 'study_screen',
      child: Scaffold(
        appBar: MindloadAppBarFactory.secondary(
          title: _currentStudySet.title.toUpperCase(),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: tokens.primary,
              ),
              color: tokens.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: _handleStudySetAction,
              tooltip: 'Study set options',
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(
                        _currentStudySet.notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: tokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Notifications',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: tokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Rename Set',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: tokens.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Refresh Set',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'generate_more_quizzes',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: tokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Generate More Quizzes',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'generate_more_flashcards',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: tokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Generate More Flashcards',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'generate_more_both',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: tokens.primary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Generate More Both',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export_flashcards',
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: tokens.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Export Flashcards',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export_quizzes',
                  child: Row(
                    children: [
                      Icon(
                        Icons.quiz,
                        color: tokens.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Export Quizzes',
                        style: TextStyle(color: tokens.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        color: tokens.error,
                        size: 20,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Delete',
                        style: TextStyle(color: tokens.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _currentQuiz != null ? _buildQuizView() : _buildMainView(),
      ),
    );
  }

  Widget _buildMainView() {
    final tokens = context.tokens;
    return Column(
      children: [
        // Tab selector (fixed position at top)
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: AccessibleCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            semanticLabel: 'Study mode selector',
            child: Container(
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tokens.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  _buildTabButton('FLASHCARDS', 0),
                  _buildTabButton('QUIZZES', 1),
                ],
              ),
            ),
          ),
        ),

        // Tab content (scrollable)
        Expanded(
          child: Builder(
            builder: (context) {
              try {
                return _selectedTabIndex == 0
                    ? _buildFlashcardsTab()
                    : _buildQuizzesTab();
              } catch (e) {
                return Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: context.tokens.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CONTENT ERROR',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: context.tokens.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load content. Please try refreshing.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AccessibleButton(
                          onPressed: () => setState(() {}),
                          variant: ButtonVariant.primary,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    final tokens = context.tokens;
    return Expanded(
      child: AccessibleButton(
        onPressed: () {
          try {
            setState(() {
              _selectedTabIndex = index;
              // Reset any active quiz when switching tabs
              if (_currentQuiz != null) {
                _currentQuiz = null;
                _showResults = false;
                _isAnswerRevealed = false;
              }
            });
          } catch (e) {
            _showErrorSnackBar('Failed to switch tab: ${e.toString()}');
          }
        },
        variant: isSelected ? ButtonVariant.primary : ButtonVariant.text,
        semanticLabel: '${isSelected ? 'Current' : 'Switch to'} $title mode',
        fullWidth: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isSelected ? tokens.onPrimary : tokens.textPrimary,
              ),
        ),
      ),
    );
  }

  Widget _buildFlashcardsTab() {
    final tokens = context.tokens;

    try {
      if (_currentStudySet.flashcards.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 80,
                color: tokens.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'NO FLASHCARDS AVAILABLE',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Use the menu to generate flashcards',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      // Validate current card index
      if (_currentCardIndex >= _currentStudySet.flashcards.length) {
        setState(() {
          _currentCardIndex = 0;
        });
        return const Center(child: CircularProgressIndicator());
      }

      final Flashcard currentCard =
          _currentStudySet.flashcards[_currentCardIndex];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            // Progress indicator
            Semantics(
              label:
                  'Progress: Card ${_currentCardIndex + 1} of ${_currentStudySet.flashcards.length}',
              child: LinearProgressIndicator(
                value: (_currentCardIndex + 1) /
                    _currentStudySet.flashcards.length,
                backgroundColor: tokens.primary.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                minHeight: 4,
              ),
            ),

            const SizedBox(height: Spacing.md),

            Text(
              'CARD ${_currentCardIndex + 1} OF ${_currentStudySet.flashcards.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.textPrimary,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: Spacing.lg),

            // Debug animation values
            if (kDebugMode)
              Builder(
                builder: (context) {
                  debugPrint(
                      '🎬 Card slide animation value: ${_cardSlideAnimation.value}');
                  debugPrint(
                      '🎬 Scale animation value: ${_scaleAnimation.value}');
                  return const SizedBox.shrink();
                },
              ),

            // Enhanced Animated Flashcard
            SizedBox(
              height: 500, // Increased height for better content display
              child: Center(
                child: SlideTransition(
                  position: _cardSlideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final isShowingFront = _flipAnimation.value < 0.5;
                          // Debug animation values in debug mode
                          if (kDebugMode) {
                            debugPrint(
                                '🎬 Flip animation value: ${_flipAnimation.value}');
                          }
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_flipAnimation.value *
                                  3.14159), // Full 180-degree rotation
                            child: Container(
                              width: double.infinity,
                              height:
                                  400, // Increased height for better content
                              decoration: BoxDecoration(
                                color: tokens.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: tokens.borderDefault,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: tokens.overlayDim,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Shimmer effect overlay
                                  if (!_showAnswer)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _shimmerAnimation,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              _shimmerAnimation.value * 400 -
                                                  200,
                                              0,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    Colors.transparent,
                                                    tokens.primary
                                                        .withValues(alpha: 0.1),
                                                    Colors.transparent,
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                  // Main content
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..rotateY(isShowingFront ? 0 : 3.14159),
                                    child: Padding(
                                      padding: const EdgeInsets.all(Spacing.lg),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .start, // Changed to start for better content flow
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center, // Center horizontally
                                        children: [
                                          // Animated icon with pulse effect
                                          AnimatedBuilder(
                                            animation: _pulseAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: 1.0,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: tokens.surfaceAlt,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                      color:
                                                          tokens.borderDefault,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.quiz,
                                                    color: tokens.primary,
                                                    size: 36,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          const SizedBox(height: Spacing.md),

                                          // Animated label with bounce effect
                                          AnimatedBuilder(
                                            animation: _bounceAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: _showAnswer
                                                    ? _bounceAnimation.value
                                                    : 1.0,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: tokens.primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: tokens.primary
                                                          .withValues(
                                                              alpha: 0.2),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _showAnswer
                                                        ? 'ANSWER'
                                                        : 'QUESTION',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color: tokens.primary,
                                                          letterSpacing: 1.5,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          const SizedBox(
                                              height: Spacing
                                                  .md), // Reduced spacing

                                          // Content with enhanced typography and better long text handling
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              constraints: const BoxConstraints(
                                                minHeight:
                                                    120, // Minimum height for short content
                                                maxHeight:
                                                    300, // Maximum height for long content
                                              ),
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: tokens.surfaceAlt,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: tokens.borderDefault,
                                                ),
                                              ),
                                              child: SingleChildScrollView(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: Text(
                                                    _showAnswer
                                                        ? currentCard.answer
                                                        : currentCard.question,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          color: tokens
                                                              .textPrimary,
                                                          height:
                                                              1.5, // Increased line height for readability
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                    maxLines:
                                                        null, // Allow unlimited lines
                                                    overflow: TextOverflow
                                                        .visible, // Show all text
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AccessibleButton(
                  onPressed: _currentCardIndex > 0 ? _previousCard : null,
                  variant: ButtonVariant.secondary,
                  disabled: _currentCardIndex <= 0,
                  semanticLabel: 'Go to previous flashcard',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: Spacing.xs),
                      Text('PREV'),
                    ],
                  ),
                ),
                AccessibleButton(
                  onPressed: _flipCard,
                  variant: ButtonVariant.primary,
                  semanticLabel: _showAnswer ? 'Hide answer' : 'Reveal answer',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_showAnswer
                          ? Icons.visibility_off
                          : Icons.visibility),
                      const SizedBox(width: Spacing.xs),
                      Text(_showAnswer ? 'HIDE' : 'REVEAL'),
                    ],
                  ),
                ),
                AccessibleButton(
                  onPressed:
                      _currentCardIndex < _currentStudySet.flashcards.length - 1
                          ? _nextCard
                          : null,
                  variant: ButtonVariant.secondary,
                  disabled: _currentCardIndex >=
                      _currentStudySet.flashcards.length - 1,
                  semanticLabel: 'Go to next flashcard',
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('NEXT'),
                      SizedBox(width: Spacing.xs),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: tokens.error,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'FLASHCARDS ERROR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Error loading flashcards: ${e.toString()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.md),
              AccessibleButton(
                onPressed: () => setState(() {}),
                variant: ButtonVariant.primary,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildQuizzesTab() {
    final tokens = context.tokens;

    try {
      if (_currentStudySet.quizzes.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: tokens.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'NO QUIZZES AVAILABLE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  semanticsLabel: 'No quizzes available in this study set',
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Use the menu to generate quiz questions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: _currentStudySet.quizzes.length,
        itemBuilder: (context, index) {
          final Quiz quiz = _currentStudySet.quizzes[index];
          final int? bestScore = quiz.results.isNotEmpty
              ? quiz.results
                  .map((r) => r.percentage)
                  .reduce((a, b) => a > b ? a : b)
                  .toInt()
              : null;

          return AccessibleCard(
            onTap: quiz.questions.isNotEmpty
                ? () {
                    try {
                      _startQuiz(quiz);
                    } catch (e) {
                      _showErrorSnackBar(
                          'Failed to start quiz: ${e.toString()}');
                    }
                  }
                : null,
            margin: const EdgeInsets.only(bottom: Spacing.md),
            semanticLabel:
                'Quiz: ${quiz.title}. ${quiz.questions.length} questions. ${_getQuizTypeLabel(quiz.type)}. ${bestScore != null ? 'Best score $bestScore percent.' : 'Not attempted yet.'} ${quiz.questions.isEmpty ? 'Quiz has no questions.' : 'Tap to start.'}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      color: tokens.primary,
                      size: 24,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        quiz.title.toUpperCase(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Text(
                      '${quiz.questions.length} Questions • ${_getQuizTypeLabel(quiz.type)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: quiz.questions.isEmpty
                                ? tokens.error
                                : tokens.textSecondary,
                          ),
                    ),
                    if (quiz.questions.isEmpty) ...[
                      const SizedBox(width: Spacing.xs),
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: tokens.error,
                      ),
                    ],
                  ],
                ),
                if (bestScore != null) ...[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Best Score: $bestScore%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.primary,
                        ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: tokens.error,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'QUIZZES ERROR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.error,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Error loading quizzes: ${e.toString()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.md),
              AccessibleButton(
                onPressed: () => setState(() {}),
                variant: ButtonVariant.primary,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildQuizView() {
    if (_showResults) {
      return _buildQuizResults();
    }

    // Validate quiz state before building UI
    if (_currentQuiz == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.tokens.error,
            ),
            const SizedBox(height: 16),
            Text(
              'QUIZ ERROR',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.tokens.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No quiz loaded. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AccessibleButton(
              onPressed: () => setState(() {
                _currentQuiz = null;
                _showResults = false;
              }),
              variant: ButtonVariant.primary,
              child: const Text('BACK TO STUDY'),
            ),
          ],
        ),
      );
    }

    if (_currentQuiz!.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: context.tokens.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'NO QUESTIONS AVAILABLE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            AccessibleButton(
              onPressed: () => setState(() {
                _currentQuiz = null;
                _showResults = false;
              }),
              variant: ButtonVariant.primary,
              child: const Text('BACK TO STUDY'),
            ),
          ],
        ),
      );
    }

    // Validate question index
    if (_currentQuestionIndex >= _currentQuiz!.questions.length) {
      setState(() {
        _currentQuestionIndex = 0;
      });
      return const Center(child: CircularProgressIndicator());
    }

    final tokens = context.tokens;
    final question = _currentQuiz!.questions[_currentQuestionIndex];

    return Column(
      children: [
        // Fixed header with progress
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            children: [
              // Progress
              Semantics(
                label:
                    'Quiz progress: Question ${_currentQuestionIndex + 1} of ${_currentQuiz!.questions.length}',
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) /
                      _currentQuiz!.questions.length,
                  backgroundColor: tokens.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                  minHeight: 4,
                ),
              ),

              const SizedBox(height: Spacing.md),

              Text(
                'QUESTION ${_currentQuestionIndex + 1} OF ${_currentQuiz!.questions.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.primary,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Column(
              children: [
                const SizedBox(height: Spacing.lg),

                // Enhanced Animated Question
                SlideTransition(
                  position: _quizSlideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: Spacing.lg),
                      constraints: BoxConstraints(
                        minHeight: 150, // Reduced minimum for short questions
                        maxHeight: _calculateQuestionHeight(question
                            .question), // Dynamic height based on content
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tokens.borderDefault,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tokens.overlayDim,
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: Column(
                          children: [
                            // Animated question icon
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: tokens.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: tokens.borderDefault,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.quiz,
                                      color: tokens.primary,
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: Spacing.md),

                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: 0.98 +
                                            (_pulseAnimation.value *
                                                0.02), // Subtle pulse effect
                                        child: Text(
                                          question.question,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: tokens.textPrimary,
                                                height:
                                                    1.5, // Increased line height for readability
                                                fontWeight: FontWeight.w600,
                                              ),
                                          textAlign: TextAlign.center,
                                          maxLines:
                                              null, // Allow unlimited lines
                                          overflow: TextOverflow
                                              .visible, // Show all text
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reveal Answer Button
                if (!_isAnswerRevealed)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: AccessibleButton(
                      onPressed: _revealAnswer,
                      variant: ButtonVariant.outline,
                      semanticLabel: 'Reveal correct answer for this question',
                      fullWidth: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: tokens.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            'REVEAL ANSWER',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: tokens.secondary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Revealed Answer
                if (_isAnswerRevealed) ...[
                  AccessibleCard(
                    margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    padding: const EdgeInsets.all(Spacing.md),
                    semanticLabel:
                        'Correct answer revealed: ${question.correctAnswer}',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: tokens.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              'CORRECT ANSWER:',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: tokens.secondary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          question.correctAnswer,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '(Answer revealed - this won\'t affect scoring if you select manually)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 16),

                // Answer options
                Column(
                  children: [
                    // Debug information
                    if (question.options.isEmpty)
                      AccessibleCard(
                        margin: const EdgeInsets.only(bottom: Spacing.sm),
                        semanticLabel:
                            'Warning: No answer options available for this question',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: tokens.error,
                                  size: 20,
                                ),
                                const SizedBox(width: Spacing.xs),
                                Text(
                                  'NO OPTIONS AVAILABLE',
                                  style: TextStyle(
                                    color: tokens.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Quiz Type: ${question.type.name}\nCorrect Answer: ${question.correctAnswer}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: Spacing.sm),
                            // Show manual answer button as fallback
                            AccessibleButton(
                              onPressed: () =>
                                  _submitAnswer(question.correctAnswer),
                              variant: ButtonVariant.primary,
                              semanticLabel:
                                  'Submit correct answer: ${question.correctAnswer}',
                              child: Text(
                                  'Submit Correct Answer (${question.correctAnswer})'),
                            ),
                          ],
                        ),
                      ),
                    // Enhanced Animated Answer Options
                    ...question.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isCorrectAnswer = option == question.correctAnswer;
                      final showAsCorrect =
                          _isAnswerRevealed && isCorrectAnswer;

                      return AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0,
                                index *
                                    15.0), // Reduced spacing for better layout
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: Spacing.md),
                              child: AnimatedContainer(
                                duration: Duration(
                                    milliseconds: 300 +
                                        (index * 100)), // Staggered animation
                                curve: Curves.easeOutBack,
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        50, // Reduced minimum for short options
                                    maxHeight: _calculateAnswerOptionHeight(
                                        option), // Dynamic height based on content
                                  ),
                                  decoration: BoxDecoration(
                                    color: showAsCorrect
                                        ? tokens.success.withValues(alpha: 0.1)
                                        : tokens.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: showAsCorrect
                                          ? tokens.success
                                          : tokens.borderDefault,
                                      width: showAsCorrect ? 2.5 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: showAsCorrect
                                            ? tokens.success
                                                .withValues(alpha: 0.2)
                                            : tokens.overlayDim,
                                        blurRadius: showAsCorrect ? 12 : 8,
                                        offset: const Offset(0, 4),
                                        spreadRadius: showAsCorrect ? 2 : 1,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _submitAnswer(option),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(Spacing.md),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Align to top for better text flow
                                          children: [
                                            // Animated option indicator
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: showAsCorrect
                                                    ? tokens.success
                                                    : tokens.surfaceAlt,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: showAsCorrect
                                                      ? tokens.success
                                                      : tokens.borderDefault,
                                                  width: 2,
                                                ),
                                              ),
                                              child: showAsCorrect
                                                  ? Icon(
                                                      Icons.check,
                                                      color: tokens.onPrimary,
                                                      size: 16,
                                                    )
                                                  : Text(
                                                      String.fromCharCode(65 +
                                                          index), // A, B, C, D...
                                                      style: TextStyle(
                                                        color:
                                                            tokens.textPrimary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                            ),

                                            const SizedBox(width: Spacing.md),

                                            Expanded(
                                              child: Text(
                                                option,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: tokens.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height:
                                                          1.4, // Increased line height
                                                    ),
                                                textAlign: TextAlign.left,
                                                overflow: TextOverflow
                                                    .visible, // Show all text
                                                maxLines:
                                                    null, // Allow unlimited lines
                                              ),
                                            ),

                                            // Hover effect indicator
                                            if (!showAsCorrect)
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: tokens.textSecondary,
                                                size: 16,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: Spacing.xl), // Add bottom spacing
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizResults() {
    final tokens = context.tokens;

    // Safety check for quiz results
    if (_currentQuiz == null ||
        _currentQuiz!.questions.isEmpty ||
        _userAnswers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: tokens.error,
            ),
            const SizedBox(height: 16),
            Text(
              'RESULTS ERROR',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            AccessibleButton(
              onPressed: _resetQuiz,
              variant: ButtonVariant.primary,
              child: const Text('BACK TO STUDY'),
            ),
          ],
        ),
      );
    }

    // Start animations for results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaleController.forward();
      _bounceController.forward();
    });

    final int correctAnswers = _userAnswers.where((answer) {
      final int index = _userAnswers.indexOf(answer);
      return index < _currentQuiz!.questions.length &&
          answer == _currentQuiz!.questions[index].correctAnswer;
    }).length;

    final int percentage =
        (correctAnswers / _currentQuiz!.questions.length * 100).round();
    final bool isHighScore = percentage >= 80;

    // Track achievement progress for quiz completion
    _trackQuizCompletion(percentage);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced Animated Results Header
          ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _quizSlideAnimation,
              child: Container(
                padding: const EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isHighScore
                        ? [
                            tokens.success.withValues(alpha: 0.15),
                            tokens.success.withValues(alpha: 0.08),
                            tokens.success.withValues(alpha: 0.05),
                          ]
                        : [
                            tokens.primary.withValues(alpha: 0.15),
                            tokens.primary.withValues(alpha: 0.08),
                            tokens.primary.withValues(alpha: 0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isHighScore
                        ? tokens.success.withValues(alpha: 0.4)
                        : tokens.primary.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHighScore
                          ? tokens.success.withValues(alpha: 0.25)
                          : tokens.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Animated celebration icon
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _bounceAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isHighScore
                                  ? tokens.success.withValues(alpha: 0.2)
                                  : tokens.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isHighScore
                                    ? tokens.success.withValues(alpha: 0.4)
                                    : tokens.primary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isHighScore
                                  ? Icons.celebration
                                  : Icons.emoji_events,
                              size: 48,
                              color:
                                  isHighScore ? tokens.success : tokens.primary,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: Spacing.md),

                    // Animated title with pulse effect
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Text(
                            isHighScore ? 'EXCELLENT WORK!' : 'QUIZ COMPLETED',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: isHighScore
                                      ? tokens.success
                                      : tokens.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: Spacing.sm),

                    Text(
                      'You scored $correctAnswers out of ${_currentQuiz!.questions.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    const SizedBox(height: Spacing.md),

                    // Animated percentage with bounce effect
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _bounceAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isHighScore
                                  ? tokens.success.withValues(alpha: 0.15)
                                  : tokens.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isHighScore
                                    ? tokens.success.withValues(alpha: 0.4)
                                    : tokens.primary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '$percentage%',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: tokens.success ?? tokens.primary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Row(
            children: [
              Expanded(
                child: AccessibleButton(
                  onPressed: _resetQuiz,
                  variant: ButtonVariant.secondary,
                  semanticLabel: 'Return to study mode',
                  child: const Text('BACK TO STUDY'),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: AccessibleButton(
                  onPressed: () => _startQuiz(_currentQuiz!),
                  variant: ButtonVariant.primary,
                  semanticLabel: 'Retake this quiz',
                  child: const Text('RETRY QUIZ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getQuizTypeLabel(QuizType type) {
    switch (type) {
      case QuizType.multipleChoice:
        return 'Multiple Choice';
      case QuizType.trueFalse:
        return 'True/False';
      case QuizType.shortAnswer:
        return 'Short Answer';
    }
  }

  /// Track quiz completion achievement progress
  void _trackQuizCompletion(int percentage) async {
    try {
      final scorePercent = percentage / 100.0;
      await AchievementTrackerService.instance.trackQuizCompleted(
        scorePercent,
        totalQuestions: _currentQuiz?.questions.length ?? 0,
        quizType:
            _getQuizTypeLabel(_currentQuiz?.type ?? QuizType.multipleChoice)
                .toLowerCase(),
        timeTaken: _quizStartTime != null
            ? DateTime.now().difference(_quizStartTime)
            : null,
      );
      debugPrint('Quiz completion tracked: $percentage% score');
    } catch (e) {
      debugPrint('Failed to track quiz completion: $e');
    }
  }

  /// Track study session achievement progress
  void _trackStudySession(
      {int? durationMinutes, int? itemsStudied, double? accuracyRate}) async {
    try {
      await AchievementTrackerService.instance.trackStudySession(
        durationMinutes: durationMinutes,
        studyType: 'flashcard_study',
        itemsStudied: itemsStudied,
        accuracyRate: accuracyRate,
      );
      debugPrint('Study session tracked');
    } catch (e) {
      debugPrint('Failed to track study session: $e');
    }
  }

  /// Track study time achievement progress
  void _trackStudyTime(int minutes, {String? context}) async {
    try {
      await AchievementTrackerService.instance
          .trackStudyTime(minutes, context: context);
      debugPrint('Study time tracked: $minutes minutes');
    } catch (e) {
      debugPrint('Failed to track study time: $e');
    }
  }

  /// Track individual flashcard review for achievements
  void _trackFlashcardReview() {
    try {
      final currentCard = _currentStudySet.flashcards[_currentCardIndex];
      final reviewTime = DateTime.now(); // Simplified timing

      // For now, we'll just log the flashcard review
      // In a future implementation, this could be tracked through a proper service
      debugPrint(
          'Flashcard review tracked for achievements: ${currentCard.question}');
    } catch (e) {
      debugPrint('Failed to track flashcard review: $e');
    }
  }

  /// Track flashcard session completion for achievements
  void _trackFlashcardSessionCompletion() {
    try {
      final totalCards = _currentStudySet.flashcards.length;
      final sessionDuration = DateTime.now().difference(_studyStartTime);

      // For now, we'll just log the flashcard session completion
      // In a future implementation, this could be tracked through a proper service
      debugPrint(
          'Flashcard session completion tracked: $totalCards cards, ${sessionDuration.inMinutes} minutes');
    } catch (e) {
      debugPrint('Failed to track flashcard session completion: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    final tokens = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: tokens.onPrimary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: tokens.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: tokens.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Calculate dynamic height for question container based on content length
  double _calculateQuestionHeight(String questionText) {
    // Base height for question container
    const double baseHeight = 200.0;
    const double minHeight = 150.0;
    const double maxHeight = 600.0;

    // Calculate height based on text length
    final int charCount = questionText.length;
    final double heightPerChar = 0.8; // Approximate height per character

    // Calculate dynamic height
    double dynamicHeight = baseHeight + (charCount * heightPerChar);

    // Ensure height is within bounds
    dynamicHeight = dynamicHeight.clamp(minHeight, maxHeight);

    return dynamicHeight;
  }

  /// Calculate dynamic height for answer option container based on content length
  double _calculateAnswerOptionHeight(String optionText) {
    // Base height for answer option container
    const double baseHeight = 60.0;
    const double minHeight = 50.0;
    const double maxHeight = 400.0;

    // Calculate height based on text length
    final int charCount = optionText.length;
    final double heightPerChar = 1.2; // Higher height per character for options

    // Calculate dynamic height
    double dynamicHeight = baseHeight + (charCount * heightPerChar);

    // Ensure height is within bounds
    dynamicHeight = dynamicHeight.clamp(minHeight, maxHeight);

    return dynamicHeight;
  }
}

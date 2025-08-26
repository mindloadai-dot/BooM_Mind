import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/services/credit_service.dart';
import 'package:mindload/services/storage_service.dart';
import 'package:mindload/widgets/customize_study_set_dialog.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/widgets/brain_logo.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/theme.dart';

class StudySetSelectionScreen extends StatefulWidget {
  final Function(StudySet) onStudySetSelected;

  const StudySetSelectionScreen({
    super.key,
    required this.onStudySetSelected,
  });

  @override
  State<StudySetSelectionScreen> createState() =>
      _StudySetSelectionScreenState();
}

class _StudySetSelectionScreenState extends State<StudySetSelectionScreen> {
  final CreditService _creditService = CreditService.instance;
  List<StudySet> _savedStudySets = [];
  StudySet? _lastCustomSet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudySets();
  }

  Future<void> _loadStudySets() async {
    try {
      final sets = await StorageService.instance.getStudySets();
      final lastCustom = await StorageService.instance.getLastCustomStudySet();

      setState(() {
        _savedStudySets = sets
            .map((metadata) => StudySet.fromJson(metadata.toStudySetData()))
            .toList();
        _lastCustomSet = lastCustom != null
            ? StudySet.fromJson(lastCustom.toStudySetData())
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.tokens.surface,
      appBar: MindloadAppBarFactory.secondary(title: 'Select Study Set'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with brain icon
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color:
                                context.tokens.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  context.tokens.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: BrainLogo(
                            size: 40,
                            color: context.tokens.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose your study material',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Select a study set to focus on during your Ultra Mode session',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Last Custom Set (if available)
                  if (_lastCustomSet != null) ...[
                    Text(
                      'Quick Start',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStudySetCard(
                      _lastCustomSet!,
                      'Use My Last Custom Set',
                      Icons.history,
                      isQuickStart: true,
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Saved Study Sets
                  if (_savedStudySets.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'Saved Sets',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_savedStudySets.length} sets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _savedStudySets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final studySet = _savedStudySets[index];
                        return _buildStudySetCard(
                          studySet,
                          studySet.title,
                          _getSubjectIcon(studySet.title),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Create New Custom Set
                  Text(
                    'Create New',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCreateNewCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStudySetCard(StudySet studySet, String title, IconData icon,
      {bool isQuickStart = false}) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isQuickStart
              ? theme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onStudySetSelected(studySet);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isQuickStart
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isQuickStart
                          ? theme.primaryColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          studySet.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (studySet.quizzes.isNotEmpty) ...[
                    Icon(Icons.quiz,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '${studySet.quizzes.length} quiz',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if (studySet.quizzes.isNotEmpty &&
                      studySet.flashcards.isNotEmpty)
                    Text(
                      ' • ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  if (studySet.flashcards.isNotEmpty) ...[
                    Icon(Icons.style,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '${studySet.flashcards.length} cards',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

  Widget _buildCreateNewCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: _showCustomizeDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Custom Set',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Design your own quiz and flashcard counts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCreditCostColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCreditCostText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCreditCostColor() {
    if (_creditService.isUnlimited) {
      return Colors.green;
    } else if (_creditService.creditsRemaining >= 2) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  String _getCreditCostText() {
    if (_creditService.isUnlimited) {
      return 'Unlimited';
    } else {
      return 'Up to 2 credits';
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'english':
      case 'literature':
        return Icons.menu_book;
      case 'language':
        return Icons.translate;
      case 'computer science':
      case 'programming':
        return Icons.computer;
      case 'art':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      default:
        return Icons.school;
    }
  }

  void _showCustomizeDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomizeStudySetDialog(
        topicDifficulty: 'medium',
        onGenerate: (quizCount, flashcardCount) async {
          await _generateCustomStudySet(quizCount, flashcardCount);
        },
      ),
    );
  }

  Future<void> _generateCustomStudySet(
      int quizCount, int flashcardCount) async {
    // Determine study set type
    StudySetType type;
    if (quizCount > 0 && flashcardCount > 0) {
      type = StudySetType.both;
    } else if (quizCount > 0) {
      type = StudySetType.quiz;
    } else {
      type = StudySetType.flashcards;
    }

    // Check if user can generate this study set
    final canGenerate = await _creditService.canGenerateStudySet(type);
    if (!canGenerate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough credits to generate this study set'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Generating your custom study set...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    try {
      // Use credits
      final success = await _creditService.useCreditsForStudySet(
          type, quizCount, flashcardCount);

      if (!success) {
        throw Exception('Failed to use credits');
      }

      // Generate sample study set (replace with actual generation logic)
      final customStudySet = StudySet(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Custom Study Set',
        content: 'Custom generated study content',
        flashcards: [], // Will be generated by AI service
        quizzes: quizCount > 0 ? [_generateSampleQuiz(quizCount)] : [],
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
      );

      // Save as last custom set
      await StorageService.instance
          .saveLastCustomStudySet(customStudySet.toMetadata());

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close selection screen
        widget.onStudySetSelected(customStudySet);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate study set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Quiz _generateSampleQuiz(int count) {
    if (count == 0) throw ArgumentError('Quiz count must be greater than 0');

    final limitedCount =
        count > 5 ? 5 : count; // Limit sample questions to 5 max
    final questions = List.generate(
        limitedCount,
        (index) => QuizQuestion(
              id: 'q_${index + 1}',
              question:
                  'Sample question ${index + 1}: What is the main concept?',
              options: [
                'Understanding key principles',
                'Memorizing unrelated facts',
                'Ignoring important details',
                'Avoiding the topic entirely',
              ],
              correctAnswer: 'Understanding key principles',
              type: QuizType.multipleChoice,
            ));

    return Quiz(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Custom Quiz',
      type: QuizType.multipleChoice,
      questions: questions,
      results: [],
      createdDate: DateTime.now(),
    );
  }
}

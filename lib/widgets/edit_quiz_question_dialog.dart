import 'package:flutter/material.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/theme.dart';

class EditQuizQuestionDialog extends StatefulWidget {
  final QuizQuestion quizQuestion;
  final Function(QuizQuestion) onSave;

  const EditQuizQuestionDialog({
    super.key,
    required this.quizQuestion,
    required this.onSave,
  });

  @override
  State<EditQuizQuestionDialog> createState() => _EditQuizQuestionDialogState();
}

class _EditQuizQuestionDialogState extends State<EditQuizQuestionDialog> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late TextEditingController _explanationController;
  late String _correctAnswer;
  late DifficultyLevel _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.quizQuestion.question);
    _optionControllers = widget.quizQuestion.options
        .map((option) => TextEditingController(text: option))
        .toList();
    _explanationController =
        TextEditingController(text: widget.quizQuestion.explanation ?? '');
    _correctAnswer = widget.quizQuestion.correctAnswer;
    _selectedDifficulty = widget.quizQuestion.difficulty;
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Dialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.quiz, color: tokens.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Edit Quiz Question',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: tokens.textSecondary),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question field
                    Text(
                      'Question',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter the question...',
                        hintStyle: TextStyle(color: tokens.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tokens.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tokens.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: tokens.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: tokens.surfaceAlt,
                      ),
                      style: TextStyle(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 20),

                    // Options
                    Text(
                      'Answer Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildOptionFields(tokens),
                    const SizedBox(height: 20),

                    // Explanation field
                    Text(
                      'Explanation (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _explanationController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Explain why this is the correct answer...',
                        hintStyle: TextStyle(color: tokens.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tokens.borderDefault),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: tokens.borderDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: tokens.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: tokens.surfaceAlt,
                      ),
                      style: TextStyle(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 20),

                    // Difficulty selector
                    Text(
                      'Difficulty Level',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: tokens.borderDefault),
                        borderRadius: BorderRadius.circular(12),
                        color: tokens.surfaceAlt,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DifficultyLevel>(
                          value: _selectedDifficulty,
                          isExpanded: true,
                          dropdownColor: tokens.surface,
                          style: TextStyle(color: tokens.textPrimary),
                          onChanged: (DifficultyLevel? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedDifficulty = newValue;
                              });
                            }
                          },
                          items: DifficultyLevel.values
                              .map<DropdownMenuItem<DifficultyLevel>>(
                                  (DifficultyLevel value) {
                            return DropdownMenuItem<DifficultyLevel>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    _getDifficultyIcon(value),
                                    color: _getDifficultyColor(value, tokens),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getDifficultyLabel(value),
                                    style: TextStyle(color: tokens.textPrimary),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveQuizQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields(SemanticTokens tokens) {
    List<Widget> fields = [];

    for (int i = 0; i < _optionControllers.length; i++) {
      final isCorrect = _optionControllers[i].text == _correctAnswer;

      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // Correct answer radio button
              Radio<String>(
                value: _optionControllers[i].text,
                groupValue: _correctAnswer,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _correctAnswer = value;
                    });
                  }
                },
                activeColor: tokens.primary,
              ),
              const SizedBox(width: 8),

              // Option text field
              Expanded(
                child: TextField(
                  controller: _optionControllers[i],
                  onChanged: (value) {
                    // Update correct answer if this option was selected
                    if (isCorrect) {
                      setState(() {
                        _correctAnswer = value;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Option ${String.fromCharCode(65 + i)}',
                    labelStyle: TextStyle(color: tokens.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            isCorrect ? tokens.success : tokens.borderDefault,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            isCorrect ? tokens.success : tokens.borderDefault,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isCorrect ? tokens.success : tokens.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isCorrect
                        ? tokens.success.withValues(alpha: 0.1)
                        : tokens.surfaceAlt,
                  ),
                  style: TextStyle(color: tokens.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return fields;
  }

  void _saveQuizQuestion() {
    final question = _questionController.text.trim();
    final options =
        _optionControllers.map((controller) => controller.text.trim()).toList();
    final explanation = _explanationController.text.trim();

    if (question.isEmpty) {
      _showError('Please enter a question');
      return;
    }

    if (options.any((option) => option.isEmpty)) {
      _showError('Please fill in all answer options');
      return;
    }

    if (!options.contains(_correctAnswer)) {
      _showError('Please select a correct answer');
      return;
    }

    final updatedQuestion = widget.quizQuestion.copyWith(
      question: question,
      options: options,
      correctAnswer: _correctAnswer,
      explanation: explanation.isEmpty ? null : explanation,
      difficulty: _selectedDifficulty,
    );

    widget.onSave(updatedQuestion);
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  IconData _getDifficultyIcon(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Icons.looks_one;
      case DifficultyLevel.intermediate:
        return Icons.looks_two;
      case DifficultyLevel.advanced:
        return Icons.looks_3;
      case DifficultyLevel.expert:
        return Icons.looks_4;
    }
  }

  Color _getDifficultyColor(DifficultyLevel difficulty, SemanticTokens tokens) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.blue;
      case DifficultyLevel.advanced:
        return Colors.orange;
      case DifficultyLevel.expert:
        return Colors.red;
    }
  }

  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }
}

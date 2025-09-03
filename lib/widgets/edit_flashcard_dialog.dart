import 'package:flutter/material.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/theme.dart';

class EditFlashcardDialog extends StatefulWidget {
  final Flashcard flashcard;
  final Function(Flashcard) onSave;

  const EditFlashcardDialog({
    super.key,
    required this.flashcard,
    required this.onSave,
  });

  @override
  State<EditFlashcardDialog> createState() => _EditFlashcardDialogState();
}

class _EditFlashcardDialogState extends State<EditFlashcardDialog> {
  late TextEditingController _questionController;
  late TextEditingController _answerController;
  late DifficultyLevel _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.flashcard.question);
    _answerController = TextEditingController(text: widget.flashcard.answer);
    _selectedDifficulty = widget.flashcard.difficulty;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: tokens.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Edit Flashcard',
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
                  borderSide: BorderSide(color: tokens.primary, width: 2),
                ),
                filled: true,
                fillColor: tokens.surfaceAlt,
              ),
              style: TextStyle(color: tokens.textPrimary),
            ),
            const SizedBox(height: 20),

            // Answer field
            Text(
              'Answer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter the answer...',
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
                  borderSide: BorderSide(color: tokens.primary, width: 2),
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
            const SizedBox(height: 32),

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
                  onPressed: _saveFlashcard,
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

  void _saveFlashcard() {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both question and answer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedFlashcard = widget.flashcard.copyWith(
      question: question,
      answer: answer,
      difficulty: _selectedDifficulty,
    );

    widget.onSave(updatedFlashcard);
    Navigator.pop(context);
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

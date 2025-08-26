import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/openai_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/widgets/mindload_enforcement_dialog.dart';
import 'package:mindload/screens/paywall_screen.dart';
import 'package:mindload/theme.dart';

/// Mindload Content Generation Dialog
/// Demonstrates integrated enforcement of all limits and caps
class MindloadGenerationDialog extends StatefulWidget {
  final String sourceContent;
  final String? title;
  final bool isRecreate;
  final String? existingSetId;

  const MindloadGenerationDialog({
    super.key,
    required this.sourceContent,
    this.title,
    this.isRecreate = false,
    this.existingSetId,
  });

  @override
  State<MindloadGenerationDialog> createState() => _MindloadGenerationDialogState();
}

class _MindloadGenerationDialogState extends State<MindloadGenerationDialog> {
  final TextEditingController _titleController = TextEditingController();
  bool _isGenerating = false;
  bool _lastAttemptFailed = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.title ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    final economyService = context.read<MindloadEconomyService>();
    
    // Create generation request
    final request = GenerationRequest(
      sourceContent: widget.sourceContent,
      sourceCharCount: widget.sourceContent.length,
      isRecreate: widget.isRecreate,
      lastAttemptFailed: _lastAttemptFailed,
    );

    // ENFORCEMENT CHECK
    final enforcement = economyService.canGenerateContent(request);
    if (!enforcement.canProceed) {
      await _showEnforcementDialog(enforcement);
      return;
    }

    setState(() {
      _isGenerating = true;
      _lastAttemptFailed = false;
    });

    try {
      // Use credits first (before OpenAI call)
      final creditsUsed = await economyService.useCreditsForGeneration(request);
      if (!creditsUsed) {
        throw Exception('Failed to consume credits');
      }

      // Get current output limits based on tier and budget state
      final outputCounts = economyService.getOutputCounts();
      final flashcardsCount = outputCounts['flashcards']!;
      final quizCount = outputCounts['quiz']!;
      
      // Record budget usage (estimate cost)
      final estimatedCost = _estimateOpenAICost(
        widget.sourceContent.length,
        flashcardsCount + quizCount,
        economyService.budgetState == BudgetState.savingsMode,
      );
      
      await economyService.recordBudgetUsage(estimatedCost);

      // Generate content with OpenAI
      final studySet = await _callOpenAI(
        widget.sourceContent,
        _titleController.text.isNotEmpty ? _titleController.text : 'Generated Study Set',
        flashcardsCount,
        quizCount,
        economyService.budgetState == BudgetState.savingsMode, // Use efficient model
      );

      // Success - close dialog and return result
      if (mounted) {
        Navigator.of(context).pop(studySet);
      }

    } catch (e) {
      setState(() {
        _lastAttemptFailed = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _generateContent,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<StudySet> _callOpenAI(
    String content,
    String title,
    int flashcardsCount,
    int quizCount,
    bool useEfficientModel,
  ) async {
    // This is a placeholder - replace with actual OpenAI service call
    final openAIService = OpenAIService.instance;
    
    // Use efficient model if in savings mode
    final model = useEfficientModel ? 'gpt-4o-mini' : 'gpt-4o';
    
    // Generate study set content
    final flashcards = await openAIService.generateFlashcards(
      content,
      count: flashcardsCount,
      model: model,
    );
    
    final quizQuestions = await openAIService.generateQuiz(
      content,
      count: quizCount,
      model: model,
    );

    // Create study set
    return StudySet(
      id: widget.existingSetId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      flashcards: flashcards,
      quizQuestions: quizQuestions,
      createdDate: DateTime.now(),
      lastStudied: DateTime.now(),
      category: 'Generated',
      description: 'Auto-generated from content',
      sourceType: 'text',
      sourceLength: content.length,
      tags: [],
      isArchived: false,
    );
  }

  double _estimateOpenAICost(int inputLength, int outputItems, bool efficient) {
    // Rough estimate based on OpenAI pricing
    final inputTokens = (inputLength / 4).round(); // ~4 chars per token
    final outputTokens = outputItems * 100; // ~100 tokens per item
    
    const inputCostPer1k = 0.00015; // GPT-4o-mini input
    const outputCostPer1k = 0.0006; // GPT-4o-mini output
    
    double cost = (inputTokens * inputCostPer1k / 1000) + (outputTokens * outputCostPer1k / 1000);
    
    if (efficient) {
      cost *= 0.8; // 20% savings in efficient mode
    }
    
    return cost;
  }

  Future<void> _showEnforcementDialog(EnforcementResult result) async {
    await showEnforcementDialog(
      context,
      result,
      onUpgrade: () {
        Navigator.of(context).pop(); // Close enforcement dialog
        Navigator.of(context).pop(); // Close generation dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaywallScreen(trigger: 'content_generation'),
            fullscreenDialog: true,
          ),
        );
      },
      onBuyCredits: () {
        Navigator.of(context).pop(); // Close enforcement dialog
        Navigator.of(context).pop(); // Close generation dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaywallScreen(trigger: 'content_generation'),
            fullscreenDialog: true,
          ),
        );
      },
      onArchiveSets: () {
        Navigator.of(context).pop(); // Close enforcement dialog
        Navigator.of(context).pop(); // Close generation dialog
        // TODO: Navigate to set manager
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigate to set manager to archive sets')),
        );
      },
      onTrimContent: () {
        Navigator.of(context).pop(); // Close enforcement dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please reduce content size and try again')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economyService, child) {
        final economy = economyService.userEconomy;
        final budgetState = economyService.budgetState;
        
        if (economy == null) {
          return const AlertDialog(
            title: Text('Error'),
            content: Text('Economy system not initialized'),
          );
        }

        final outputCounts = economyService.getOutputCounts();
        final sourceCharCount = widget.sourceContent.length;
        final pasteLimit = economy.getPasteCharLimit(budgetState);
        final isOverLimit = sourceCharCount > pasteLimit;

        final tokens = context.tokens;
        
        return AlertDialog(
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                widget.isRecreate ? Icons.refresh : Icons.auto_awesome,
                color: tokens.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isRecreate ? 'Recreate Study Set' : 'Generate Study Set',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Study Set Title',
                  hintText: 'Enter a descriptive title...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                enabled: !_isGenerating,
              ),
              
              const SizedBox(height: 16),
              
              // Source Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverLimit 
                      ? Colors.red.withValues(alpha:  0.1)
                      : tokens.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverLimit 
                        ? Colors.red.withValues(alpha:  0.3)
                        : tokens.surface.withValues(alpha:  0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_snippet_outlined,
                          size: 16,
                          color: isOverLimit ? Colors.red : tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Source Content',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isOverLimit ? Colors.red : tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      '${(sourceCharCount / 1000).toStringAsFixed(1)}K / ${(pasteLimit / 1000).round()}K characters',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverLimit ? Colors.red : tokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    LinearProgressIndicator(
                      value: (sourceCharCount / pasteLimit).clamp(0.0, 1.0),
                      backgroundColor: tokens.surface.withValues(alpha:  0.3),
                      valueColor: AlwaysStoppedAnimation(
                        isOverLimit ? Colors.red : tokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Output Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha:  0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.primary.withValues(alpha:  0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: tokens.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Will Generate',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        _buildOutputBadge(
                          context,
                          '${outputCounts['flashcards']} flashcards',
                          Icons.style_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text('+', style: TextStyle(color: tokens.textSecondary)),
                        const SizedBox(width: 8),
                        _buildOutputBadge(
                          context,
                          '${outputCounts['quiz']} quiz',
                          Icons.quiz_outlined,
                        ),
                      ],
                    ),
                    
                    if (budgetState == BudgetState.savingsMode) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.battery_saver, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Efficient mode active',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Credit Status
              MindloadCreditStatus(
                economy: economy,
                budgetState: budgetState,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: _isGenerating || isOverLimit ? null : _generateContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: tokens.surface.withValues(alpha:  0.3),
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Generating...'),
                      ],
                    )
                  : Text(
                      widget.isRecreate 
                          ? (_lastAttemptFailed ? 'Retry (Free)' : 'Recreate')
                          : 'Generate',
                    ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement credit purchase flow
              },
              child: const Text('GET CREDITS'),
            ),
          ],
        );
      },
    );
  }

  void _onGenerationComplete() {
    Navigator.pop(context);
    // Navigate to set manager
  }

  Widget _buildOutputBadge(BuildContext context, String text, IconData icon) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha:  0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tokens.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.primary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show generation dialog
Future<StudySet?> showMindloadGenerationDialog(
  BuildContext context, {
  required String sourceContent,
  String? title,
  bool isRecreate = false,
  String? existingSetId,
}) {
  return showDialog<StudySet>(
    context: context,
    barrierDismissible: false,
    builder: (context) => MindloadGenerationDialog(
      sourceContent: sourceContent,
      title: title,
      isRecreate: isRecreate,
      existingSetId: existingSetId,
    ),
  );
}
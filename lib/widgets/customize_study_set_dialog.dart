import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/services/credit_service.dart';

class CustomizeStudySetDialog extends StatefulWidget {
  final String topicDifficulty;
  final Function(int quizCount, int flashcardCount) onGenerate;
  
  const CustomizeStudySetDialog({
    super.key,
    this.topicDifficulty = 'medium',
    required this.onGenerate,
  });

  @override
  State<CustomizeStudySetDialog> createState() => _CustomizeStudySetDialogState();
}

class _CustomizeStudySetDialogState extends State<CustomizeStudySetDialog> {
  final CreditService _creditService = CreditService.instance;
  
  int _quizCount = 0; // Initialize with default value
  int _flashcardCount = 0; // Initialize with default value
  Map<String, int> _optimalCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCountsWithOptimal();
  }

  Future<void> _initializeCountsWithOptimal() async {
    setState(() => _isLoading = true);
    
    // Simulate a brief delay for AI calculation
    await Future.delayed(const Duration(milliseconds: 300));
    
    _optimalCounts = _creditService.calculateOptimalCounts(widget.topicDifficulty);
    
    setState(() {
      _quizCount = _optimalCounts['quiz'] ?? _creditService.lastQuizCount;
      _flashcardCount = _optimalCounts['flashcards'] ?? _creditService.lastFlashcardCount;
      _isLoading = false;
    });
  }

  int get _totalCreditsNeeded {
    int credits = 0;
    if (_quizCount > 0) credits += CreditLimits.quizSetCost;
    if (_flashcardCount > 0) credits += CreditLimits.flashcardSetCost;
    return credits;
  }

  /// Calculate the actual cost based on the number of items selected
  Map<String, dynamic> get _detailedCostBreakdown {
    final tier = _creditService.currentPlan;
    int totalCredits = 0;
    int totalTokens = 0;
    
    // Calculate credits and tokens for quiz questions
    if (_quizCount > 0) {
      final quizCredits = CreditLimits.quizSetCost;
      final quizTokensPerCredit = _getQuizTokensPerCredit(tier);
      totalCredits += quizCredits;
      totalTokens += quizTokensPerCredit;
    }
    
    // Calculate credits and tokens for flashcards
    if (_flashcardCount > 0) {
      final flashcardCredits = CreditLimits.flashcardSetCost;
      final flashcardTokensPerCredit = _getFlashcardTokensPerCredit(tier);
      totalCredits += flashcardCredits;
      totalTokens += flashcardTokensPerCredit;
    }
    
    return {
      'totalCredits': totalCredits,
      'totalTokens': totalTokens,
      'quizCredits': _quizCount > 0 ? CreditLimits.quizSetCost : 0,
      'flashcardCredits': _flashcardCount > 0 ? CreditLimits.flashcardSetCost : 0,
      'quizTokens': _quizCount > 0 ? _getQuizTokensPerCredit(tier) : 0,
      'flashcardTokens': _flashcardCount > 0 ? _getFlashcardTokensPerCredit(tier) : 0,
    };
  }

  /// Get tokens per credit for quiz questions based on tier
  int _getQuizTokensPerCredit(SubscriptionPlan tier) {
    switch (tier) {
      case SubscriptionPlan.free:
        return 30; // Free tier: 30 quiz questions per credit
      case SubscriptionPlan.pro:
        return 50; // Pro tier: 50 quiz questions per credit
      case SubscriptionPlan.admin:
        return 70; // Admin tier: 70 quiz questions per credit
    }
  }

  /// Get tokens per credit for flashcards based on tier
  int _getFlashcardTokensPerCredit(SubscriptionPlan tier) {
    switch (tier) {
      case SubscriptionPlan.free:
        return 50; // Free tier: 50 flashcards per credit
      case SubscriptionPlan.pro:
        return 70; // Pro tier: 70 flashcards per credit
      case SubscriptionPlan.admin:
        return 100; // Admin tier: 100 flashcards per credit
    }
  }

  bool get _canGenerate {
    if (_totalCreditsNeeded == 0) return false;
    if (_creditService.isUnlimited) return true;
    return _creditService.creditsRemaining >= _totalCreditsNeeded;
  }

  String get _generateButtonText {
    if (_totalCreditsNeeded == 0) return 'Select at least one type';
    if (_totalCreditsNeeded == 1) return 'Generate (1 Credit)';
    return 'Generate ($_totalCreditsNeeded Credits)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.tune, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Customize Study Set',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Calculating optimal counts...',
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
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
                          const SizedBox(height: 24),
                          
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: theme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cost Breakdown',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _creditService.isUnlimited
                                                ? 'Unlimited credits available'
                                                : '${_creditService.creditsRemaining} credits remaining',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_canGenerate && !_creditService.isUnlimited)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Not enough credits',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Detailed cost breakdown
                                if (_quizCount > 0 || _flashcardCount > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.primaryColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Quiz cost
                                        if (_quizCount > 0) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.quiz, size: 16, color: theme.primaryColor),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '$_quizCount Quiz Questions',
                                                  style: theme.textTheme.bodySmall,
                                                ),
                                              ),
                                              Text(
                                                '${_detailedCostBreakdown['quizCredits']} credit',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.primaryColor,
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
                                              Icon(Icons.style, size: 16, color: theme.primaryColor),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '$_flashcardCount Flashcards',
                                                  style: theme.textTheme.bodySmall,
                                                ),
                                              ),
                                              Text(
                                                '${_detailedCostBreakdown['flashcardCredits']} credit',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.primaryColor,
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
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${_detailedCostBreakdown['totalCredits']} Credit${_detailedCostBreakdown['totalCredits'] != 1 ? 's' : ''}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (!_creditService.isUnlimited && !_canGenerate) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUpgradeDialog();
                        },
                        icon: const Icon(Icons.upgrade, size: 18),
                        label: const Text('Upgrade for unlimited credits'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
            
            // Action Buttons - Fixed at bottom
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _canGenerate ? _onGenerate : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _generateButtonText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(String title, IconData icon, int currentValue, int optimalValue, Function(double) onChanged) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              currentValue.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (optimalValue > 0)
          Text(
            'Optimal: $optimalValue',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: theme.primaryColor,
            inactiveTrackColor: theme.primaryColor.withOpacity(0.3),
            thumbColor: theme.primaryColor,
            overlayColor: theme.primaryColor.withOpacity(0.2),
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
          children: [0, 5, 10, 15, 20, 25].map((count) => 
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: OutlinedButton(
                  onPressed: () {
                    onChanged(count.toDouble());
                    HapticFeedback.lightImpact();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    side: BorderSide(
                      color: currentValue == count 
                        ? theme.primaryColor 
                        : theme.primaryColor.withOpacity(0.3),
                    ),
                    backgroundColor: currentValue == count 
                      ? theme.primaryColor.withOpacity(0.1) 
                      : null,
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: currentValue == count 
                        ? theme.primaryColor 
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: currentValue == count 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  void _onGenerate() {
    Navigator.pop(context);
    widget.onGenerate(_quizCount, _flashcardCount);
    HapticFeedback.mediumImpact();
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text(
          'Get unlimited study set generations, priority support, and more features with our Pro plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
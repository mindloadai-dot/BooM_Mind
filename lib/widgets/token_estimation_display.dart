import 'package:flutter/material.dart';
import 'package:mindload/services/token_estimation_service.dart';
import 'package:mindload/theme.dart';

/// Comprehensive Token Estimation Display Widget
/// Shows clear pre-processing information before any content processing
class TokenEstimationDisplay extends StatelessWidget {
  final TokenEstimationResult estimation;
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;
  final bool showProceedButton;
  final String? proceedButtonText;
  final String? cancelButtonText;
  final bool isInDialog;

  const TokenEstimationDisplay({
    super.key,
    required this.estimation,
    this.onProceed,
    this.onCancel,
    this.showProceedButton = true,
    this.proceedButtonText,
    this.cancelButtonText,
    this.isInDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isCompact = isInDialog;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isCompact ? 500 : 600,
        maxHeight: isCompact ? 350 : 600,
      ),
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.outline.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and title
            _buildHeader(tokens, isCompact),

            SizedBox(height: isCompact ? 12 : 16),

            // Token cost breakdown
            _buildTokenBreakdown(tokens, isCompact),

            SizedBox(height: isCompact ? 8 : 12),

            // Input details
            _buildInputDetails(tokens, isCompact),

            SizedBox(height: isCompact ? 8 : 12),

            // Output estimate
            _buildOutputEstimate(tokens, isCompact),

            // Warnings if any
            if (estimation.warnings.isNotEmpty) ...[
              SizedBox(height: isCompact ? 8 : 12),
              _buildWarnings(tokens, isCompact),
            ],

            // Action buttons
            if (showProceedButton) ...[
              SizedBox(height: isCompact ? 12 : 16),
              _buildActionButtons(tokens),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens, bool isCompact) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.token,
            color: tokens.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Token Estimation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              Text(
                'Pre-processing cost breakdown',
                style: TextStyle(
                  fontSize: 14,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokenBreakdown(SemanticTokens tokens, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: isCompact ? 16 : 18,
                color: tokens.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Cost',
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${estimation.totalTokens}',
                style: TextStyle(
                  fontSize: isCompact ? 28 : 32,
                  fontWeight: FontWeight.w800,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MindLoad Tokens',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          if (estimation.depthMultiplier != 1.0) ...[
            SizedBox(height: isCompact ? 8 : 12),
            Container(
              padding: EdgeInsets.all(isCompact ? 6 : 8),
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: isCompact ? 14 : 16,
                    color: tokens.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${estimation.depthMultiplier > 1 ? 'Increased' : 'Reduced'} cost due to ${estimation.inputDetails['depth']} analysis',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputDetails(SemanticTokens tokens, bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.input,
                size: 20,
                color: tokens.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Input Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputDetailRow(
              'Type', estimation.inputType.toUpperCase(), tokens),
          ..._buildInputDetailRows(tokens),
        ],
      ),
    );
  }

  List<Widget> _buildInputDetailRows(SemanticTokens tokens) {
    final rows = <Widget>[];

    switch (estimation.inputType) {
      case 'text':
        rows.add(_buildInputDetailRow(
            'Words', '${estimation.inputDetails['words']}', tokens));
        rows.add(_buildInputDetailRow(
            'Characters', '${estimation.inputDetails['characters']}', tokens));
        break;
      case 'youtube':
        rows.add(_buildInputDetailRow(
            'Duration',
            '${estimation.inputDetails['durationMinutes'].toStringAsFixed(1)} min',
            tokens));
        rows.add(_buildInputDetailRow(
            'Captions',
            estimation.inputDetails['hasCaptions']
                ? 'Available'
                : 'Not available',
            tokens));
        break;
      case 'pdf':
        rows.add(_buildInputDetailRow(
            'Pages', '${estimation.inputDetails['pageCount']}', tokens));
        rows.add(_buildInputDetailRow(
            'Total Words', '${estimation.inputDetails['totalWords']}', tokens));
        break;
      case 'document':
        rows.add(_buildInputDetailRow('File Type',
            estimation.inputDetails['fileType'].toUpperCase(), tokens));
        rows.add(_buildInputDetailRow('Estimated Words',
            '${estimation.inputDetails['estimatedWords']}', tokens));
        break;
      case 'regeneration':
        rows.add(_buildInputDetailRow('Current Flashcards',
            '${estimation.inputDetails['currentFlashcards']}', tokens));
        rows.add(_buildInputDetailRow('Current Quiz Questions',
            '${estimation.inputDetails['currentQuizQuestions']}', tokens));
        break;
    }

    rows.add(_buildInputDetailRow('Analysis Depth',
        estimation.inputDetails['depth'].toUpperCase(), tokens));

    return rows;
  }

  Widget _buildInputDetailRow(
      String label, String value, SemanticTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputEstimate(SemanticTokens tokens, bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.output,
                size: 20,
                color: tokens.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Expected Output',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (estimation.outputEstimate['flashcards']! > 0) ...[
                Expanded(
                  child: _buildOutputItem(
                    'Flashcards',
                    '${estimation.outputEstimate['flashcards']}',
                    Icons.quiz,
                    tokens,
                  ),
                ),
              ],
              if (estimation.outputEstimate['flashcards']! > 0 &&
                  estimation.outputEstimate['quizQuestions']! > 0)
                Container(
                  width: 1,
                  height: 40,
                  color: tokens.divider,
                ),
              if (estimation.outputEstimate['quizQuestions']! > 0) ...[
                Expanded(
                  child: _buildOutputItem(
                    'Quiz Questions',
                    '${estimation.outputEstimate['quizQuestions']}',
                    Icons.help_outline,
                    tokens,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputItem(
      String label, String count, IconData icon, SemanticTokens tokens) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: tokens.accent,
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: tokens.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWarnings(SemanticTokens tokens, bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: tokens.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Warnings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...estimation.warnings.map((warning) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: tokens.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 14,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SemanticTokens tokens) {
    return Column(
      children: [
        if (onCancel != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: tokens.borderDefault),
              ),
              child: Text(
                cancelButtonText ?? 'Cancel',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              proceedButtonText ?? 'Proceed',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

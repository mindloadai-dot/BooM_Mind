import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/services/pdf_export_service.dart';
import 'package:mindload/models/pdf_export_models.dart';

import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/screens/enhanced_subscription_screen.dart';
import 'package:mindload/screens/subscription_settings_screen.dart';
import 'package:mindload/screens/tiers_benefits_screen.dart';
import 'package:mindload/services/auth_service.dart';

/// Export Screen - Demonstrates credits integration for exports
///
/// Features:
/// - Shows export quota remaining
/// - Blocks exports when quota exceeded
/// - Shows credit costs for new content generation during export
/// - Integrated buy credits and upgrade flows
class ExportScreen extends StatefulWidget {
  final String studySetId;
  final String studySetTitle;

  const ExportScreen({
    super.key,
    required this.studySetId,
    required this.studySetTitle,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _selectedExportType = 'flashcards_pdf';
  bool _includeMindloadHeader = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: MindloadAppBarFactory.standard(
        title: 'Export Study Set',
        onBuyCredits: _handleBuyCredits,
        onViewLedger: _handleViewLedger,
        onUpgrade: _handleUpgrade,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Study set info
            _buildStudySetInfo(context, tokens),

            const SizedBox(height: 24),

            // Export quota status
            _buildExportQuotaStatus(context, tokens),

            const SizedBox(height: 24),

            // Export options
            _buildExportOptions(context, tokens),

            const SizedBox(height: 24),

            // Export button
            _buildExportButton(context, tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildStudySetInfo(BuildContext context, SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.library_books,
                  size: 20,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.studySetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Created 2 days ago',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Study set stats
          Row(
            children: [
              _buildStatChip(context, Icons.quiz, '45 Flashcards', tokens),
              const SizedBox(width: 12),
              _buildStatChip(
                  context, Icons.help_outline, '25 Questions', tokens),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label,
      SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.borderDefault.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: tokens.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportQuotaStatus(BuildContext context, SemanticTokens tokens) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        final exportsRemaining = economy.exportsRemaining;
        final monthlyQuota = economy.userEconomy?.monthlyExports ?? 5;
        final isLowExports = exportsRemaining <= 2;
        final isNoExports = exportsRemaining == 0;

        Color statusColor;
        IconData statusIcon;
        String statusMessage;

        if (isNoExports) {
          statusColor = tokens.error;
          statusIcon = Icons.block;
          statusMessage = 'No exports remaining this month';
        } else if (isLowExports) {
          statusColor = tokens.warning;
          statusIcon = Icons.warning_amber_rounded;
          statusMessage = 'Low on exports';
        } else {
          statusColor = tokens.success;
          statusIcon = Icons.check_circle;
          statusMessage = 'Exports available';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              Row(
                children: [
                  Icon(
                    statusIcon,
                    size: 20,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusMessage,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quota details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exports remaining this month',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
                  ),
                  Text(
                    '$exportsRemaining / $monthlyQuota',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),

              // Upgrade suggestion for low/no exports
              if (isLowExports) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        economy.currentTier == MindloadTier.free
                            ? 'Upgrade to get 30+ exports per month'
                            : 'Consider upgrading for more exports',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (economy.currentTier != MindloadTier.cortex &&
                        economy.currentTier != MindloadTier.singularity)
                      ElevatedButton(
                        onPressed: _handleUpgrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.primary,
                          foregroundColor: tokens.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Upgrade'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOptions(BuildContext context, SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 16),

          // Export format selection
          _buildExportFormatOption(
            'flashcards_pdf',
            'Flashcards PDF',
            'Clean, printable flashcard format',
            Icons.quiz,
            tokens,
          ),

          const SizedBox(height: 12),

          _buildExportFormatOption(
            'quiz_pdf',
            'Quiz PDF',
            'Question and answer sheets',
            Icons.help_outline,
            tokens,
          ),

          const SizedBox(height: 12),

          _buildExportFormatOption(
            'both_pdf',
            'Complete Study Pack',
            'Both flashcards and quiz (2 files)',
            Icons.folder,
            tokens,
          ),

          const SizedBox(height: 20),

          // Header option
          Row(
            children: [
              Checkbox(
                value: _includeMindloadHeader,
                onChanged: (value) {
                  setState(() {
                    _includeMindloadHeader = value ?? true;
                  });
                },
                activeColor: tokens.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Include Mindload header and branding',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportFormatOption(
    String value,
    String title,
    String description,
    IconData icon,
    SemanticTokens tokens,
  ) {
    final isSelected = _selectedExportType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExportType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tokens.primary : tokens.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // TODO(dan): Flutter 3.32+ recommends wrapping radios in RadioGroup. Our SDK constraint may not expose RadioGroup yet.
            Radio<String>(
              value: value,
              groupValue: _selectedExportType,
              onChanged: (newValue) {
                setState(() {
                  _selectedExportType = newValue!;
                });
              },
              activeColor: tokens.primary,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 20,
              color: isSelected ? tokens.primary : tokens.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
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

  Widget _buildExportButton(BuildContext context, SemanticTokens tokens) {
    return Consumer<MindloadEconomyService>(
      builder: (context, economy, child) {
        final canExport = economy.exportsRemaining > 0;
        final isLoading = _isExporting;

        return ElevatedButton(
          onPressed: canExport && !isLoading ? _handleExport : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canExport ? tokens.primary : tokens.muted,
            foregroundColor: canExport ? tokens.onPrimary : tokens.onMuted,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: tokens.muted,
            disabledForegroundColor: tokens.onMuted,
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Exporting...'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canExport ? Icons.download : Icons.block,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canExport ? 'Export Study Set' : 'Export Quota Exceeded',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // Action handlers

  void _handleBuyCredits() {
    // Navigate to enhanced subscription screen for credit purchases
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EnhancedSubscriptionScreen(),
        ));
  }

  void _handleViewLedger() {
    // Navigate to subscription settings for credit history
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionSettingsScreen(),
        ));
  }

  void _handleUpgrade() {
    // Navigate to subscription upgrade options
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TiersBenefitsScreen(),
        ));
  }

  void _handleExport() async {
    final economy = context.read<MindloadEconomyService>();

    final request = ExportRequest(
      setId: widget.studySetId,
      exportType: _selectedExportType,
      includeMindloadHeader: _includeMindloadHeader,
    );

    final enforcement = economy.canExportContent(request);

    if (!enforcement.canProceed) {
      // Show enforcement error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enforcement.blockReason ?? 'Cannot export'),
          duration: const Duration(seconds: 3),
        ),
      );

      if (enforcement.showUpgrade) {
        _handleUpgrade();
      }
      return;
    }

    // Proceed with export
    setState(() {
      _isExporting = true;
    });

    try {
      // Use the new PDF export and share system
      final pdfService = PdfExportService.instance;
      final authService = Provider.of<AuthService>(context, listen: false);
      final uid = authService.currentUserId ?? 'anonymous';
      final appVersion = await _getAppVersion();

      final studySet =
          await UnifiedStorageService.instance.getStudySet(widget.studySetId);

      await pdfService.exportAndShareStudySet(
        uid: uid,
        setId: widget.studySetId,
        setTitle: widget.studySetTitle,
        flashcardCount: _selectedExportType.contains('flashcards')
            ? studySet?.flashcards.length ?? 0
            : 0,
        quizCount: _selectedExportType.contains('quiz')
            ? studySet?.quizzes.length ?? 0
            : 0,
        appVersion: appVersion,
        customOptions: PdfExportOptions(
          setId: widget.studySetId,
          includeFlashcards: _selectedExportType.contains('flashcards'),
          includeQuiz: _selectedExportType.contains('quiz'),
          style: 'standard',
          pageSize: 'Letter',
          includeMindloadBranding: _includeMindloadHeader,
        ),
      );

      // If successful, use the export quota
      economy.useExport(request);

      _showSuccessSnackBar(
          'Export process initiated. ${economy.exportsRemaining} exports remaining.');
    } catch (e) {
      _showErrorSnackBar('Export failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<String> _getAppVersion() async {
    // In a real app, you'd use the package_info_plus plugin
    return '1.0.0';
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
      ),
    );
  }
}

/// Upgrade options sheet
class _UpgradeSheet extends StatelessWidget {
  final List<TierUpgradeInfo> upgradeOptions;

  const _UpgradeSheet({required this.upgradeOptions});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      margin: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 16,
        right: 16,
        top: 64,
      ),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(16),
        ),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Upgrade Your Plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),

          // Upgrade options
          ...upgradeOptions
              .map((option) => _buildUpgradeOption(context, option, tokens)),

          // Bottom safe area
          SizedBox(height: mediaQuery.padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildUpgradeOption(
      BuildContext context, TierUpgradeInfo option, SemanticTokens tokens) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: option.accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                option.toTier.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: option.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                option.displayPrice,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Benefits
          ...option.benefits.take(4).map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: option.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 16),

          // CTA button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Upgrade to ${option.toTier.displayName} - Implementation needed'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: option.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                option.cta,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

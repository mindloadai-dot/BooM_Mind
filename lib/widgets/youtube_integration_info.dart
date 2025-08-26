import 'package:flutter/material.dart';
import 'package:mindload/models/subscription_models.dart';
import 'package:mindload/theme.dart';

/// **YouTube Integration Information Widget**
/// 
/// A comprehensive widget that displays YouTube integration capabilities
/// across different subscription tiers. Used in onboarding, welcome screens,
/// and feature explanations throughout the application.
class YouTubeIntegrationInfo extends StatelessWidget {
  final SubscriptionTier? currentTier;
  final bool showComparison;
  final bool showCallToAction;
  final VoidCallback? onUpgradePressed;

  const YouTubeIntegrationInfo({
    super.key,
    this.currentTier,
    this.showComparison = false,
    this.showCallToAction = true,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SemanticTokensExtension>()?.tokens ?? 
                 ThemeManager.instance.currentTokens;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tokens.surface,
            tokens.surface.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.borderDefault.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.textSecondary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with YouTube logo
          _buildHeader(context, tokens),
          const SizedBox(height: 20),
          
          // Feature description
          _buildFeatureDescription(context, tokens),
          const SizedBox(height: 20),
          
          // How it works
          _buildHowItWorks(context, tokens),
          const SizedBox(height: 20),
          
          // Tier comparison or current tier info
          if (showComparison)
            _buildTierComparison(context, tokens)
          else if (currentTier != null)
            _buildCurrentTierInfo(context, tokens),
          
          // Call to action
          if (showCallToAction && currentTier != null)
            _buildCallToAction(context, tokens),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SemanticTokens tokens) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.play_circle_filled,
            color: Color(0xFFFF0000),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YouTube Integration',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transform videos into study materials',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureDescription(BuildContext context, SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What You Can Do',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          context,
          tokens,
          Icons.link_rounded,
          'Paste YouTube Links',
          'Simply paste any YouTube video URL and we\'ll detect it automatically',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context,
          tokens,
          Icons.preview_rounded,
          'Smart Preview',
          'See video details, duration, and estimated MindLoad Token cost before processing',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context,
          tokens,
          Icons.subtitles_rounded,
          'Auto-Transcript',
          'We extract and clean video transcripts, converting them to study-ready text',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context,
          tokens,
          Icons.quiz_rounded,
          'Study Materials',
          'Generate flashcards, quizzes, and study guides from video content',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    SemanticTokens tokens,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
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
    );
  }

  Widget _buildHowItWorks(BuildContext context, SemanticTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStep(context, tokens, '1', 'Paste Link', Icons.content_paste_rounded),
            const SizedBox(width: 8),
            _buildArrow(tokens),
            const SizedBox(width: 8),
            _buildStep(context, tokens, '2', 'Preview', Icons.visibility_rounded),
            const SizedBox(width: 8),
            _buildArrow(tokens),
            const SizedBox(width: 8),
            _buildStep(context, tokens, '3', 'Study', Icons.school_rounded),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.warning.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, color: tokens.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Long-press the preview to confirm and process the video',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, SemanticTokens tokens, String number, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: tokens.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(SemanticTokens tokens) {
    return Icon(
      Icons.arrow_forward_rounded,
      color: tokens.textSecondary,
      size: 16,
    );
  }

  Widget _buildCurrentTierInfo(BuildContext context, SemanticTokens tokens) {
    final tierLimits = TierLimits.getLimits(currentTier!);
    final tierInfo = TierInfo.allTiers.firstWhere((t) => t.tier == currentTier);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tierInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierInfo.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: tierInfo.color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your ${tierInfo.name} Plan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tierInfo.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tierLimits.hasYouTubeAccess) ...[
            _buildPlanFeature(context, tokens, Icons.access_time_rounded, 
              'Video Duration', tierLimits.formattedYouTubeDurationLimit),
            if (tierLimits.monthlyYoutubeIngests > 0) ...[
              const SizedBox(height: 8),
              _buildPlanFeature(context, tokens, Icons.video_library_rounded, 
                'Monthly Videos', '${tierLimits.monthlyYoutubeIngests} videos'),
            ],
            const SizedBox(height: 8),
            _buildPlanFeature(context, tokens, Icons.language_rounded, 
              'Languages', 'Auto-detect with English fallback'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, color: tokens.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'YouTube integration not available on your current plan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.warning,
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

  Widget _buildPlanFeature(BuildContext context, SemanticTokens tokens, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: tokens.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTierComparison(BuildContext context, SemanticTokens tokens) {
    final tiers = [
      SubscriptionTier.free,
      SubscriptionTier.axon,
      SubscriptionTier.neuron,
      SubscriptionTier.cortex,
      SubscriptionTier.singularity,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YouTube Access by Plan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...tiers.map((tier) {
          final tierLimits = TierLimits.getLimits(tier);
          final tierInfo = TierInfo.allTiers.firstWhere((t) => t.tier == tier);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: tierInfo.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tierInfo.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  tierLimits.hasYouTubeAccess 
                    ? tierLimits.formattedYouTubeDurationLimit
                    : 'No access',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tierLimits.hasYouTubeAccess ? tokens.textPrimary : tokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCallToAction(BuildContext context, SemanticTokens tokens) {
    final tierLimits = TierLimits.getLimits(currentTier!);
    
    if (tierLimits.hasYouTubeAccess) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.success.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: tokens.success, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re all set!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Start creating study materials from YouTube videos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onUpgradePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.primary,
            foregroundColor: tokens.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upgrade_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Upgrade for YouTube Access',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

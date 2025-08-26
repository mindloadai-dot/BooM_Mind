import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/services/mindload_economy_service.dart';

import 'package:mindload/services/remote_config_service.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:mindload/l10n/app_localizations.dart';
import 'package:mindload/services/pricing_service.dart';
import 'package:mindload/constants/product_constants.dart';
import 'package:mindload/theme.dart';
import 'dart:io';

class PaywallScreen extends StatefulWidget {
  final String trigger;
  final bool showExitIntent;

  const PaywallScreen({
    super.key,
    this.trigger = 'unknown',
    this.showExitIntent = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with TickerProviderStateMixin {
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;
  final MindloadEconomyService _economyService =
      MindloadEconomyService.instance;
  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;
  final TelemetryService _telemetry = TelemetryService.instance;
  final PricingService _pricing = PricingService.instance;

  int _selectedPlanIndex = 0; // Default to Pro Monthly
  bool _isLoading = false;
  bool _showExitIntent = false;
  DateTime? _paywallStartTime;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _paywallStartTime = DateTime.now();
    _showExitIntent = widget.showExitIntent;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _trackPaywallView();

    // Initialize pricing so UI reflects Remote Config/overrides without app update
    _pricing.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _trackPaywallExit('dispose');
    super.dispose();
  }

  void _trackPaywallView() async {
    await _telemetry.trackPaywallView(
      variant: _remoteConfig.paywallCopyVariant,
      trigger: widget.trigger,
    );
  }

  void _trackPaywallExit(String action) async {
    if (_paywallStartTime != null) {
      final timeSpent =
          DateTime.now().difference(_paywallStartTime!).inMilliseconds;
      await _telemetry.trackPaywallExit(
        action: action,
        timeSpentMs: timeSpent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = _remoteConfig.getLocalizedPaywallCopy(l10n);
    final plans = SubscriptionPlan.availablePlans;

    return PopScope(
      canPop: false,
      // Migrate deprecated onPopInvoked to onPopInvokedWithResult
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Directionality(
        textDirection: l10n.isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _showExitIntent
                  ? _buildExitIntentContent()
                  : _buildMainContent(copy, plans),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
      Map<String, dynamic> copy, List<SubscriptionPlan> plans) {
    return Column(
      children: [
        // Header with close button
        _buildHeader(copy),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // MindLoad Tokens Explanation
                _buildMindloadTokensExplanation(),

                const SizedBox(height: 24),

                // Plan cards
                _buildPlanCards(plans, copy),

                const SizedBox(height: 32),

                // Action buttons
                _buildActionButtons(copy),

                const SizedBox(height: 24),

                // Legal links
                _buildLegalLinks(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExitIntentContent() {
    final l10n = AppLocalizations.of(context)!;
    final copy = _remoteConfig.getLocalizedExitIntentCopy(l10n);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Exit intent icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flash_on,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  copy['title']!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Body
                Text(
                  copy['body']!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // MindLoad Logic Packs Section
                if (_remoteConfig.sparkPackEnabled ||
                    _remoteConfig.neuroBurstEnabled ||
                    _remoteConfig.cortexPackEnabled ||
                    _remoteConfig.synapsePackEnabled ||
                    _remoteConfig.quantumPackEnabled)
                  _buildLogicPacksSection(),

                const SizedBox(height: 24),

                // Action buttons
                Column(
                  children: [
                    // Buy logic pack button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _buyLogicPack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                color: context.tokens.onPrimary)
                            : Text(
                                'View All Logic Packs',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Maybe later button
                    TextButton(
                      onPressed: () {
                        _trackPaywallExit('maybe_later');
                        Navigator.pop(context);
                      },
                      child: Text(
                        copy['secondary_button']!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> copy) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () => _onWillPop(),
            icon: Icon(Icons.close,
                color: Theme.of(context).colorScheme.onSurface),
          ),

          // Title
          Expanded(
            child: Text(
              copy['header'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          // Balance space
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMindloadTokensExplanation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'What are MindLoad Tokens?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'MindLoad Tokens (ML Tokens) power your AI learning experience. Each subscription includes monthly ML Tokens for:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TokenFeatureChip(
                Icons.auto_awesome,
                'AI Generation',
              ),
              _TokenFeatureChip(
                Icons.quiz,
                'Smart Quizzes',
              ),
              _TokenFeatureChip(
                Icons.tips_and_updates,
                'Study Tips',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pro subscribers get 60 ML Tokens monthly • Free users get limited tokens',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _TokenFeatureChip(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanCards(
      List<SubscriptionPlan> plans, Map<String, dynamic> copy) {
    return Column(
      children: [
        for (int i = 0; i < plans.length; i++) ...[
          _buildPlanCard(plans[i], i, copy),
          if (i < plans.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPlanCard(
      SubscriptionPlan plan, int index, Map<String, dynamic> copy) {
    final isSelected = _selectedPlanIndex == index;
    final showIntro = plan.hasIntroOffer && _remoteConfig.introEnabled;
    final showAnnualIntro = false; // No annual plans available

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? plan.accentColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? plan.accentColor
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            Row(
              children: [
                // Intro badge for monthly
                // if (showIntro && plan.type == SubscriptionType.proMonthly) // Pro Monthly removed
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: plan.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    copy['monthly_badge'],
                    style: TextStyle(
                      color: context.tokens.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Badge for annual
                if (plan.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.tokens.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.badge!,
                      style: TextStyle(
                        color: context.tokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const Spacer(),

                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? plan.accentColor
                          : context.tokens.outline,
                      width: 2,
                    ),
                    color: isSelected ? plan.accentColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check,
                          color: context.tokens.onPrimary, size: 16)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title and price
            Text(
              plan.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            // Pricing display for monthly
            if (showIntro) ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _getIntroPrice(),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: plan.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    TextSpan(
                      text: ' first month',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'then \$5.99/month, cancel anytime', // Pro Monthly removed
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ] else ...[
              Text(
                '\$5.99/month', // Pro Monthly removed
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: plan.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cancel anytime',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],

            const SizedBox(height: 16),

            // Features
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final feature in plan.features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: plan.accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> copy) {
    return Column(
      children: [
        // Primary button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _startProSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    copy['primary_button'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Secondary button
        TextButton(
          onPressed: _restorePurchases,
          child: Text(
            copy['secondary_button'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLinks() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _openPrivacyPolicy,
              child: Text(
                l10n.privacyPolicy,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
            Text(
              ' · ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            GestureDetector(
              onTap: _openTermsOfUse,
              child: Text(
                l10n.termsOfUse,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // GDPR compliance notice for EU users
        if (_isEUUser()) ...[
          Text(
            l10n.gdprNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _openDataProcessing,
            child: Text(
              l10n.dataProcessing,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.7),
                    decoration: TextDecoration.underline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Future<bool> _onWillPop() async {
    if (_showExitIntent || !_remoteConfig.logicPackEnabled) {
      _trackPaywallExit('back_button');
      Navigator.pop(context);
      return false;
    }

    // Show exit intent offer
    setState(() => _showExitIntent = true);
    return false;
  }

  void _startProSubscription() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final selectedPlan = SubscriptionPlan.availablePlans[_selectedPlanIndex];

      // Track purchase start with telemetry
      await _telemetry.trackPurchaseStart(
        productId: selectedPlan.productId,
        subscriptionType: selectedPlan.type,
      );

      final success = await _purchaseService.purchaseSubscription(selectedPlan);

      if (success && mounted) {
        _trackPaywallExit('purchase_success');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;

        // Track purchase failure
        await _telemetry.trackPurchaseFail(
          productId:
              SubscriptionPlan.availablePlans[_selectedPlanIndex].productId,
          errorCode: 'purchase_exception',
          errorMessage: 'Purchase failed. Please try again.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _buyLogicPack() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final success = await _purchaseService.purchaseLogicPack();

      if (success && mounted) {
        _trackPaywallExit('logic_pack_success');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Purchase failed. Please try again or contact support if the issue persists.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _restorePurchases() async {
    try {
      final success = await _purchaseService.restorePurchases();

      if (success && mounted) {
        final l10n = AppLocalizations.of(context)!;

        // Track restore success
        await _telemetry.trackRestoreSuccess(
          restoredProducts: [
            'restored'
          ], // Will be populated by purchase service
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseRestored)),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noPurchasesFound)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreFailed)),
        );
      }
    }
  }

  void _openPrivacyPolicy() async {
    final l10n = AppLocalizations.of(context)!;
    String url = 'https://mindload.app/privacy';

    // Use localized URLs when available
    if (l10n.locale.languageCode != 'en') {
      url += '?lang=${l10n.locale.languageCode}';
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _openTermsOfUse() async {
    final l10n = AppLocalizations.of(context)!;
    String url = 'https://mindload.app/terms';

    // Use localized URLs when available
    if (l10n.locale.languageCode != 'en') {
      url += '?lang=${l10n.locale.languageCode}';
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _openDataProcessing() async {
    const url = 'https://mindload.app/data-processing';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // Check if user is in EU for compliance display
  bool _isEUUser() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split('_');
      if (parts.length >= 2) {
        final country = parts[1].toUpperCase();
        const euCountries = [
          'DE',
          'FR',
          'IT',
          'ES',
          'NL',
          'BE',
          'AT',
          'CH',
          'DK',
          'SE',
          'NO',
          'FI',
          'PL',
          'CZ',
          'HU',
          'PT',
          'IE',
          'GR',
          'RO',
          'BG',
          'HR',
          'LT',
          'LV',
          'EE',
          'SI',
          'SK',
          'CY',
          'MT',
          'LU',
          'UK'
        ];
        return euCountries.contains(country);
      }
    } catch (e) {
      // Ignore error and default to false
    }
    return false;
  }

  String _getIntroPrice() {
    // Get intro price from PricingService or fallback
    return '\$2.99'; // Get from store pricing
  }

  Widget _buildLogicPacksSection() {
    final l10n = AppLocalizations.of(context)!;
    final copy = _remoteConfig.getLocalizedPaywallCopy(l10n);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'MindLoad Logic Packs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _remoteConfig.logicPacksDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _LogicPackChip(
                Icons.lightbulb_outline,
                ProductConstants.sparkPackName,
                _remoteConfig.sparkPackEnabled,
              ),
              _LogicPackChip(
                Icons.psychology,
                ProductConstants.neuroPackName,
                _remoteConfig.neuroBurstEnabled,
              ),
              _LogicPackChip(
                Icons.science,
                ProductConstants.cortexPackName,
                _remoteConfig.cortexPackEnabled,
              ),
              _LogicPackChip(
                Icons.electric_bolt,
                ProductConstants.synapsePackName,
                _remoteConfig.synapsePackEnabled,
              ),
              _LogicPackChip(
                Icons.auto_awesome,
                ProductConstants.quantumPackName,
                _remoteConfig.quantumPackEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _LogicPackChip(IconData icon, String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

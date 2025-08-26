import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/models/iap_firebase_models.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/services/firebase_remote_config_service.dart';
import 'package:mindload/services/firebase_iap_service.dart';
import 'package:mindload/services/international_iap_service.dart';

class IapPaywallScreen extends StatefulWidget {
  final String trigger;
  final bool showExitIntent;

  const IapPaywallScreen({
    super.key,
    this.trigger = 'unknown',
    this.showExitIntent = false,
  });

  @override
  State<IapPaywallScreen> createState() => _IapPaywallScreenState();
}

class _IapPaywallScreenState extends State<IapPaywallScreen> with TickerProviderStateMixin {
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;
  final FirebaseRemoteConfigService _remoteConfig = FirebaseRemoteConfigService.instance;
  final InternationalIapService _internationalIap = InternationalIapService.instance;

  int _selectedPlanIndex = 0; // Default to Pro Monthly
  bool _isLoading = false;
  bool _showExitIntent = false;
  DateTime? _paywallStartTime;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _recordPaywallView();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _recordPaywallExit('dispose');
    super.dispose();
  }

  void _recordPaywallView() async {
    try {
      // Record telemetry via Firebase IAP service directly
      await FirebaseIapService.instance.recordTelemetryEvent(IapTelemetryEvent.paywallView, {
        'trigger': widget.trigger,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Error recording paywall view - non-critical
    }
  }

  void _recordPaywallExit(String action) async {
    if (_paywallStartTime != null) {
      final timeSpent = DateTime.now().difference(_paywallStartTime!).inMilliseconds;
      try {
        await FirebaseIapService.instance.recordTelemetryEvent(IapTelemetryEvent.paywallView, {
          'action': action,
          'timeSpentMs': timeSpent,
          'selectedPlan': _selectedPlanIndex,
        });
      } catch (e) {
        // Error recording paywall exit - non-critical
      }
    }
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) return;
    
    if (_showExitIntent) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _showExitIntent = true;
    });
    _recordPaywallExit('back_button');
  }

  @override
  Widget build(BuildContext context) {
    final plans = _purchaseService.getAvailablePlans();
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _showExitIntent ? _buildExitIntentContent() : _buildMainContent(plans),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<SubscriptionPlan> plans) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha:  0.8),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            elevation: 0,
            leading: Container(
              alignment: Alignment.centerLeft,
              constraints: const BoxConstraints(maxWidth: 56, maxHeight: 56),
              child: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  _onPopInvokedWithResult(false, null);
                },
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44, maxWidth: 48, maxHeight: 48),
                padding: const EdgeInsets.all(8),
              ),
            ),
            automaticallyImplyLeading: false,
            leadingWidth: 56, // Prevent overflow
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildFeaturesList(),
                  const SizedBox(height: 32),
                  _buildPlanSelector(plans),
                  const SizedBox(height: 24),
                  _buildStarterPackOption(),
                  const SizedBox(height: 32),
                  _buildActionButtons(plans),
                  const SizedBox(height: 24),
                  _buildLegalText(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha:  0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.psychology,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Unlock MindLoad Pro',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Supercharge your learning with unlimited AI-powered study tools',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.flash_on, 'text': 'Unlimited AI generations'},
      {'icon': Icons.priority_high, 'text': 'Priority processing'},
      {'icon': Icons.timer, 'text': 'Ultra Study Mode with focus timer'},
      {'icon': Icons.headphones, 'text': 'Binaural beats audio'},
      {'icon': Icons.trending_up, 'text': 'Advanced progress tracking'},
      {'icon': Icons.cloud_sync, 'text': 'Cross-device sync'},
    ];

    return Column(
      children: features.map((feature) => _buildFeatureItem(
        feature['icon'] as IconData,
        feature['text'] as String,
      )).toList(),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha:  0.2),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(List<SubscriptionPlan> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose Your Plan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Column(
          children: plans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            return _buildPlanCard(plan, index, index == _selectedPlanIndex);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index, bool isSelected) {
    final bool showIntro = plan.hasIntroOffer && 
                          true; // No annual plans available
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha:  0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha:  0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:  0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha:  0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: plan.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plan.badge!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showIntro 
                        ? plan.introDescription ?? plan.displayPrice
                        : plan.displayPrice,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showIntro) ...[
                    const SizedBox(height: 2),
                    Text(
                      plan.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterPackOption() {
    if (!_remoteConfig.logicPackEnabled) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:  0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need credits now?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Get ${CreditQuotas.rolloverCap} credits instantly',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : _purchaseLogicPack,
            child: Text(
              'Buy Credits',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(List<SubscriptionPlan> plans) {
    final selectedPlan = plans[_selectedPlanIndex];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _purchaseSubscription(selectedPlan),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 8,
                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha:  0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Start Pro',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _restorePurchases,
          child: Text(
            'Restore Purchases',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.8),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        if (_purchaseService.canManageSubscriptions) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _openSubscriptionManagement(),
            child: Text(
              _purchaseService.getSubscriptionManagementLabel(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegalText() {
    return Column(
      children: [
        Text(
          'Auto-renew, cancel anytime in App Store/Google Play',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _launchUrl('https://mindload.app/privacy'),
              child: Text(
                'Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(' | ', style: Theme.of(context).textTheme.bodySmall),
            TextButton(
              onPressed: () => _launchUrl('https://mindload.app/terms'),
              child: Text(
                'Terms of Use',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExitIntentContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Wait! Don\'t miss out',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Start with our intro offer for your first month of Pro features!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showExitIntent = false;
                  _selectedPlanIndex = 0; // Select Pro Monthly
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(
                'Try Intro Offer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _recordPaywallExit('exit_intent_dismiss');
              Navigator.pop(context);
            },
            child: Text(
              'No thanks, maybe later',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha:  0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _purchaseSubscription(SubscriptionPlan plan) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _purchaseService.purchaseSubscription(plan);
      if (success && mounted) {
        _recordPaywallExit('purchase_success');
        Navigator.pop(context, true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to ${plan.title}!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase failed. Please try again or contact support if the issue persists.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _purchaseLogicPack() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _purchaseService.purchaseLogicPack();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased ${CreditQuotas.rolloverCap} credits!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase failed. Please try again or contact support if the issue persists.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _purchaseService.restoreEntitlements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Purchases restored successfully!'
                : 'No purchases found to restore'),
            backgroundColor: success 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Restore failed. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openSubscriptionManagement() async {
    final url = _purchaseService.getSubscriptionManagementUrl();
    if (url.isNotEmpty) {
      await _launchUrl(url);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Error launching URL - non-critical
    }
  }
}
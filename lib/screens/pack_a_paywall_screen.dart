import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:mindload/models/pricing_models.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/theme.dart';

/// Pack-A Paywall Screen
/// Shows only "Ultra Mode access" for paid tiers; Free shows "Preview only. No Ultra Mode"
class PackAPaywallScreen extends StatefulWidget {
  final String trigger;
  final bool showExitIntent;

  const PackAPaywallScreen({
    super.key,
    this.trigger = 'unknown',
    this.showExitIntent = false,
  });

  @override
  State<PackAPaywallScreen> createState() => _PackAPaywallScreenState();
}

class _PackAPaywallScreenState extends State<PackAPaywallScreen>
    with TickerProviderStateMixin {
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;

  int _selectedPlanIndex = 0;
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: tokens.bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _showExitIntent ? _buildExitIntentContent() : _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final tokens = context.tokens;
    final plans = SubscriptionPlan.availablePlans;

    return Column(
      children: [
        // Header
        _buildHeader(tokens),
        
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Main message
                _buildMainMessage(tokens),
                const SizedBox(height: 32),
                
                // Plan selector
                _buildPlanSelector(plans),
                const SizedBox(height: 32),
                
                // Action buttons
                _buildActionButtons(plans),
                const SizedBox(height: 24),
                
                // Legal links
                _buildLegalLinks(tokens),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.headerBg,
        border: Border(
          bottom: BorderSide(
            color: tokens.borderDefault.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: tokens.navIcon),
            tooltip: 'Close',
          ),
          Expanded(
            child: Text(
              'Choose Your Plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.navText,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildMainMessage(SemanticTokens tokens) {
    return Column(
      children: [
        Icon(
          Icons.flash_on,
          size: 64,
          color: tokens.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Unlock Ultra Mode',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Get distraction-free, high-focus study sessions with advanced features and unlimited MindLoad Tokens.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: tokens.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlanSelector(List<SubscriptionPlan> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Your Tier',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
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
    final tokens = context.tokens;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? plan.accentColor.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? plan.accentColor
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: plan.accentColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? plan.accentColor : tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? plan.accentColor : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? plan.accentColor : Colors.transparent,
                  ),
                  child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price
            Row(
              children: [
                Text(
                  plan.displayPrice,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: plan.accentColor,
                  ),
                ),
                if (plan.title.contains('Annual')) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      'SAVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Features
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: plan.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
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
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _purchaseSubscription(selectedPlan),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPlan.accentColor,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: selectedPlan.accentColor.withOpacity(0.3),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Start ${selectedPlan.title.split(' ')[0]}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLinks(SemanticTokens tokens) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            // Navigate to terms of service
          },
          child: Text(
            'Terms of Service',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to privacy policy
          },
          child: Text(
            'Privacy Policy',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExitIntentContent() {
    final tokens = context.tokens;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flash_on,
              size: 80,
              color: tokens.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Wait! Don\'t miss out on Ultra Mode',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Get distraction-free study sessions and unlock your full learning potential.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _showExitIntent = false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: tokens.primary),
                    ),
                    child: Text(
                      'Continue Browsing',
                      style: TextStyle(color: tokens.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showExitIntent = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: tokens.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('See Plans'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_paywallStartTime != null) {
      final timeSpent = DateTime.now().difference(_paywallStartTime!).inMilliseconds;
      _recordPaywallExit('exit_intent_triggered');
      
      if (timeSpent < 5000) { // Less than 5 seconds
        setState(() => _showExitIntent = true);
        return false;
      }
    }
    
    _recordPaywallExit('user_dismiss');
    return true;
  }

  void _recordPaywallExit(String action) {
    // TODO: Implement analytics tracking
    if (kDebugMode) {
      debugPrint('Paywall exit: $action');
    }
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
}

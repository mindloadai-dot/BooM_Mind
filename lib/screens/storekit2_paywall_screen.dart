import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/services/storekit2_service.dart';
import 'package:mindload/models/pricing_models.dart';

/// StoreKit 2 Paywall Screen - iOS-specific IAP implementation
/// Meets all Apple IAP requirements:
/// - Clear pricing and product information
/// - Localized content (Dynamic Type 120%, VoiceOver)
/// - Proper error handling and user feedback
/// - Restore purchases functionality
/// - Intro offer eligibility checking
class StoreKit2PaywallScreen extends StatefulWidget {
  const StoreKit2PaywallScreen({super.key});

  @override
  State<StoreKit2PaywallScreen> createState() => _StoreKit2PaywallScreenState();
}

class _StoreKit2PaywallScreenState extends State<StoreKit2PaywallScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  String? _errorMessage;
  final bool _showRestoreButton = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeStoreKit();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeStoreKit() async {
    try {
      final storeKit = StoreKit2Service.instance;
      if (!storeKit.isInitialized) {
        await storeKit.initialize();
      }
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize store: $e';
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler;

    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back),
        ),
        title: Text(
          'Upgrade to Pro',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: tokens.textPrimary,
            fontSize: textScaler.scale(20),
          ),
        ),
        actions: [
          if (_showRestoreButton)
            TextButton(
              onPressed: _isLoading ? null : _restorePurchases,
              child: Text(
                'Restore',
                style: TextStyle(
                  color: tokens.primary,
                  fontSize: textScaler.scale(16),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Consumer<StoreKit2Service>(
            builder: (context, storeKit, child) {
              if (!storeKit.isAvailable) {
                return _buildStoreUnavailable(tokens, textScaler);
              }

              if (storeKit.products.isEmpty) {
                return _buildLoadingState(tokens, textScaler);
              }

              return _buildPaywallContent(storeKit, tokens, textScaler);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStoreUnavailable(SemanticTokens tokens, TextScaler textScaler) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 64,
              color: tokens.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Store Unavailable',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: tokens.textPrimary,
                fontSize: textScaler.scale(24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'In-app purchases are not available on this device.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: tokens.textSecondary,
                fontSize: textScaler.scale(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(SemanticTokens tokens, TextScaler textScaler) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Products...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: tokens.textSecondary,
              fontSize: textScaler.scale(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallContent(StoreKit2Service storeKit, SemanticTokens tokens, TextScaler textScaler) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          _buildHeader(tokens, textScaler),
          const SizedBox(height: 32),

          // MindLoad Tokens Explanation
          _buildTokensExplanation(tokens, textScaler),
          const SizedBox(height: 32),

          // Product Cards
          ..._buildProductCards(storeKit, tokens, textScaler),
          const SizedBox(height: 32),

          // Error Message
          if (_errorMessage != null)
            _buildErrorMessage(_errorMessage!, tokens, textScaler),

          // Terms and Privacy
          _buildTermsAndPrivacy(tokens, textScaler),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(SemanticTokens tokens, TextScaler textScaler) {
    return Column(
      children: [
        Icon(
          Icons.auto_awesome,
          size: 64,
          color: tokens.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock Your Learning Potential',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: tokens.textPrimary,
            fontSize: textScaler.scale(28),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get unlimited AI-powered study materials and advanced features',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: tokens.textSecondary,
            fontSize: textScaler.scale(18),
          ),
        ),
      ],
    );
  }

  Widget _buildTokensExplanation(SemanticTokens tokens, TextScaler textScaler) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.token,
                color: tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'What are MindLoad Tokens?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.primary,
                  fontSize: textScaler.scale(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'MindLoad Tokens (ML Tokens) are the currency that powers AI-powered learning features. Each token lets you generate study materials like flashcards, quizzes, and study tips.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              fontSize: textScaler.scale(16),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildFeatureChip(
                Icons.auto_awesome,
                'AI Generation',
                tokens,
                textScaler,
              ),
              _buildFeatureChip(
                Icons.quiz,
                'Smart Quizzes',
                tokens,
                textScaler,
              ),
              _buildFeatureChip(
                Icons.tips_and_updates,
                'Study Tips',
                tokens,
                textScaler,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, SemanticTokens tokens, TextScaler textScaler) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: tokens.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textPrimary,
              fontSize: textScaler.scale(12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductCards(StoreKit2Service storeKit, SemanticTokens tokens, TextScaler textScaler) {
    final products = storeKit.products;
    final List<Widget> cards = [];

    // Add subscription plans
    for (final plan in SubscriptionPlan.availablePlans) {
      ProductDetails? product;
      try {
        product = products.firstWhere((p) => p.id == plan.productId);
      } catch (e) {
        product = null;
      }
      
      if (product != null) {
        cards.add(
          _buildSubscriptionCard(plan, product, storeKit, tokens, textScaler),
        );
        cards.add(const SizedBox(height: 16));
      }
    }

    // Add starter pack
    ProductDetails? starterPack;
    try {
      starterPack = products.firstWhere((p) => p.id == ProductIds.logicPack);
    } catch (e) {
      starterPack = null;
    }
    
    if (starterPack != null) {
      cards.add(
        _buildStarterPackCard(starterPack, storeKit, tokens, textScaler),
      );
    }

    return cards;
  }

  Widget _buildSubscriptionCard(
    SubscriptionPlan plan,
    ProductDetails product,
    StoreKit2Service storeKit,
    SemanticTokens tokens,
    TextScaler textScaler,
  ) {
    final isIntroEligible = plan.hasIntroOffer;
    
    return Container(
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: plan.accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                if (plan.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: plan.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.badge!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: textScaler.scale(10),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (plan.badge != null) const SizedBox(height: 8),
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontSize: textScaler.scale(24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    fontSize: textScaler.scale(16),
                  ),
                ),
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: tokens.success,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontSize: textScaler.scale(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // Price and Action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                if (isIntroEligible && plan.introPrice != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tokens.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${plan.introDescription}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.warning,
                        fontSize: textScaler.scale(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isIntroEligible && plan.introPrice != null) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.displayPrice,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontSize: textScaler.scale(28),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (isIntroEligible && plan.introPrice != null)
                            Text(
                              'then ${plan.displayPrice}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: tokens.textSecondary,
                                fontSize: textScaler.scale(14),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _purchaseProduct(plan.productId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: plan.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isIntroEligible ? 'Start Free Trial' : 'Subscribe',
                                style: TextStyle(
                                  fontSize: textScaler.scale(16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterPackCard(
    ProductDetails product,
    StoreKit2Service storeKit,
    SemanticTokens tokens,
    TextScaler textScaler,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.borderDefault,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.overlayDim.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CreditPack.logicPack.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_circle,
                    color: CreditPack.logicPack.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CreditPack.logicPack.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: tokens.textPrimary,
                          fontSize: textScaler.scale(20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        CreditPack.logicPack.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          fontSize: textScaler.scale(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    CreditPack.logicPack.displayPrice,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontSize: textScaler.scale(24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _purchaseProduct(ProductIds.logicPack),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CreditPack.logicPack.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Buy Now',
                            style: TextStyle(
                              fontSize: textScaler.scale(16),
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildErrorMessage(String message, SemanticTokens tokens, TextScaler textScaler) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: tokens.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.error,
                fontSize: textScaler.scale(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacy(SemanticTokens tokens, TextScaler textScaler) {
    return Column(
      children: [
        Text(
          'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tokens.textTertiary,
            fontSize: textScaler.scale(12),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Navigate to Terms of Service
              },
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  color: tokens.primary,
                  fontSize: textScaler.scale(14),
                ),
              ),
            ),
            Text(
              '•',
              style: TextStyle(
                color: tokens.textTertiary,
                fontSize: textScaler.scale(14),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Privacy Policy
              },
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: tokens.primary,
                  fontSize: textScaler.scale(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _purchaseProduct(String productId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storeKit = StoreKit2Service.instance;
      final success = await storeKit.purchaseProduct(productId);
      
      if (success) {
        // Purchase initiated successfully
        // The result will be handled by the purchase stream
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase initiated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to initiate purchase. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Purchase failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storeKit = StoreKit2Service.instance;
      final success = await storeKit.restorePurchases();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchases restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to restore purchases. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Restore failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';

import 'package:mindload/theme.dart';
import 'package:mindload/models/mindload_economy_models.dart';

class LogicPacksScreen extends StatefulWidget {
  const LogicPacksScreen({super.key});

  @override
  State<LogicPacksScreen> createState() => _LogicPacksScreenState();
}

class _LogicPacksScreenState extends State<LogicPacksScreen> {
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MindloadAppBarFactory.secondary(
        title: 'Logic Packs',
      ),
      body: Consumer<MindloadEconomyService>(
        builder: (context, economyService, child) {
          final userEconomy = economyService.userEconomy;
          if (userEconomy == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),
                const SizedBox(height: 24),

                // Current Token Status
                _buildCurrentTokenStatus(userEconomy),
                const SizedBox(height: 24),

                // Logic Packs Grid
                _buildLogicPacksGrid(),
                const SizedBox(height: 24),

                // How It Works Section
                _buildHowItWorksSection(),
                const SizedBox(height: 24),

                // FAQ Section
                _buildFAQSection(),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logic Packs',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'One-time purchases for additional MindLoad tokens. Perfect for exam weeks, intensive study sessions, or when you need extra processing power.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: tokens.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Logic Packs never expire and can be used alongside your monthly subscription tokens.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTokenStatus(MindloadUserEconomy userEconomy) {
    final tokens = context.tokens;
    final tierConfig = MindloadEconomyConfig.tierConfigs[userEconomy.tier];
    final monthlyQuota = tierConfig?.monthlyTokens ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: tokens.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Your Token Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Allowance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                      Text(
                        '${userEconomy.creditsRemaining} / $monthlyQuota',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rollover Tokens',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                      Text(
                        '${userEconomy.rolloverCredits}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tokens.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (userEconomy.rolloverCredits > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: tokens.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'You have ${userEconomy.rolloverCredits} rollover tokens from previous months!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogicPacksGrid() {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Logic Packs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
          children: [
            _buildLogicPackCard(
              'Spark Pack',
              '50 Tokens',
              4.99,
              Icons.flash_on,
              Colors.amber,
              'Perfect for quick study sessions',
              [
                '5-10 flashcards',
                '3-5 quiz questions',
                'Small document processing'
              ],
            ),
            _buildLogicPackCard(
              'Neuro Pack',
              '150 Tokens',
              12.99,
              Icons.psychology,
              Colors.blue,
              'Great for weekly reviews',
              [
                '15-30 flashcards',
                '10-15 quiz questions',
                'Medium document processing'
              ],
            ),
            _buildLogicPackCard(
              'Cortex Pack',
              '500 Tokens',
              39.99,
              Icons.memory,
              Colors.purple,
              'Ideal for exam preparation',
              [
                '50-100 flashcards',
                '30-50 quiz questions',
                'Large document processing'
              ],
            ),
            _buildLogicPackCard(
              'Singularity Pack',
              '1500 Tokens',
              99.99,
              Icons.rocket_launch,
              Colors.orange,
              'Ultimate study power',
              [
                '150-300 flashcards',
                '100-150 quiz questions',
                'Multiple large documents'
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogicPackCard(
    String name,
    String tokenCount,
    double price,
    IconData icon,
    Color color,
    String description,
    List<String> features,
  ) {
    final tokens = context.tokens;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _handleLogicPackPurchase(name, price),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tokenCount,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title and Price
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
              ),

              const Spacer(),

              // Features
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            feature,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: tokens.textSecondary,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 12),

              // Buy Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleLogicPackPurchase(name, price),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: context.tokens.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How Logic Packs Work',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        _buildHowItWorksStep(
          1,
          'Purchase',
          'Choose your Logic Pack and complete the purchase through your device\'s app store.',
          Icons.shopping_cart,
        ),
        _buildHowItWorksStep(
          2,
          'Instant Delivery',
          'Tokens are added to your account immediately after successful purchase verification.',
          Icons.flash_on,
        ),
        _buildHowItWorksStep(
          3,
          'Use Anytime',
          'Logic Pack tokens never expire and can be used alongside your monthly allowance.',
          Icons.schedule,
        ),
        _buildHowItWorksStep(
          4,
          'Track Usage',
          'Monitor your token balance and usage in the My Plan section.',
          Icons.analytics,
        ),
      ],
    );
  }

  Widget _buildHowItWorksStep(
      int step, String title, String description, IconData icon) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$step',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.primary,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(icon, color: tokens.primary, size: 24),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          'Do Logic Pack tokens expire?',
          'No, Logic Pack tokens never expire. They remain in your account until you use them.',
        ),
        _buildFAQItem(
          'Can I use Logic Pack tokens with my subscription?',
          'Yes! Logic Pack tokens work alongside your monthly subscription tokens. You can use both types of tokens for any feature.',
        ),
        _buildFAQItem(
          'What happens if I upgrade my subscription?',
          'Your Logic Pack tokens remain available. When you upgrade, you\'ll have both your new monthly allowance and your existing Logic Pack tokens.',
        ),
        _buildFAQItem(
          'Can I gift Logic Packs to others?',
          'Currently, Logic Packs are tied to the purchasing account. We\'re working on gifting features for future updates.',
        ),
        _buildFAQItem(
          'Are Logic Packs available in all countries?',
          'Logic Packs are available in all countries where MindLoad is available. Pricing may vary based on your local currency.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final tokens = context.tokens;

    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogicPackPurchase(String packName, double price) async {
    setState(() => _isLoading = true);

    try {
      // Show confirmation dialog
      final confirmed = await _showPurchaseConfirmation(packName, price);
      if (!confirmed) return;

      // Navigate to MyPlanScreen for purchase options
      // This would typically integrate with your IAP service
      Navigator.pushNamed(context, '/my-plan');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showPurchaseConfirmation(String packName, double price) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Purchase'),
            content: Text(
                'Are you sure you want to purchase the $packName for \$${price.toStringAsFixed(2)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Purchase'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

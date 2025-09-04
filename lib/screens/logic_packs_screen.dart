import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mindload/services/mindload_economy_service.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/widgets/unified_design_system.dart';

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
            padding: UnifiedSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(),
                SizedBox(height: UnifiedSpacing.lg),

                // Current Token Status
                _buildCurrentTokenStatus(userEconomy),
                SizedBox(height: UnifiedSpacing.lg),

                // Logic Packs Grid
                _buildLogicPacksGrid(),
                SizedBox(height: UnifiedSpacing.lg),

                // How It Works Section
                _buildHowItWorksSection(),
                SizedBox(height: UnifiedSpacing.lg),

                // FAQ Section
                _buildFAQSection(),
                SizedBox(height: UnifiedSpacing.xxxl), // Bottom padding
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
        UnifiedText(
          'Logic Packs',
          style: UnifiedTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        SizedBox(height: UnifiedSpacing.sm),
        UnifiedText(
          'One-time purchases for additional MindLoad tokens. Perfect for exam weeks, intensive study sessions, or when you need extra processing power.',
          style: UnifiedTypography.bodyLarge.copyWith(
                color: tokens.textSecondary,
                height: 1.5,
              ),
        ),
        SizedBox(height: UnifiedSpacing.md),
        UnifiedCard(
          padding: UnifiedSpacing.cardPadding,
          borderRadius: UnifiedBorderRadius.mdRadius,
          child: Row(
            children: [
              UnifiedIcon(Icons.lightbulb_outline, color: tokens.primary, size: 24),
              SizedBox(width: UnifiedSpacing.sm),
              Expanded(
                child: UnifiedText(
                  'Logic Packs never expire and can be used alongside your monthly subscription tokens.',
                  style: UnifiedTypography.bodyMedium.copyWith(
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

    return UnifiedCard(
      elevation: 2,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: Padding(
        padding: UnifiedSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UnifiedIcon(Icons.account_balance_wallet,
                    color: tokens.primary, size: 28),
                SizedBox(width: UnifiedSpacing.sm),
                UnifiedText(
                  'Your Token Balance',
                  style: UnifiedTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.textPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(height: UnifiedSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnifiedText(
                        'Monthly Allowance',
                        style: UnifiedTypography.bodyMedium.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                      UnifiedText(
                        '${userEconomy.creditsRemaining} / $monthlyQuota',
                        style: UnifiedTypography.titleLarge.copyWith(
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
                      UnifiedText(
                        'Rollover Tokens',
                        style: UnifiedTypography.bodyMedium.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                      UnifiedText(
                        '${userEconomy.rolloverCredits}',
                        style: UnifiedTypography.titleLarge.copyWith(
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
                             SizedBox(height: UnifiedSpacing.sm),
               UnifiedCard(
                 padding: EdgeInsets.all(UnifiedSpacing.sm),
                 borderRadius: UnifiedBorderRadius.mdRadius,
                 border: Border.all(color: tokens.primary.withValues(alpha: 0.3)),
                 child: UnifiedText(
                  'You have ${userEconomy.rolloverCredits} rollover tokens from previous months!',
                  style: UnifiedTypography.bodySmall.copyWith(
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
        UnifiedText(
          'Available Logic Packs',
          style: UnifiedTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        SizedBox(height: UnifiedSpacing.md),
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

    return UnifiedCard(
      elevation: 3,
      borderRadius: UnifiedBorderRadius.lgRadius,
      child: InkWell(
        onTap: () => _handleLogicPackPurchase(name, price),
        borderRadius: UnifiedBorderRadius.lgRadius,
        child: Padding(
          padding: UnifiedSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                                     UnifiedCard(
                     padding: EdgeInsets.all(UnifiedSpacing.sm),
                     borderRadius: UnifiedBorderRadius.mdRadius,
                     child: UnifiedIcon(icon, color: color, size: 24),
                   ),
                   SizedBox(width: UnifiedSpacing.sm),
                   UnifiedCard(
                     padding: EdgeInsets.all(UnifiedSpacing.sm),
                     borderRadius: UnifiedBorderRadius.mdRadius,
                     child: UnifiedText(
                      tokenCount,
                      style: UnifiedTypography.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: UnifiedSpacing.md),

              // Title and Price
              UnifiedText(
                name,
                style: UnifiedTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
              ),
              SizedBox(height: UnifiedSpacing.sm),
              UnifiedText(
                '\$${price.toStringAsFixed(2)}',
                style: UnifiedTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),

              SizedBox(height: UnifiedSpacing.sm),

              // Description
              UnifiedText(
                description,
                style: UnifiedTypography.bodySmall.copyWith(
                      color: tokens.textSecondary,
                    ),
              ),

              SizedBox(height: UnifiedSpacing.sm),

              // Features
                              ...features.map((feature) => Padding(
                     padding: EdgeInsets.only(bottom: UnifiedSpacing.xs),
                     child: Row(
                       children: [
                         UnifiedIcon(Icons.check_circle, color: color, size: 14),
                         SizedBox(width: UnifiedSpacing.sm),
                         Expanded(
                           child: UnifiedText(
                             feature,
                             style:
                                 UnifiedTypography.bodySmall.copyWith(
                                       color: tokens.textSecondary,
                                     ),
                           ),
                         ),
                       ],
                     ),
                   )),

               SizedBox(height: UnifiedSpacing.md),

               // Buy Button
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () => _handleLogicPackPurchase(name, price),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: color,
                     foregroundColor: context.tokens.onPrimary,
                     shape: RoundedRectangleBorder(
                       borderRadius: UnifiedBorderRadius.mdRadius,
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
        UnifiedText(
          'How Logic Packs Work',
          style: UnifiedTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        SizedBox(height: UnifiedSpacing.md),
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
       padding: EdgeInsets.only(bottom: UnifiedSpacing.md),
       child: Row(
         children: [
           Container(
             width: 40,
             height: 40,
             decoration: BoxDecoration(
               color: tokens.primary.withValues(alpha: 0.2),
               borderRadius: UnifiedBorderRadius.mdRadius,
             ),
             child: Center(
               child: UnifiedText(
                 '$step',
                 style: UnifiedTypography.titleMedium.copyWith(
                       fontWeight: FontWeight.bold,
                       color: tokens.primary,
                     ),
               ),
             ),
           ),
           SizedBox(width: UnifiedSpacing.md),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 UnifiedText(
                   title,
                   style: UnifiedTypography.titleMedium.copyWith(
                         fontWeight: FontWeight.bold,
                         color: tokens.textPrimary,
                       ),
                 ),
                 SizedBox(height: UnifiedSpacing.sm),
                 UnifiedText(
                   description,
                   style: UnifiedTypography.bodyMedium.copyWith(
                         color: tokens.textSecondary,
                       ),
                 ),
               ],
             ),
           ),
           UnifiedIcon(icon, color: tokens.primary, size: 24),
         ],
       ),
     );
  }

  Widget _buildFAQSection() {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedText(
          'Frequently Asked Questions',
          style: UnifiedTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
        ),
        SizedBox(height: UnifiedSpacing.md),
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
     title: UnifiedText(
       question,
       style: UnifiedTypography.titleMedium.copyWith(
             fontWeight: FontWeight.w600,
             color: tokens.textPrimary,
           ),
     ),
     children: [
       Padding(
         padding: EdgeInsets.fromLTRB(UnifiedSpacing.md, 0, UnifiedSpacing.md, UnifiedSpacing.md),
         child: UnifiedText(
           answer,
           style: UnifiedTypography.bodyMedium.copyWith(
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
           content: UnifiedText('Purchase failed: ${e.toString()}'),
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
            title: UnifiedText('Confirm Purchase'),
            content: UnifiedText(
                'Are you sure you want to purchase the $packName for \$${price.toStringAsFixed(2)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: UnifiedText('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: UnifiedText('Purchase'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

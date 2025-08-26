import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindload/models/iap_firebase_models.dart';
import 'package:mindload/services/in_app_purchase_service.dart';
import 'package:mindload/services/firebase_iap_service.dart';
import 'package:mindload/services/firebase_remote_config_service.dart';

class IapSubscriptionScreen extends StatefulWidget {
  const IapSubscriptionScreen({super.key});

  @override
  State<IapSubscriptionScreen> createState() => _IapSubscriptionScreenState();
}

class _IapSubscriptionScreenState extends State<IapSubscriptionScreen> {
  final InAppPurchaseService _purchaseService = InAppPurchaseService.instance;
  final FirebaseIapService _firebaseIap = FirebaseIapService.instance;
  final FirebaseRemoteConfigService _remoteConfig =
      FirebaseRemoteConfigService.instance;

  FirebaseUser? _userData;
  UserEntitlement? _entitlement;
  List<CreditLedgerEntry> _creditHistory = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _firebaseIap.getCurrentUserData(),
        _firebaseIap.getCurrentEntitlement(),
        _firebaseIap.getCreditLedger(limit: 20),
      ]);

      _userData = futures[0] as FirebaseUser?;
      _entitlement = futures[1] as UserEntitlement?;
      _creditHistory = futures[2] as List<CreditLedgerEntry>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading subscription data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadSubscriptionData();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Subscription',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  )
                : Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubscriptionCard(),
                    const SizedBox(height: 24),
                    _buildCreditsCard(),
                    const SizedBox(height: 24),
                    _buildManagementActions(),
                    const SizedBox(height: 24),
                    _buildCreditHistory(),
                    const SizedBox(height: 24),
                    _buildDebugInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildSubscriptionCard() {
    final isActive = _entitlement?.status == EntitlementStatus.active;
    final tier = _userData?.tier ?? UserTier.free;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isActive
              ? [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary
                ]
              : [
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                  Theme.of(context).colorScheme.surface
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.diamond : Icons.person,
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTierDisplayName(tier),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: isActive
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      _getStatusDescription(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isActive
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withValues(alpha: 0.9)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
          ),
          if (_userData?.renewalDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isActive
                        ? Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.8)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next billing: ${_formatDate(_userData!.renewalDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.8)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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

  Widget _buildCreditsCard() {
    final credits = _userData?.credits ?? 0;
    final tier = _userData?.tier ?? UserTier.free;

    int monthlyQuota;
    switch (tier) {
      case UserTier.free:
        monthlyQuota = CreditQuotas.free;
        break;
      case UserTier.proMonthly:
      case UserTier.proAnnual:
        monthlyQuota = CreditQuotas.pro;
        break;
    }

    final usagePercentage =
        monthlyQuota > 0 ? (credits / monthlyQuota).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Credits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const Spacer(),
              Text(
                '$credits',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
                      'Monthly quota: $monthlyQuota',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: usagePercentage,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercentage > 0.8
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tier == UserTier.free) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Pro for ${CreditQuotas.pro} credits per month',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
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

  Widget _buildManagementActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Subscription',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.restore,
          title: 'Restore Purchases',
          subtitle: 'Restore your previous purchases',
          onTap: _restorePurchases,
        ),
        if (_remoteConfig.manageLinksEnabled) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.settings,
            title: _purchaseService.getSubscriptionManagementLabel(),
            subtitle: 'Manage billing and renewal settings',
            onTap: _openSubscriptionManagement,
          ),
        ],
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.sync,
          title: 'Sync Account',
          subtitle: 'Force sync with server',
          onTap: _triggerSync,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditHistory() {
    if (_creditHistory.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credit History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: _creditHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final ledgerEntry = entry.value;
              final isLast = index == _creditHistory.length - 1;

              return _buildCreditHistoryItem(ledgerEntry, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditHistoryItem(CreditLedgerEntry entry, bool isLast) {
    final isPositive = entry.delta > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPositive
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCreditReasonDisplay(entry.reason),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${entry.delta}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    if (_userData == null && _entitlement == null) {
      return const SizedBox();
    }

    return ExpansionTile(
      title: Text(
        'Debug Information',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_userData != null) ...[
                Text('User Data:',
                    style: Theme.of(context).textTheme.titleSmall),
                Text('Tier: ${_userData!.tier.name}'),
                Text('Credits: ${_userData!.credits}'),
                Text('Platform: ${_userData!.platform.name}'),
                Text('Intro Used: ${_userData!.introUsed}'),
                if (_userData!.renewalDate != null)
                  Text('Renewal: ${_userData!.renewalDate!.toIso8601String()}'),
                const SizedBox(height: 12),
              ],
              if (_entitlement != null) ...[
                Text('Entitlement:',
                    style: Theme.of(context).textTheme.titleSmall),
                Text('Status: ${_entitlement!.status.name}'),
                Text('Product ID: ${_entitlement!.productId ?? 'None'}'),
                Text('Platform: ${_entitlement!.platform?.name ?? 'None'}'),
                Text('Auto Renew: ${_entitlement!.autoRenew}'),
                if (_entitlement!.lastVerifiedAt != null)
                  Text(
                      'Last Verified: ${_entitlement!.lastVerifiedAt!.toIso8601String()}'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getTierDisplayName(UserTier tier) {
    switch (tier) {
      case UserTier.free:
        return 'Free Plan';
      case UserTier.proMonthly:
        return 'Pro Monthly';
      case UserTier.proAnnual:
        return 'Pro Annual';
    }
  }

  String _getStatusDescription() {
    if (_entitlement?.status == EntitlementStatus.active) {
      return 'Active subscription with full access';
    } else if (_entitlement?.status == EntitlementStatus.grace) {
      return 'Grace period - subscription will renew soon';
    } else if (_entitlement?.status == EntitlementStatus.expired) {
      return 'Subscription has expired';
    } else {
      return 'Free account with limited features';
    }
  }

  String _getCreditReasonDisplay(String reason) {
    switch (reason) {
      case 'intro_month_grant':
        return 'Intro month credits';
      case 'monthly_renewal':
        return 'Monthly credit renewal';
      case 'annual_subscription':
        return 'Annual subscription credits';
      case 'starter_pack_purchase':
        return 'Starter pack purchase';
      case 'credit_usage':
        return 'Credit used for generation';
      default:
        return reason.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _restorePurchases() async {
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
        if (success) {
          await _refreshData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _openSubscriptionManagement() async {
    final url = _purchaseService.getSubscriptionManagementUrl();
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error launching subscription management: $e');
        }
      }
    }
  }

  void _triggerSync() async {
    try {
      await _firebaseIap.triggerReconciliation();
      await _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account synced successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

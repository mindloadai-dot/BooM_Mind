import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/services/achievement_service.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';

import 'package:mindload/theme.dart';
import 'package:mindload/models/achievement_models.dart';

/// Modernized Achievements Hub Screen with clear achievement instructions
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Animation controllers
  late AnimationController _headerController;
  late AnimationController _progressController;
  late AnimationController _tabAnimationController;
  late AnimationController _achievementController;

  // Animations
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _progressScaleAnimation;
  late Animation<double> _progressFillAnimation;
  late Animation<double> _tabSlideAnimation;
  late Animation<double> _achievementScaleAnimation;
  late Animation<double> _achievementFadeAnimation;

  // Tab indices
  static const int _allTab = 0;
  static const int _earnedTab = 1;
  static const int _progressTab = 2;
  static const int _lockedTab = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();

    // Initialize achievement service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAchievementService();
    });
  }

  void _initializeAnimations() {
    // Header Animations
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    // Progress Animations
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.elasticOut),
    );

    _progressFillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // Tab Animations
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _tabSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
          parent: _tabAnimationController, curve: Curves.easeOutQuart),
    );

    // Achievement Animations
    _achievementController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _achievementScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
          parent: _achievementController, curve: Curves.easeOutBack),
    );

    _achievementFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _achievementController, curve: Curves.easeIn),
    );

    // Start animations
    _headerController.forward();
    _progressController.forward();
    _tabAnimationController.forward();
    _achievementController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    _progressController.dispose();
    _tabAnimationController.dispose();
    _achievementController.dispose();
    super.dispose();
  }

  Future<void> _initializeAchievementService() async {
    try {
      await AchievementService.instance.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load achievements: ${e.toString()}'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: MindloadAppBarFactory.secondary(
        title: 'Achievements',
        actions: [
          IconButton(
            onPressed: _refreshAchievements,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Achievements',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with Progress Overview
          _buildHeaderSection(tokens, theme),

          // Tab Bar
          _buildTabBar(tokens, theme),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(tokens, theme),
                _buildEarnedTab(tokens, theme),
                _buildProgressTab(tokens, theme),
                _buildLockedTab(tokens, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(SemanticTokens tokens, ThemeData theme) {
    final totalAchievements = AchievementService.instance.catalog.length;
    final earnedAchievements = AchievementService.instance
        .getAchievementsByStatus(AchievementStatus.earned)
        .length;
    final progressAchievements = AchievementService.instance
        .getAchievementsByStatus(AchievementStatus.inProgress)
        .length;
    final completionRate =
        totalAchievements > 0 ? (earnedAchievements / totalAchievements) : 0.0;

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_headerSlideAnimation.value, 0),
          child: Opacity(
            opacity: _headerFadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Title and Stats
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 32,
                        color: tokens.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Achievement Progress',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              '$earnedAchievements of $totalAchievements completed',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress Bar
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _progressScaleAnimation.value,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completion Rate',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: tokens.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${(completionRate * 100).toInt()}%',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: tokens.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _progressFillAnimation.value *
                                    completionRate,
                                backgroundColor: tokens.muted,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    tokens.primary),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Earned',
                          earnedAchievements.toString(),
                          Icons.check_circle,
                          tokens.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'In Progress',
                          progressAchievements.toString(),
                          Icons.trending_up,
                          tokens.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Locked',
                          (totalAchievements -
                                  earnedAchievements -
                                  progressAchievements)
                              .toString(),
                          Icons.lock,
                          tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(SemanticTokens tokens, ThemeData theme) {
    return AnimatedBuilder(
      animation: _tabAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _tabSlideAnimation.value),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border(
                bottom:
                    BorderSide(color: tokens.outline.withValues(alpha: 0.2)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: tokens.primary,
              unselectedLabelColor: tokens.textSecondary,
              indicatorColor: tokens.primary,
              indicatorWeight: 3,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Earned'),
                Tab(text: 'In Progress'),
                Tab(text: 'Locked'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllTab(SemanticTokens tokens, ThemeData theme) {
    final achievements = AchievementService.instance.catalog
        .map((catalog) {
          final userState =
              AchievementService.instance.userAchievements[catalog.id];
          if (userState == null) return null;
          return AchievementDisplay(catalog: catalog, userState: userState);
        })
        .where((achievement) => achievement != null)
        .cast<AchievementDisplay>()
        .toList();

    if (achievements.isEmpty) {
      return _buildEmptyState(tokens, theme, 'No achievements available');
    }

    return _buildAchievementsList(tokens, theme, achievements);
  }

  Widget _buildEarnedTab(SemanticTokens tokens, ThemeData theme) {
    final achievements = AchievementService.instance
        .getAchievementsByStatus(AchievementStatus.earned);

    if (achievements.isEmpty) {
      return _buildEmptyState(tokens, theme, 'No achievements earned yet');
    }

    return _buildAchievementsList(tokens, theme, achievements);
  }

  Widget _buildProgressTab(SemanticTokens tokens, ThemeData theme) {
    final achievements = AchievementService.instance
        .getAchievementsByStatus(AchievementStatus.inProgress);

    if (achievements.isEmpty) {
      return _buildEmptyState(tokens, theme, 'No achievements in progress');
    }

    return _buildAchievementsList(tokens, theme, achievements);
  }

  Widget _buildLockedTab(SemanticTokens tokens, ThemeData theme) {
    final achievements = AchievementService.instance
        .getAchievementsByStatus(AchievementStatus.locked);

    if (achievements.isEmpty) {
      return _buildEmptyState(tokens, theme, 'No locked achievements');
    }

    return _buildAchievementsList(tokens, theme, achievements);
  }

  Widget _buildEmptyState(
      SemanticTokens tokens, ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: tokens.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(SemanticTokens tokens, ThemeData theme,
      List<AchievementDisplay> achievements) {
    return AnimatedBuilder(
      animation: _achievementController,
      builder: (context, child) {
        return Transform.scale(
          scale: _achievementScaleAnimation.value,
          child: Opacity(
            opacity: _achievementFadeAnimation.value,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementCard(tokens, theme, achievement);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementCard(
      SemanticTokens tokens, ThemeData theme, AchievementDisplay achievement) {
    final progress = achievement.progressPercent;
    final isEarned = achievement.userState.status == AchievementStatus.earned;
    final isInProgress =
        achievement.userState.status == AchievementStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEarned
              ? tokens.success.withValues(alpha: 0.4)
              : isInProgress
                  ? tokens.warning.withValues(alpha: 0.4)
                  : tokens.outline.withValues(alpha: 0.2),
          width: isEarned || isInProgress ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.outline.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showAchievementDetails(achievement),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Achievement Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getTierColor(achievement.catalog.tier, tokens)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getTierColor(achievement.catalog.tier, tokens)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          achievement.catalog.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Achievement Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.catalog.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.catalog.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tier Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTierColor(achievement.catalog.tier, tokens)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getTierColor(achievement.catalog.tier, tokens)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        achievement.catalog.tier.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              _getTierColor(achievement.catalog.tier, tokens),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Progress Section
                if (!isEarned) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${achievement.userState.progress}/${achievement.catalog.threshold}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: tokens.muted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isInProgress ? tokens.warning : tokens.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.toInt()}% Complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ] else ...[
                  // Earned Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: tokens.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: tokens.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: tokens.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Achievement Unlocked!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Modern How to Obtain Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tokens.primary.withValues(alpha: 0.08),
                        tokens.primary.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tokens.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with icon and title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tokens.primary.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: tokens.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.rocket_launch,
                                color: tokens.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How to Unlock',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: tokens.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Follow these steps to earn this achievement',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          tokens.primary.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.catalog.howTo,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.textPrimary,
                                height: 1.5,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Modern action button
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    tokens.primary,
                                    tokens.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        tokens.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      _showAchievementDetails(achievement),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isEarned
                                            ? Icons.celebration
                                            : Icons.auto_awesome,
                                        color: tokens.onPrimary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEarned
                                            ? 'View Achievement'
                                            : 'Learn More',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: tokens.onPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTierColor(AchievementTier tier, SemanticTokens tokens) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.legendary:
        return const Color(0xFFFF6B35);
    }
  }

  void _showAchievementDetails(AchievementDisplay achievement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AchievementDetailsSheet(achievement: achievement),
    );
  }

  void _refreshAchievements() async {
    try {
      await AchievementService.instance.initialize();
      if (mounted) setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Achievements refreshed!'),
          backgroundColor: context.tokens.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }
}

// Achievement Details Bottom Sheet
class _AchievementDetailsSheet extends StatelessWidget {
  final AchievementDisplay achievement;

  const _AchievementDetailsSheet({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Achievement Header
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getTierColor(achievement.catalog.tier, tokens)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getTierColor(achievement.catalog.tier, tokens)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          achievement.catalog.icon,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.catalog.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getTierColor(
                                      achievement.catalog.tier, tokens)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              achievement.catalog.tier.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _getTierColor(
                                    achievement.catalog.tier, tokens),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.catalog.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // How to Obtain
                Text(
                  'How to Obtain',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: tokens.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: tokens.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Requirements',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        achievement.catalog.howTo,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Progress Section
                if (achievement.userState.status !=
                    AchievementStatus.earned) ...[
                  Text(
                    'Your Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.warning.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: tokens.warning.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                            Text(
                              '${achievement.userState.progress}/${achievement.catalog.threshold}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: tokens.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: achievement.progressPercent / 100,
                            backgroundColor: tokens.muted,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(tokens.warning),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${achievement.progressPercent.toInt()}% Complete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Achievement Unlocked Celebration
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tokens.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: tokens.success.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.celebration,
                          color: tokens.success,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Achievement Unlocked!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: tokens.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Congratulations! You\'ve earned this achievement.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: tokens.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getTierColor(AchievementTier tier, SemanticTokens tokens) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.legendary:
        return const Color(0xFFFF6B35);
    }
  }
}

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
    final completionRate =
        totalAchievements > 0 ? (earnedAchievements / totalAchievements) : 0.0;

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Opacity(
            opacity: _headerFadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.primary.withOpacity(0.1),
                    tokens.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.5],
                ),
              ),
              child: Column(
                children: [
                  // Title and Animated Progress Ring
                  ScaleTransition(
                    scale: _progressScaleAnimation,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _progressFillAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressFillAnimation.value *
                                    completionRate,
                                strokeWidth: 8,
                                backgroundColor: tokens.muted.withOpacity(0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    tokens.primary),
                              );
                            },
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(completionRate * 100).toInt()}%',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: tokens.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Complete',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Achievement Progress',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$earnedAchievements of $totalAchievements completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEarned
              ? tokens.success.withOpacity(0.5)
              : isInProgress
                  ? tokens.warning.withOpacity(0.5)
                  : tokens.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isEarned
                ? tokens.success.withOpacity(0.1)
                : isInProgress
                    ? tokens.warning.withOpacity(0.1)
                    : tokens.outline.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _showAchievementDetails(achievement),
          borderRadius: BorderRadius.circular(24),
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
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _getTierColor(achievement.catalog.tier, tokens)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _getTierColor(achievement.catalog.tier, tokens)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          achievement.catalog.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
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
                          const SizedBox(height: 6),
                          Text(
                            achievement.catalog.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tier Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getTierColor(achievement.catalog.tier, tokens)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        achievement.catalog.tier.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              _getTierColor(achievement.catalog.tier, tokens),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress Section or Earned Badge
                if (!isEarned)
                  _buildProgressIndicator(
                      tokens, theme, achievement, isInProgress)
                else
                  _buildEarnedBadge(tokens, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarnedBadge(SemanticTokens tokens, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: tokens.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.success.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: tokens.success, size: 20),
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
    );
  }

  Color _getTierColor(AchievementTier tier, SemanticTokens tokens) {
    switch (tier) {
      case AchievementTier.bronze:
        return tokens.tierBronze;
      case AchievementTier.silver:
        return tokens.tierSilver;
      case AchievementTier.gold:
        return tokens.tierGold;
      case AchievementTier.platinum:
        return tokens.tierPlatinum;
      case AchievementTier.legendary:
        return tokens.tierLegendary;
    }
  }

  void _showAchievementDetails(AchievementDisplay achievement) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AchievementDetailsScreen(achievement: achievement),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(SemanticTokens tokens, ThemeData theme,
      AchievementDisplay achievement, bool isInProgress) {
    final progress = achievement.progressPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
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

// Achievement Details Screen
class AchievementDetailsScreen extends StatefulWidget {
  final AchievementDisplay achievement;

  const AchievementDetailsScreen({super.key, required this.achievement});

  @override
  State<AchievementDetailsScreen> createState() =>
      _AchievementDetailsScreenState();
}

class _AchievementDetailsScreenState extends State<AchievementDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: tokens.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, tokens, theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        context,
                        'Description',
                        widget.achievement.catalog.description,
                      ),
                      const SizedBox(height: 24),
                      _buildHowToObtainSection(context, tokens, theme),
                      const SizedBox(height: 24),
                      if (widget.achievement.userState.status !=
                          AchievementStatus.earned) ...[
                        _buildProgressSection(context, tokens, theme),
                      ] else ...[
                        _buildUnlockedCelebration(context, tokens, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, SemanticTokens tokens, ThemeData theme) {
    return SliverAppBar(
      backgroundColor: tokens.surface,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(Icons.close, color: tokens.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      expandedHeight: 250.0,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildAppBarBackground(context, tokens, theme),
      ),
    );
  }

  Widget _buildAppBarBackground(
      BuildContext context, SemanticTokens tokens, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getTierColor(widget.achievement.catalog.tier, tokens)
                .withOpacity(0.2),
            tokens.surface,
          ],
          stops: const [0, 0.8],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color:
                          _getTierColor(widget.achievement.catalog.tier, tokens)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getTierColor(
                                widget.achievement.catalog.tier, tokens)
                            .withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getTierColor(
                                  widget.achievement.catalog.tier, tokens)
                              .withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.achievement.catalog.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.achievement.catalog.title,
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
                                  widget.achievement.catalog.tier, tokens)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.achievement.catalog.tier.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _getTierColor(
                                widget.achievement.catalog.tier, tokens),
                            fontWeight: FontWeight.bold,
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

  Widget _buildSection(BuildContext context, String title, String content) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: tokens.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHowToObtainSection(
      BuildContext context, SemanticTokens tokens, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            border: Border.all(color: tokens.primary.withValues(alpha: 0.2)),
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
                widget.achievement.catalog.howTo,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(
      BuildContext context, SemanticTokens tokens, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: theme.textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.warning.withValues(alpha: 0.2)),
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
                      '${widget.achievement.userState.progress}/${widget.achievement.catalog.threshold}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_controller.value *
                            widget.achievement.progressPercent /
                            100),
                        backgroundColor: tokens.muted,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(tokens.warning),
                        minHeight: 10,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.achievement.progressPercent.toInt()}% Complete',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedCelebration(
      BuildContext context, SemanticTokens tokens, ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tokens.success.withOpacity(0.2),
              tokens.success.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.success.withValues(alpha: 0.3)),
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

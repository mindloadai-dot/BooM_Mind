import 'dart:math';
import 'package:flutter/material.dart';

import 'package:mindload/theme.dart';
import 'package:mindload/widgets/mindload_app_bar.dart';
import 'package:mindload/widgets/mindload_button_system.dart';
import 'package:mindload/services/neurograph_service.dart';
import 'package:mindload/models/neurograph_models.dart';

class NeuroGraphScreen extends StatefulWidget {
  const NeuroGraphScreen({super.key});

  @override
  State<NeuroGraphScreen> createState() => _NeuroGraphScreenState();
}

class _NeuroGraphScreenState extends State<NeuroGraphScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  DateTime? _lastUpdated;
  bool _hasData = false;
  List<StudySession> _studyData = [];
  List<StreakData> _streakData = [];
  List<RecallData> _recallData = [];
  List<EfficiencyData> _efficiencyData = [];
  List<ForgettingData> _forgettingData = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _chartAnimationController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();

    // Delay chart animation for better visual effect
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _chartAnimationController.forward();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final neuroGraphService = NeuroGraphService.instance;
      await neuroGraphService.initialize();

      if (mounted) {
        _lastUpdated = neuroGraphService.lastUpdated;
        _studyData = neuroGraphService.studyData;
        _streakData = neuroGraphService.streakData;
        _recallData = neuroGraphService.recallData;
        _efficiencyData = neuroGraphService.efficiencyData;
        _forgettingData = neuroGraphService.forgettingData;

        _hasData = neuroGraphService.hasData;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading NeuroGraph data: $e');
      if (mounted) {
        _hasData = false;
        _studyData = [];
        _streakData = [];
        _recallData = [];
        _efficiencyData = [];
        _forgettingData = [];
        setState(() {});
      }
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Refreshing NeuroGraph data...');
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hasData
              ? 'NeuroGraph data refreshed! Found ${_studyData.length} study sessions.'
              : 'No study data found. Complete some quizzes or flashcard sessions first.'),
          backgroundColor: _hasData ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: context.tokens.surface,
        appBar: MindloadAppBar(
          title: 'NeuroGraph',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildInfoPanel(),
                  const SizedBox(height: 24),
                  if (_hasData) ...[
                    _buildStudyHeatmap(),
                    const SizedBox(height: 24),
                    _buildStreakSparkline(),
                    const SizedBox(height: 24),
                    _buildRecallRadar(),
                    const SizedBox(height: 24),
                    _buildEfficiencyBar(),
                    const SizedBox(height: 24),
                    _buildForgettingCurve(),
                    const SizedBox(height: 24),
                    _buildAnalysisCard(),
                    const SizedBox(height: 24),
                    _buildQuickTipsCard(),
                    const SizedBox(height: 24),
                    _buildGraphExplanations(),
                  ] else ...[
                    _buildEmptyState(),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building NeuroGraph screen: $e');
      return Scaffold(
        backgroundColor: context.tokens.surface,
        appBar: MindloadAppBar(
          title: 'NeuroGraph',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: context.tokens.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: context.tokens.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try refreshing the page or restarting the app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.tokens.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: _refreshData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.tokens.primary.withOpacity(0.1),
            context.tokens.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.tokens.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: context.tokens.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Learning Analytics',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.tokens.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your progress and optimize your study habits',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_lastUpdated != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: context.tokens.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last updated: ${_lastUpdated!.day}/${_lastUpdated!.month}/${_lastUpdated!.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: context.tokens.outline.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'What is NeuroGraph?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'NeuroGraph analyzes your learning patterns and study behavior to help you understand how your brain processes information. Each chart reveals different aspects of your cognitive performance.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: context.tokens.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete quizzes and flashcard sessions to see your data visualized below.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.tokens.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyHeatmap() {
    return _buildChartCard(
      title: 'Study Activity',
      subtitle: 'When you study most effectively',
      helpText:
          'This shows your study activity throughout the week. Darker colors indicate more study time.',
      child: SizedBox(
        height: 180,
        child: _buildSimplifiedHeatmap(),
      ),
    );
  }

  Widget _buildStreakSparkline() {
    return _buildChartCard(
      title: 'Study Streak',
      subtitle: 'Your daily consistency',
      helpText:
          'This tracks your daily study consistency. Higher bars mean longer study sessions.',
      child: SizedBox(
        height: 120,
        child: _buildSimplifiedSparkline(),
      ),
    );
  }

  Widget _buildRecallRadar() {
    return _buildChartCard(
      title: 'Memory Performance',
      subtitle: 'How well you remember',
      helpText:
          'This shows your memory performance across different subjects. Larger circles mean better recall.',
      child: SizedBox(
        height: 200,
        child: _buildSimplifiedRadar(),
      ),
    );
  }

  Widget _buildEfficiencyBar() {
    return _buildChartCard(
      title: 'Learning Efficiency',
      subtitle: 'How much you learn per minute',
      helpText:
          'This compares your learning efficiency over time. Higher bars mean you\'re learning more effectively.',
      child: SizedBox(
        height: 150,
        child: _buildSimplifiedBarChart(),
      ),
    );
  }

  Widget _buildForgettingCurve() {
    return _buildChartCard(
      title: 'Memory Retention',
      subtitle: 'How much you remember over time',
      helpText:
          'This shows how much information you retain over time. Review before the line drops too much!',
      child: SizedBox(
        height: 150,
        child: _buildSimplifiedLineChart(),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
    String? helpText,
  }) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, childWidget) {
        return Transform.scale(
          scale: 0.8 + (_chartAnimation.value * 0.2),
          child: Opacity(
            opacity: _chartAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.tokens.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.tokens.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.tokens.outline.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.tokens.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: context.tokens.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.help_outline,
                        color: context.tokens.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  if (helpText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      helpText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.tokens.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimplifiedHeatmap() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.tokens.textPrimary,
                    ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: context.tokens.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Low',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: context.tokens.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'High',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: List.generate(7, (dayIndex) {
                final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        dayNames[dayIndex],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.tokens.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Column(
                          children: List.generate(6, (hourIndex) {
                            final intensity = Random().nextDouble();
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                decoration: BoxDecoration(
                                  color: context.tokens.primary
                                      .withOpacity(intensity * 0.8),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedSparkline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 7 Days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.tokens.textPrimary,
                    ),
              ),
              Text(
                '${Random().nextInt(5) + 3} day streak',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.tokens.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: List.generate(7, (index) {
                final height = Random().nextDouble() * 0.6 + 0.2;
                return Expanded(
                  child: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: context.tokens.primary
                              .withOpacity(height * _chartAnimation.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedRadar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Performance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildSimplifiedRadarItem('Math', 85, context.tokens.primary),
                _buildSimplifiedRadarItem(
                    'Science', 72, context.tokens.secondary),
                _buildSimplifiedRadarItem('History', 90, context.tokens.accent),
                _buildSimplifiedRadarItem('Language', 78, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedRadarItem(String label, int value, Color color) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.tokens.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(value * _chartAnimation.value).round()}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimplifiedBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Efficiency Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                final height = Random().nextDouble() * 0.7 + 0.3;
                return Expanded(
                  child: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: context.tokens.primary.withOpacity(
                                    height * _chartAnimation.value),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${index + 1}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.tokens.textSecondary,
                                    ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedLineChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Memory Retention',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.tokens.textPrimary,
                    ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    color: context.tokens.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Actual',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 12,
                    height: 2,
                    color: context.tokens.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: List.generate(7, (index) {
                final actualHeight = Random().nextDouble() * 0.6 + 0.2;
                final expectedHeight = (1.0 - (index * 0.12)).clamp(0.1, 1.0);

                return Expanded(
                  child: AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (actualHeight *
                                          100 *
                                          _chartAnimation.value)
                                      .round(),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      color: context.tokens.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: (expectedHeight *
                                          100 *
                                          _chartAnimation.value)
                                      .round(),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 2),
                                    decoration: BoxDecoration(
                                      color: context.tokens.secondary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'D${index + 1}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.tokens.textSecondary,
                                    ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ANALYSIS & TIPS CARDS
  // ============================================================================

  Widget _buildAnalysisCard() {
    final neuroGraphService = NeuroGraphService.instance;
    final analysis = neuroGraphService.getCachedAnalysis();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: context.tokens.outline.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Analysis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis.isNotEmpty
                ? analysis.join('\n\n')
                : 'Complete more study sessions to get personalized insights about your learning patterns.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipsCard() {
    final neuroGraphService = NeuroGraphService.instance;
    final tips = neuroGraphService.getCachedQuickTips();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: context.tokens.outline.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: context.tokens.secondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Tips',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tips.isNotEmpty
                ? tips.join('\n\n')
                : 'Study regularly and complete quizzes to receive personalized tips for improving your learning.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: context.tokens.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete some quizzes or flashcard sessions to see your learning analytics here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            onPressed: () {
              // Navigate to home screen instead of non-existent /create route
              Navigator.pushNamed(context, '/home');
            },
            fullWidth: true,
            child: const Text('Start Studying'),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphExplanations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Understanding Your Charts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildExplanationItem(
            icon: Icons.grid_on,
            title: 'Study Activity',
            description:
                'Shows when you study most effectively. Darker colors indicate more study time.',
            color: context.tokens.primary,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.trending_up,
            title: 'Study Streak',
            description:
                'Tracks your daily study consistency. Higher bars mean longer study sessions.',
            color: context.tokens.secondary,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.radar,
            title: 'Memory Performance',
            description:
                'Shows your memory performance across different subjects. Larger circles mean better recall.',
            color: context.tokens.accent,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.bar_chart,
            title: 'Learning Efficiency',
            description:
                'Compares your learning efficiency over time. Higher bars mean you\'re learning more effectively.',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.show_chart,
            title: 'Memory Retention',
            description:
                'Shows how much information you retain over time. Review before the line drops too much!',
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: context.tokens.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: context.tokens.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Regular study sessions are more effective than cramming. Try to study a little each day!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.tokens.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.tokens.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

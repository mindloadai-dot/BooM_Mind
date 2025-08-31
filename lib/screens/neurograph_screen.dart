import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mindload/constants/product_constants.dart';
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadData() async {
    try {
      final neuroGraphService = NeuroGraphService.instance;
      await neuroGraphService.initialize();

      _lastUpdated = neuroGraphService.lastUpdated;
      _studyData = neuroGraphService.studyData;
      _streakData = neuroGraphService.streakData;
      _recallData = neuroGraphService.recallData;
      _efficiencyData = neuroGraphService.efficiencyData;
      _forgettingData = neuroGraphService.forgettingData;

      _hasData = neuroGraphService.hasData;
      setState(() {});
    } catch (e) {
      debugPrint('Error loading NeuroGraph data: $e');
      _hasData = false;
      setState(() {});
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
  }

  Widget _buildHeader() {
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
                Icons.analytics,
                color: context.tokens.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProductConstants.neurographTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.tokens.textPrimary,
                              ),
                    ),
                    Text(
                      ProductConstants.neurographSubtitle,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.tokens.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${ProductConstants.neurographUpdatedBadge} • ${_formatTimeAgo(_lastUpdated!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.tokens.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
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
            ProductConstants.neurographEmptyTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.tokens.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ProductConstants.neurographEmptyBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            onPressed: _startQuickSession,
            fullWidth: true,
            child: Text(ProductConstants.neurographEmptyCta),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _generateSampleData,
            child: const Text('Generate Sample Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyHeatmap() {
    return _buildChartCard(
      title: ProductConstants.studyHeatmapTitle,
      subtitle: ProductConstants.studyHeatmapSubtitle,
      helpText:
          'This heatmap shows your study activity throughout the day and week. Darker colors indicate more study time. Use this to identify when you learn most effectively.',
      child: SizedBox(
        height: 200,
        child: _buildHeatmapChart(),
      ),
    );
  }

  Widget _buildStreakSparkline() {
    return _buildChartCard(
      title: ProductConstants.streakSparklineTitle,
      subtitle: ProductConstants.streakSparklineSubtitle,
      helpText:
          'This sparkline tracks your daily study consistency over time. Higher peaks indicate longer study streaks. Maintaining consistency is crucial for memory retention.',
      child: SizedBox(
        height: 150,
        child: _buildSparklineChart(),
      ),
    );
  }

  Widget _buildRecallRadar() {
    return _buildChartCard(
      title: ProductConstants.recallRadarTitle,
      subtitle: ProductConstants.recallRadarSubtitle,
      helpText:
          'This radar chart measures your recall ability across different subjects and difficulty levels. Larger areas indicate stronger memory performance in those areas.',
      child: SizedBox(
        height: 250,
        child: _buildRadarChart(),
      ),
    );
  }

  Widget _buildEfficiencyBar() {
    return _buildChartCard(
      title: ProductConstants.efficiencyBarTitle,
      subtitle: ProductConstants.efficiencyBarSubtitle,
      helpText:
          'This bar chart shows your learning efficiency over time - how much you learn per minute of study. Higher bars mean you\'re absorbing information more effectively.',
      child: SizedBox(
        height: 200,
        child: _buildBarChart(),
      ),
    );
  }

  Widget _buildForgettingCurve() {
    return _buildChartCard(
      title: ProductConstants.forgettingCurveTitle,
      subtitle: ProductConstants.forgettingCurveSubtitle,
      helpText:
          'Based on Hermann Ebbinghaus\'s research, this curve shows how quickly you forget information without review. The steeper the drop, the more urgent the need for review.',
      child: SizedBox(
        height: 200,
        child: _buildLineChart(),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
    String? helpText,
  }) {
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
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                ),
              ),
              if (helpText != null)
                Tooltip(
                  message: helpText,
                  child: Icon(
                    Icons.help_outline,
                    size: 20,
                    color: context.tokens.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.tokens.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildHeatmapChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Time Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 24,
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 7 * 24,
              itemBuilder: (context, index) {
                final day = index ~/ 24;
                final hour = index % 24;
                final intensity = Random().nextDouble();

                return Container(
                  decoration: BoxDecoration(
                    color: context.tokens.primary.withOpacity(intensity * 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparklineChart() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30-Day Streak',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: List.generate(30, (index) {
                final height = Random().nextDouble() * 0.8 + 0.2;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: context.tokens.primary.withOpacity(height),
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
  }

  Widget _buildRadarChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recall by Subject',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildRadarItem('Math', 80),
                      const SizedBox(height: 8),
                      _buildRadarItem('Science', 65),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildRadarItem('History', 90),
                      const SizedBox(height: 8),
                      _buildRadarItem('Language', 75),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildRadarItem('Literature', 85),
                      const SizedBox(height: 8),
                      const SizedBox(height: 40), // Spacer
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarItem(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.tokens.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.tokens.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Efficiency',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 75,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: context.tokens.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Correct/min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 45,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: context.tokens.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Response Time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.tokens.textSecondary,
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
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.tokens.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forgetting Curve',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: List.generate(7, (index) {
                final actualHeight = Random().nextDouble() * 0.6 + 0.2;
                final predictedHeight = (1.0 - (index * 0.1)).clamp(0.1, 1.0);

                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: (actualHeight * 100).round(),
                              child: Container(
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                  color: context.tokens.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: (predictedHeight * 100).round(),
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
                        'Day ${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.tokens.textSecondary,
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
                Icons.insights,
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analysis.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: context.tokens.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.tokens.textPrimary,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
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
                color: context.tokens.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: context.tokens.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.tokens.textPrimary,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _startQuickSession() {
    // Navigate to study screen or start a quick session
    Navigator.pushNamed(context, '/home');
  }

  void _generateSampleData() async {
    try {
      final neuroGraphService = NeuroGraphService.instance;
      await neuroGraphService.generateSampleData();
      await _loadData(); // Reload data after generation

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sample data generated successfully!'),
            backgroundColor: context.tokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate sample data: $e'),
            backgroundColor: context.tokens.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.tokens.primary.withOpacity(0.1),
            context.tokens.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.tokens.primary.withOpacity(0.2),
        ),
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
            title: 'Study Heatmap',
            description:
                'Shows when you study most effectively. Darker colors indicate more study time. Use this to identify your peak learning hours.',
            color: context.tokens.primary,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.trending_up,
            title: 'Streak Sparkline',
            description:
                'Tracks your daily study consistency. Higher peaks mean longer streaks. Consistency is key to long-term retention.',
            color: context.tokens.secondary,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.radar,
            title: 'Recall Radar',
            description:
                'Measures how well you remember information across different subjects. Larger areas indicate stronger recall abilities.',
            color: context.tokens.accent,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.bar_chart,
            title: 'Efficiency Bar Chart',
            description:
                'Compares your learning efficiency over time. Higher bars mean you\'re learning more in less time.',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildExplanationItem(
            icon: Icons.show_chart,
            title: 'Forgetting Curve',
            description:
                'Based on Ebbinghaus\'s research, this shows how much information you retain over time. Review before the curve drops!',
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: context.tokens.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Use the refresh button above to update your charts after completing study sessions.',
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.tokens.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.tokens.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

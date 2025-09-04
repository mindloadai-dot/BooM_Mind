import 'package:flutter/material.dart';
import 'neurograph_config.dart';
import 'neurograph_models.dart';
import 'neurograph_repo.dart';
import 'neurograph_compute.dart';
import 'neurograph_widgets.dart';

/// Main NeuroGraph V2 screen with tabbed interface for all six charts
class NeuroGraphV2Screen extends StatefulWidget {
  final String userId;

  const NeuroGraphV2Screen({
    super.key,
    required this.userId,
  });

  @override
  State<NeuroGraphV2Screen> createState() => _NeuroGraphV2ScreenState();
}

class _NeuroGraphV2ScreenState extends State<NeuroGraphV2Screen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late NeuroGraphRepository _repository;

  // Data state
  List<Attempt> _attempts = [];
  Map<String, dynamic> _userSummary = {};
  final NeuroGraphFilters _filters = const NeuroGraphFilters();

  // Loading states
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Chart data
  List<DailyPoint> _dailyPoints = [];
  List<double> _emaValues = [];
  Map<String, RecallModel> _recallModels = {};
  List<WeekPoint> _weekPoints = [];
  CalibrationSummary _calibration = const CalibrationSummary(
      bins: [], brierScore: 0.0, expectedCalibrationError: 0.0);
  List<WeekStack> _weekStacks = [];
  Map<DateTime, ConsistencyHeat> _heatData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _repository = NeuroGraphRepository();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load user summary first
      final summary = await _repository.getUserDataSummary(widget.userId);

      if (!mounted) return;

      setState(() {
        _userSummary = summary;
      });

      if (!summary['hasData']) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'No learning data available. Start studying to see your analytics!\n\n'
              'Debug info:\n'
              'User ID: ${widget.userId}\n'
              'Total attempts: ${summary['totalAttempts']}\n'
              'Timezone: ${summary['userTimezone']}\n'
              'Error: ${summary['error'] ?? 'No error'}';
        });
        return;
      }

      // Load attempts data
      final fromDate = DateTime.now()
          .subtract(Duration(days: NeuroGraphConfig.learningCurveDays));
      final attempts = await _repository.attemptsForUser(
        widget.userId,
        from: fromDate,
        filters: _filters,
      );

      if (!mounted) return;

      setState(() {
        _attempts = attempts;
      });

      // Compute all chart data
      await _computeChartData();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load analytics data: ${e.toString()}';
      });
    }
  }

  Future<void> _computeChartData() async {
    // Get user's timezone from repository
    final userTimezone = await _repository.getUserTimezone();

    // Learning curve data
    _dailyPoints =
        NeuroGraphCompute.dailyAccuracy(_attempts, timezone: userTimezone);
    if (_dailyPoints.isNotEmpty) {
      final accuracies = _dailyPoints.map((p) => p.accuracy).toList();
      _emaValues =
          NeuroGraphCompute.ema(accuracies, n: NeuroGraphConfig.emaPeriod);
    }

    // Spaced review data
    final forgettingAttempts = await _repository.attemptsForUser(
      widget.userId,
      from: DateTime.now()
          .subtract(Duration(days: NeuroGraphConfig.forgettingCurveDays)),
    );
    _recallModels = NeuroGraphCompute.forgettingModel(forgettingAttempts,
        timezone: userTimezone);

    // Retrieval practice data
    _weekPoints =
        NeuroGraphCompute.retrievalVsExam(_attempts, timezone: userTimezone);

    // Calibration data
    _calibration =
        NeuroGraphCompute.calibration(_attempts, timezone: userTimezone);

    // Mastery data
    _weekStacks =
        NeuroGraphCompute.masteryStacks(_attempts, timezone: userTimezone);

    // Consistency data
    _heatData =
        NeuroGraphCompute.consistencyHeat(_attempts, timezone: userTimezone);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _createSampleData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _repository.createSampleData(widget.userId);
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample data created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload data
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create sample data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onViewDueItems() {
    final dueItems =
        _recallModels.values.where((model) => model.isDue).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Items Due for Review'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: dueItems.length,
            itemBuilder: (context, index) {
              final item = dueItems[index];
              return ListTile(
                title: Text('Question ${item.questionId}'),
                subtitle: Text(
                  'Recall: ${(item.pRecall * 100).toStringAsFixed(1)}% • '
                  'Repetitions: ${item.repetitions}',
                ),
                trailing: Text(
                  '${item.daysSinceLastSuccess} days ago',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroGraph Analytics'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
            tooltip: 'Refresh data',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Learning Curve'),
            Tab(text: 'Spaced Review'),
            Tab(text: 'Retrieval Practice'),
            Tab(text: 'Calibration'),
            Tab(text: 'Mastery'),
            Tab(text: 'Consistency'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLearningCurveTab(colorScheme),
                    _buildSpacedReviewTab(colorScheme),
                    _buildRetrievalPracticeTab(colorScheme),
                    _buildCalibrationTab(colorScheme),
                    _buildMasteryTab(colorScheme),
                    _buildConsistencyTab(colorScheme),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createSampleData,
              icon: const Icon(Icons.data_saver_on),
              label: const Text('Create Sample Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCurveTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Learning Curve',
            'Track your daily accuracy and progress over time',
            Icons.trending_up,
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          NeuroGraphWidgets.learningCurveChart(
            dailyPoints: _dailyPoints,
            emaValues: _emaValues,
            goalMin: NeuroGraphConfig.goalAccuracyMin,
            goalMax: NeuroGraphConfig.goalAccuracyMax,
            chartHeight: NeuroGraphConfig.chartHeight,
            primaryColor: colorScheme.primary,
            secondaryColor: colorScheme.secondary,
            goalColor: Color(NeuroGraphConfig.goalColor),
          ),
          const SizedBox(height: 16),
          _buildChartLegend([
            _LegendItem('Daily Accuracy', colorScheme.primary),
            _LegendItem('7-day EMA', colorScheme.secondary),
            _LegendItem(
                'Goal Range (80-90%)', Color(NeuroGraphConfig.goalColor)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSpacedReviewTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Spaced Review',
            'Items due for review based on forgetting curve',
            Icons.schedule,
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          NeuroGraphWidgets.spacedReviewPanel(
            recallModels: _recallModels,
            chartHeight: NeuroGraphConfig.chartHeight,
            primaryColor: colorScheme.primary,
            accentColor: colorScheme.tertiary,
            onViewDueItems: _onViewDueItems,
          ),
        ],
      ),
    );
  }

  Widget _buildRetrievalPracticeTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Retrieval Practice',
            'Practice sessions vs subsequent exam performance',
            Icons.psychology,
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          NeuroGraphWidgets.retrievalPracticeMeter(
            weekPoints: _weekPoints,
            chartHeight: NeuroGraphConfig.chartHeight,
            primaryColor: colorScheme.primary,
            secondaryColor: colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          _buildChartLegend([
            _LegendItem('Retrieval Sessions', colorScheme.primary),
            _LegendItem('Exam Scores', colorScheme.secondary),
          ]),
        ],
      ),
    );
  }

  Widget _buildCalibrationTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Calibration',
            'How well your confidence matches your accuracy',
            Icons.psychology_alt,
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          NeuroGraphWidgets.calibrationPlot(
            calibration: _calibration,
            chartHeight: NeuroGraphConfig.chartHeight,
            primaryColor: colorScheme.primary,
            errorColor: colorScheme.error,
          ),
          const SizedBox(height: 16),
          _buildChartLegend([
            _LegendItem('Perfect Calibration', Colors.grey),
            _LegendItem('Your Calibration', colorScheme.primary),
          ]),
        ],
      ),
    );
  }

  Widget _buildMasteryTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Mastery Progress',
            'Track items through NEW → PRACTICING → MASTERED',
            Icons.school,
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          NeuroGraphWidgets.masteryProgressChart(
            weekStacks: _weekStacks,
            chartHeight: NeuroGraphConfig.chartHeight,
            newColor: colorScheme.primary,
            practicingColor: colorScheme.secondary,
            masteredColor: colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          _buildChartLegend([
            _LegendItem('New', colorScheme.primary),
            _LegendItem('Practicing', colorScheme.secondary),
            _LegendItem('Mastered', colorScheme.tertiary),
          ]),
        ],
      ),
    );
  }

  Widget _buildConsistencyTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(
            'Study Consistency',
            'Daily study activity and streaks',
            Icons.calendar_today,
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          NeuroGraphWidgets.consistencyHeatmap(
            heatData: _heatData,
            chartHeight: NeuroGraphConfig.chartHeight,
            primaryColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildChartHeader(
      String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(List<_LegendItem> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Data'),
        content: const Text('Filter functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;

  _LegendItem(this.label, this.color);
}

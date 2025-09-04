import 'package:flutter/material.dart';
import 'dart:math';
import '../theme.dart';
import 'neurograph_models.dart';
import 'neurograph_offline_repo.dart';
import 'neurograph_compute.dart';

/// Simple and intuitive NeuroGraph V2 screen with motivational metrics
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
  late NeuroGraphOfflineRepository _repository;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _chartController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  // Data state
  List<Attempt> _attempts = [];
  Map<String, dynamic> _userSummary = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Chart data
  List<DailyPoint> _dailyPoints = [];
  List<double> _emaValues = [];
  
  // Enhanced statistical data
  Map<String, dynamic> _learningStats = {};
  List<Map<String, dynamic>> _weeklyProgress = [];
  List<Map<String, dynamic>> _topicPerformance = [];
  Map<String, dynamic> _studyPatterns = {};
  List<Map<String, dynamic>> _accuracyTrends = [];
  Map<String, dynamic> _timeAnalysis = {};

  // Motivational metrics
  int _totalStudyMinutes = 0;
  double _questionsPerDay = 0.0;
  double _improvementRate = 0.0;
  int _nextMilestone = 0;
  String _nextMilestoneType = '';
  int _daysToNextMilestone = 0;

  @override
  void initState() {
    super.initState();
    _repository = NeuroGraphOfflineRepository();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Fade animation for overall content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Slide animation for cards
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Chart animation
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutBack),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Delay chart animation for better visual effect
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _chartController.forward();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load user summary
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
              'No learning data available yet!\n\nStart studying to see your progress!';
        });
        return;
      }

      // Load attempts data
      final fromDate = DateTime.now().subtract(Duration(days: 30));
      final attempts = await _repository.attemptsForUser(
        widget.userId,
        from: fromDate,
      );

      if (!mounted) return;

      setState(() {
        _attempts = attempts;
      });

      // Compute chart data and motivational metrics
      await _computeChartData();
      _computeMotivationalMetrics();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load analytics: ${e.toString()}';
      });
    }
  }

  Future<void> _computeChartData() async {
    final userTimezone = await _repository.getUserTimezone();

    // Learning curve data
    _dailyPoints =
        NeuroGraphCompute.dailyAccuracy(_attempts, timezone: userTimezone);
    if (_dailyPoints.isNotEmpty) {
      final accuracies = _dailyPoints.map((p) => p.accuracy).toList();
      _emaValues = NeuroGraphCompute.ema(accuracies, n: 7);
    }

    // Enhanced statistical computations
    _computeLearningStatistics();
    _computeWeeklyProgress();
    _computeTopicPerformance();
    _computeStudyPatterns();
    _computeAccuracyTrends();
    _computeTimeAnalysis();
  }

  void _computeLearningStatistics() {
    if (_attempts.isEmpty) return;

    final totalAttempts = _attempts.length;
    final correctAttempts = _attempts.where((a) => a.isCorrect).length;
    final accuracy = (correctAttempts / totalAttempts) * 100;

    // Response time analysis
    final responseTimes = _attempts.map((a) => a.responseMs).toList();
    final avgResponseTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
    final fastestResponse = responseTimes.reduce((a, b) => a < b ? a : b);
    final slowestResponse = responseTimes.reduce((a, b) => a > b ? a : b);

    // Difficulty progression (using score as proxy for difficulty)
    final scores = _attempts.map((a) => a.score).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;

    // Study session analysis
    final sessions = _groupAttemptsBySession();
    final avgSessionLength = sessions.map((s) => s.length).reduce((a, b) => a + b) / sessions.length;

    _learningStats = {
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'accuracy': accuracy,
      'avgResponseTime': avgResponseTime,
      'fastestResponse': fastestResponse,
      'slowestResponse': slowestResponse,
      'avgScore': avgScore,
      'totalSessions': sessions.length,
      'avgSessionLength': avgSessionLength,
      'studyEfficiency': (accuracy * totalAttempts) / (avgResponseTime / 1000), // Efficiency score
    };
  }

  void _computeWeeklyProgress() {
    if (_attempts.isEmpty) return;

    final now = DateTime.now();
    final weeks = <Map<String, dynamic>>[];

    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final weekAttempts = _attempts.where((a) => 
        a.timestamp.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        a.timestamp.isBefore(weekEnd.add(const Duration(days: 1)))
      ).toList();

      if (weekAttempts.isNotEmpty) {
        final weekCorrect = weekAttempts.where((a) => a.isCorrect).length;
        final weekAccuracy = (weekCorrect / weekAttempts.length) * 100;
        final weekQuestions = weekAttempts.length;

        weeks.add({
          'week': 'Week ${4 - i}',
          'accuracy': weekAccuracy,
          'questions': weekQuestions,
          'correct': weekCorrect,
          'incorrect': weekQuestions - weekCorrect,
        });
      }
    }

    _weeklyProgress = weeks;
  }

  void _computeTopicPerformance() {
    if (_attempts.isEmpty) return;

    final topicMap = <String, List<Attempt>>{};
    
    // Group attempts by topic (using topicId as proxy)
    for (final attempt in _attempts) {
      final topic = _extractTopicFromTopicId(attempt.topicId);
      topicMap.putIfAbsent(topic, () => []).add(attempt);
    }

    final topicStats = <Map<String, dynamic>>[];
    
    topicMap.forEach((topic, attempts) {
      final correct = attempts.where((a) => a.isCorrect).length;
      final accuracy = (correct / attempts.length) * 100;
      final avgTime = attempts.map((a) => a.responseMs).reduce((a, b) => a + b) / attempts.length;

      topicStats.add({
        'topic': topic,
        'attempts': attempts.length,
        'accuracy': accuracy,
        'avgTime': avgTime,
        'strength': accuracy > 80 ? 'Strong' : accuracy > 60 ? 'Good' : 'Needs Work',
      });
    });

    // Sort by accuracy descending
    topicStats.sort((a, b) => (b['accuracy'] as double).compareTo(a['accuracy'] as double));
    _topicPerformance = topicStats;
  }

  void _computeStudyPatterns() {
    if (_attempts.isEmpty) return;

    final hourDistribution = List.filled(24, 0);
    final dayDistribution = List.filled(7, 0);
    
    for (final attempt in _attempts) {
      final hour = attempt.timestamp.hour;
      final day = attempt.timestamp.weekday - 1; // 0-based
      hourDistribution[hour]++;
      dayDistribution[day]++;
    }

    final peakHour = hourDistribution.indexOf(hourDistribution.reduce((a, b) => a > b ? a : b));
    final peakDay = dayDistribution.indexOf(dayDistribution.reduce((a, b) => a > b ? a : b));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    _studyPatterns = {
      'peakHour': peakHour,
      'peakDay': dayNames[peakDay],
      'hourDistribution': hourDistribution,
      'dayDistribution': dayDistribution,
      'consistency': _calculateConsistencyScore(),
      'preferredTime': _getPreferredTimeSlot(peakHour),
    };
  }

  void _computeAccuracyTrends() {
    if (_dailyPoints.isEmpty) return;

    final trends = <Map<String, dynamic>>[];
    
    for (int i = 0; i < _dailyPoints.length; i++) {
      final point = _dailyPoints[i];
      final trend = i > 0 ? point.accuracy - _dailyPoints[i - 1].accuracy : 0.0;
      
      trends.add({
        'date': point.date,
        'accuracy': point.accuracy,
        'trend': trend,
        'direction': trend > 0 ? 'up' : trend < 0 ? 'down' : 'stable',
      });
    }

    _accuracyTrends = trends;
  }

  void _computeTimeAnalysis() {
    if (_attempts.isEmpty) return;

    final responseTimes = _attempts.map((a) => a.responseMs).toList();
    final sortedTimes = List<int>.from(responseTimes)..sort();
    
    final median = sortedTimes[sortedTimes.length ~/ 2];
    final q1 = sortedTimes[sortedTimes.length ~/ 4];
    final q3 = sortedTimes[(sortedTimes.length * 3) ~/ 4];

    _timeAnalysis = {
      'median': median,
      'q1': q1,
      'q3': q3,
      'iqr': q3 - q1,
      'outliers': _findOutliers(responseTimes, q1, q3),
      'speedCategories': _categorizeSpeed(responseTimes),
    };
  }

  List<List<Attempt>> _groupAttemptsBySession() {
    if (_attempts.isEmpty) return [];
    
    final sessions = <List<Attempt>>[];
    final sortedAttempts = List<Attempt>.from(_attempts)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    List<Attempt> currentSession = [];
    
    for (int i = 0; i < sortedAttempts.length; i++) {
      final attempt = sortedAttempts[i];
      
      if (currentSession.isEmpty) {
        currentSession.add(attempt);
      } else {
        final lastAttempt = currentSession.last;
        final timeDiff = attempt.timestamp.difference(lastAttempt.timestamp).inMinutes;
        
        if (timeDiff <= 30) { // 30-minute gap defines a session
          currentSession.add(attempt);
        } else {
          sessions.add(List.from(currentSession));
          currentSession = [attempt];
        }
      }
    }
    
    if (currentSession.isNotEmpty) {
      sessions.add(currentSession);
    }
    
    return sessions;
  }

  String _extractTopicFromTopicId(String topicId) {
    // Simple topic extraction based on topicId
    final lowerTopicId = topicId.toLowerCase();
    
    if (lowerTopicId.contains('math') || lowerTopicId.contains('calc') || lowerTopicId.contains('equation')) {
      return 'Mathematics';
    } else if (lowerTopicId.contains('history') || lowerTopicId.contains('war') || lowerTopicId.contains('century')) {
      return 'History';
    } else if (lowerTopicId.contains('science') || lowerTopicId.contains('chemistry') || lowerTopicId.contains('physics')) {
      return 'Science';
    } else if (lowerTopicId.contains('language') || lowerTopicId.contains('grammar') || lowerTopicId.contains('vocabulary')) {
      return 'Language';
    } else {
      return 'General';
    }
  }

  double _calculateConsistencyScore() {
    if (_dailyPoints.length < 7) return 0.0;
    
    final recentWeek = _dailyPoints.take(7).map((p) => p.accuracy).toList();
    final mean = recentWeek.reduce((a, b) => a + b) / recentWeek.length;
    final variance = recentWeek.map((a) => (a - mean) * (a - mean)).reduce((a, b) => a + b) / recentWeek.length;
    final stdDev = sqrt(variance);
    
    // Higher consistency = lower standard deviation
    return (100 - (stdDev * 10)).clamp(0.0, 100.0);
  }

  String _getPreferredTimeSlot(int peakHour) {
    if (peakHour < 6) return 'Early Morning';
    if (peakHour < 12) return 'Morning';
    if (peakHour < 17) return 'Afternoon';
    if (peakHour < 21) return 'Evening';
    return 'Night';
  }

  List<int> _findOutliers(List<int> times, int q1, int q3) {
    final iqr = q3 - q1;
    final lowerBound = q1 - (1.5 * iqr);
    final upperBound = q3 + (1.5 * iqr);
    
    return times.where((time) => time < lowerBound || time > upperBound).toList();
  }

  Map<String, int> _categorizeSpeed(List<int> times) {
    final fast = times.where((t) => t < 5000).length; // < 5 seconds
    final medium = times.where((t) => t >= 5000 && t < 15000).length; // 5-15 seconds
    final slow = times.where((t) => t >= 15000).length; // > 15 seconds
    
    return {
      'fast': fast,
      'medium': medium,
      'slow': slow,
    };
  }

  void _computeMotivationalMetrics() {
    if (_attempts.isEmpty) return;

    // Calculate total study time (estimated 30 seconds per question)
    _totalStudyMinutes = (_attempts.length * 30) ~/ 60;

    // Calculate questions per day (last 7 days)
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    final recentAttempts =
        _attempts.where((a) => a.timestamp.isAfter(sevenDaysAgo)).length;
    _questionsPerDay = recentAttempts / 7.0;

    // Calculate improvement rate (comparing first vs last week)
    if (_dailyPoints.length >= 14) {
      final firstWeek =
          _dailyPoints.take(7).map((p) => p.accuracy).reduce((a, b) => a + b) /
              7;
      final lastWeek = _dailyPoints
              .skip(_dailyPoints.length - 7)
              .map((p) => p.accuracy)
              .reduce((a, b) => a + b) /
          7;
      _improvementRate = ((lastWeek - firstWeek) / firstWeek) * 100;
    }

    // Calculate next milestone
    _calculateNextMilestone();
  }

  void _calculateNextMilestone() {
    final totalAttempts = _attempts.length;
    final currentStreak = _userSummary['studyStreak']?['currentStreak'] ?? 0;
    final accuracy = (_userSummary['correctAttempts'] ?? 0) /
        (_userSummary['totalAttempts'] ?? 1) *
        100;

    // Determine next milestone based on current progress
    if (totalAttempts < 50) {
      _nextMilestone = 50;
      _nextMilestoneType = 'questions';
      _daysToNextMilestone =
          ((50 - totalAttempts) / _questionsPerDay).ceil().toInt();
    } else if (totalAttempts < 100) {
      _nextMilestone = 100;
      _nextMilestoneType = 'questions';
      _daysToNextMilestone =
          ((100 - totalAttempts) / _questionsPerDay).ceil().toInt();
    } else if (currentStreak < 7) {
      _nextMilestone = 7;
      _nextMilestoneType = 'day streak';
      _daysToNextMilestone = (7 - currentStreak).toInt();
    } else if (currentStreak < 14) {
      _nextMilestone = 14;
      _nextMilestoneType = 'day streak';
      _daysToNextMilestone = (14 - currentStreak).toInt();
    } else if (accuracy < 80) {
      _nextMilestone = 80;
      _nextMilestoneType = '% accuracy';
      _daysToNextMilestone =
          ((80 - accuracy) / (_improvementRate / 7)).ceil().toInt();
    } else {
      _nextMilestone = 100;
      _nextMilestoneType = '% accuracy';
      _daysToNextMilestone =
          ((100 - accuracy) / (_improvementRate / 7)).ceil().toInt();
    }
  }

  Future<void> _createSampleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.createSampleData(widget.userId);
      await _loadData();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to create sample data: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: AppBar(
        title: Text(
          'NeuroGraph Analytics',
          style: TextStyle(
            color: context.tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.tokens.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.tokens.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: context.tokens.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your learning analytics...',
            style: TextStyle(
              fontSize: 16,
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: context.tokens.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createSampleData,
              icon: Icon(Icons.add_chart),
              label: Text('Create Sample Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.tokens.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildLearningProgressChart(),
            const SizedBox(height: 24),
            _buildWeeklyProgressChart(),
            const SizedBox(height: 24),
            _buildTopicPerformanceChart(),
            const SizedBox(height: 24),
            _buildStudyPatternsChart(),
            const SizedBox(height: 24),
            _buildAccuracyTrendsChart(),
            const SizedBox(height: 24),
            _buildTimeAnalysisChart(),
            const SizedBox(height: 24),
            _buildMotivationalMetrics(),
            const SizedBox(height: 24),
            _buildStudyStreakCard(),
            const SizedBox(height: 24),
            _buildNextMilestoneCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _chartAnimation.value),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Attempts',
                  '${_userSummary['totalAttempts'] ?? 0}',
                  Icons.quiz,
                  context.tokens.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Accuracy',
                  '${((_userSummary['correctAttempts'] ?? 0) / (_userSummary['totalAttempts'] ?? 1) * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  context.tokens.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningProgressChart() {
    if (_dailyPoints.isEmpty) {
      return _buildEmptyChartCard('Learning Progress', 'No data available');
    }

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildSimpleLineChart(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleLineChart() {
    if (_dailyPoints.isEmpty) {
      return Center(
        child: Text(
          'No progress data available',
          style: TextStyle(
            color: context.tokens.textSecondary,
          ),
        ),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: LineChartPainter(
        data: _dailyPoints.map((p) => p.accuracy).toList(),
        color: context.tokens.primary,
      ),
    );
  }

  Widget _buildMotivationalMetrics() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMetricRow(
                  'Study Time',
                  '$_totalStudyMinutes minutes',
                  Icons.timer,
                  context.tokens.primary,
                ),
                const SizedBox(height: 12),
                _buildMetricRow(
                  'Questions/Day',
                  _questionsPerDay.toStringAsFixed(1),
                  Icons.speed,
                  context.tokens.success,
                ),
                const SizedBox(height: 12),
                _buildMetricRow(
                  'Improvement Rate',
                  '${_improvementRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  _improvementRate >= 0
                      ? context.tokens.success
                      : context.tokens.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(
      String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: context.tokens.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.tokens.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStudyStreakCard() {
    final streak = _userSummary['studyStreak'] ?? {};
    final currentStreak = streak['currentStreak'] ?? 0;
    final longestStreak = streak['longestStreak'] ?? 0;

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Streak',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStreakItem(
                        'Current',
                        '$currentStreak days',
                        Icons.local_fire_department,
                        currentStreak > 0
                            ? context.tokens.primary
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStreakItem(
                        'Longest',
                        '$longestStreak days',
                        Icons.emoji_events,
                        context.tokens.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextMilestoneCard() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.tokens.primary.withOpacity(0.1),
                  context.tokens.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.tokens.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: context.tokens.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next Milestone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Reach $_nextMilestone $_nextMilestoneType',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.tokens.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _daysToNextMilestone <= 1
                      ? 'Almost there! Keep going!'
                      : 'Just $_daysToNextMilestone days to go!',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _calculateMilestoneProgress(),
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(context.tokens.primary),
                  minHeight: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateMilestoneProgress() {
    final totalAttempts = _attempts.length;
    final currentStreak = _userSummary['studyStreak']?['currentStreak'] ?? 0;
    final accuracy = (_userSummary['correctAttempts'] ?? 0) /
        (_userSummary['totalAttempts'] ?? 1) *
        100;

    if (_nextMilestoneType == 'questions') {
      return (totalAttempts / _nextMilestone).clamp(0.0, 1.0);
    } else if (_nextMilestoneType == 'day streak') {
      return (currentStreak / _nextMilestone).clamp(0.0, 1.0);
    } else if (_nextMilestoneType == '% accuracy') {
      return (accuracy / _nextMilestone).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  Widget _buildStreakItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.tokens.textPrimary,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: context.tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressChart() {
    if (_weeklyProgress.isEmpty) {
      return _buildEmptyChartCard('Weekly Progress', 'No weekly data available');
    }

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: context.tokens.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Weekly Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Shows your accuracy and question count over the last 4 weeks',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildWeeklyBarChart(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyBarChart() {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: WeeklyBarChartPainter(
        data: _weeklyProgress,
        primaryColor: context.tokens.primary,
        secondaryColor: context.tokens.secondary,
        textColor: context.tokens.textPrimary,
      ),
    );
  }

  Widget _buildEmptyChartCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: context.tokens.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicPerformanceChart() {
    if (_topicPerformance.isEmpty) {
      return _buildEmptyChartCard('Topic Performance', 'No topic data available');
    }

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.subject, color: context.tokens.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Topic Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Shows your performance across different subject areas',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._topicPerformance.take(5).map((topic) => _buildTopicRow(topic)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicRow(Map<String, dynamic> topic) {
    final accuracy = topic['accuracy'] as double;
    final strength = topic['strength'] as String;
    Color strengthColor;
    
    switch (strength) {
      case 'Strong':
        strengthColor = context.tokens.success;
        break;
      case 'Good':
        strengthColor = context.tokens.warning;
        break;
      default:
        strengthColor = context.tokens.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              topic['topic'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.tokens.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              strength,
              style: TextStyle(
                fontSize: 12,
                color: strengthColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPatternsChart() {
    if (_studyPatterns.isEmpty) {
      return _buildEmptyChartCard('Study Patterns', 'No pattern data available');
    }

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: context.tokens.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Study Patterns',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your preferred study times and consistency patterns',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPatternStats(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatternStats() {
    final peakHour = _studyPatterns['peakHour'] as int;
    final peakDay = _studyPatterns['peakDay'] as String;
    final consistency = _studyPatterns['consistency'] as double;
    final preferredTime = _studyPatterns['preferredTime'] as String;

    return Column(
      children: [
        _buildPatternRow('Peak Study Hour', '$peakHour:00', Icons.access_time),
        _buildPatternRow('Peak Study Day', peakDay, Icons.calendar_today),
        _buildPatternRow('Consistency Score', '${consistency.toStringAsFixed(1)}%', Icons.trending_up),
        _buildPatternRow('Preferred Time', preferredTime, Icons.schedule),
      ],
    );
  }

  Widget _buildPatternRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: context.tokens.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: context.tokens.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyTrendsChart() {
    if (_accuracyTrends.isEmpty) {
      return _buildEmptyChartCard('Accuracy Trends', 'No trend data available');
    }

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: context.tokens.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Accuracy Trends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily accuracy changes and learning momentum',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: _buildTrendChart(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendChart() {
    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: TrendChartPainter(
        data: _accuracyTrends,
        primaryColor: context.tokens.primary,
        successColor: context.tokens.success,
        errorColor: context.tokens.error,
      ),
    );
  }

  Widget _buildTimeAnalysisChart() {
    if (_timeAnalysis.isEmpty) {
      return _buildEmptyChartCard('Response Time Analysis', 'No time data available');
    }

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _chartAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: context.tokens.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Response Time Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your response speed patterns and time management',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTimeStats(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeStats() {
    final median = _timeAnalysis['median'] as int;
    final speedCategories = _timeAnalysis['speedCategories'] as Map<String, int>;
    
    return Column(
      children: [
        _buildTimeRow('Median Response', '${(median / 1000).toStringAsFixed(1)}s', Icons.timer),
        _buildTimeRow('Fast Responses', '${speedCategories['fast'] ?? 0}', Icons.flash_on),
        _buildTimeRow('Medium Responses', '${speedCategories['medium'] ?? 0}', Icons.timer),
        _buildTimeRow('Slow Responses', '${speedCategories['slow'] ?? 0}', Icons.slow_motion_video),
      ],
    );
  }

  Widget _buildTimeRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: context.tokens.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: context.tokens.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width / (data.length - 1);
    final height = size.height;

    for (int i = 0; i < data.length; i++) {
      final x = i * width;
      final y = height - (data[i] * height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WeeklyBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;

  WeeklyBarChartPainter({
    required this.data,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final barWidth = size.width / (data.length * 2);
    final maxAccuracy = data.map((d) => d['accuracy'] as double).reduce((a, b) => a > b ? a : b);
    final maxQuestions = data.map((d) => d['questions'] as int).reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < data.length; i++) {
      final week = data[i];
      final accuracy = week['accuracy'] as double;
      final questions = week['questions'] as int;
      final weekLabel = week['week'] as String;

      // Draw accuracy bar
      final accuracyHeight = (accuracy / maxAccuracy) * (size.height * 0.4);
      final accuracyRect = Rect.fromLTWH(
        i * barWidth * 2,
        size.height * 0.6 - accuracyHeight,
        barWidth,
        accuracyHeight,
      );

      final accuracyPaint = Paint()..color = primaryColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(accuracyRect, const Radius.circular(4)),
        accuracyPaint,
      );

      // Draw questions bar
      final questionsHeight = (questions / maxQuestions) * (size.height * 0.4);
      final questionsRect = Rect.fromLTWH(
        i * barWidth * 2 + barWidth,
        size.height * 0.6 - questionsHeight,
        barWidth,
        questionsHeight,
      );

      final questionsPaint = Paint()..color = secondaryColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(questionsRect, const Radius.circular(4)),
        questionsPaint,
      );

      // Draw week label
      textPainter.text = TextSpan(
        text: weekLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          i * barWidth * 2 + barWidth / 2 - textPainter.width / 2,
          size.height - 20,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrendChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;

  TrendChartPainter({
    required this.data,
    required this.primaryColor,
    required this.successColor,
    required this.errorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final barWidth = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final trend = point['trend'] as double;
      final direction = point['direction'] as String;

      Color barColor;
      switch (direction) {
        case 'up':
          barColor = successColor;
          break;
        case 'down':
          barColor = errorColor;
          break;
        default:
          barColor = primaryColor;
      }

      final barHeight = (trend.abs() / 100) * size.height * 0.8;
      final barRect = Rect.fromLTWH(
        i * barWidth + barWidth * 0.2,
        size.height / 2 - barHeight / 2,
        barWidth * 0.6,
        barHeight,
      );

      final barPaint = Paint()..color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        barPaint,
      );

      // Draw trend arrow
      final arrowPaint = Paint()
        ..color = barColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final arrowY = size.height / 2;
      final arrowX = i * barWidth + barWidth / 2;

      if (direction == 'up') {
        canvas.drawLine(
          Offset(arrowX, arrowY + 5),
          Offset(arrowX, arrowY - 5),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(arrowX - 3, arrowY - 2),
          Offset(arrowX, arrowY - 5),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(arrowX + 3, arrowY - 2),
          Offset(arrowX, arrowY - 5),
          arrowPaint,
        );
      } else if (direction == 'down') {
        canvas.drawLine(
          Offset(arrowX, arrowY - 5),
          Offset(arrowX, arrowY + 5),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(arrowX - 3, arrowY + 2),
          Offset(arrowX, arrowY + 5),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(arrowX + 3, arrowY + 2),
          Offset(arrowX, arrowY + 5),
          arrowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

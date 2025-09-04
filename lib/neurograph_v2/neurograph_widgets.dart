import 'package:flutter/material.dart';
import 'neurograph_config.dart';
import 'neurograph_models.dart';

/// Chart widgets for NeuroGraph V2 analytics
/// Simplified version focusing on core functionality

class NeuroGraphWidgets {
  /// Learning Curve Chart with EMA and goal band
  static Widget learningCurveChart({
    required List<DailyPoint> dailyPoints,
    required List<double> emaValues,
    required double goalMin,
    required double goalMax,
    required double chartHeight,
    required Color primaryColor,
    required Color secondaryColor,
    required Color goalColor,
  }) {
    if (dailyPoints.isEmpty) {
      return _buildEmptyChart('No learning data available', chartHeight);
    }

    return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(NeuroGraphConfig.chartPadding),
      child: Column(
        children: [
          Text(
            'Learning Curve',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleLineChart(
              dailyPoints.map((p) => p.accuracy).toList(),
              emaValues,
              primaryColor,
              secondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend([
            _LegendItem('Daily Accuracy', primaryColor),
            _LegendItem('7-day EMA', secondaryColor),
            _LegendItem('Goal Range (80-90%)', goalColor),
          ]),
        ],
      ),
    );
  }

  /// Spaced Review / Forgetting Curve Panel
  static Widget spacedReviewPanel({
    required Map<String, RecallModel> recallModels,
    required double chartHeight,
    required Color primaryColor,
    required Color accentColor,
    required VoidCallback onViewDueItems,
  }) {
    final dueItems = recallModels.values.where((model) => model.isDue).length;
    final totalItems = recallModels.length;

    return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(NeuroGraphConfig.chartPadding),
      child: Column(
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Due Today',
                  dueItems.toString(),
                  accentColor,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Total Items',
                  totalItems.toString(),
                  primaryColor,
                  Icons.list,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Forgetting curve preview
          Expanded(
            child: _buildForgettingCurvePreview(recallModels, primaryColor),
          ),
          const SizedBox(height: 8),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: dueItems > 0 ? onViewDueItems : null,
              icon: const Icon(Icons.visibility),
              label: Text('View Due Items ($dueItems)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Retrieval Practice Meter
  static Widget retrievalPracticeMeter({
    required List<WeekPoint> weekPoints,
    required double chartHeight,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    if (weekPoints.isEmpty) {
      return _buildEmptyChart('No retrieval practice data', chartHeight);
    }

    return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(NeuroGraphConfig.chartPadding),
      child: Column(
        children: [
          Text(
            'Retrieval Practice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleBarChart(
              weekPoints.map((p) => p.retrievalSessions.toDouble()).toList(),
              primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend([
            _LegendItem('Retrieval Sessions', primaryColor),
            _LegendItem('Exam Scores', secondaryColor),
          ]),
        ],
      ),
    );
  }

  /// Calibration Plot
  static Widget calibrationPlot({
    required CalibrationSummary calibration,
    required double chartHeight,
    required Color primaryColor,
    required Color errorColor,
  }) {
    if (calibration.bins.isEmpty) {
      return _buildEmptyChart('No confidence data available', chartHeight);
    }

    return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(NeuroGraphConfig.chartPadding),
      child: Column(
        children: [
          // Metrics badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricBadge(
                  'ECE',
                  calibration.expectedCalibrationError.toStringAsFixed(3),
                  errorColor),
              _buildMetricBadge('Brier',
                  calibration.brierScore.toStringAsFixed(3), primaryColor),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleScatterPlot(calibration.bins, primaryColor),
          ),
        ],
      ),
    );
  }

  /// Mastery Progress Stacked Area Chart
  static Widget masteryProgressChart({
    required List<WeekStack> weekStacks,
    required double chartHeight,
    required Color newColor,
    required Color practicingColor,
    required Color masteredColor,
  }) {
    if (weekStacks.isEmpty) {
      return _buildEmptyChart('No mastery data available', chartHeight);
    }

    return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(NeuroGraphConfig.chartPadding),
      child: Column(
        children: [
          Text(
            'Mastery Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: newColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleStackedChart(
              weekStacks,
              newColor,
              practicingColor,
              masteredColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend([
            _LegendItem('New', newColor),
            _LegendItem('Practicing', practicingColor),
            _LegendItem('Mastered', masteredColor),
          ]),
        ],
      ),
    );
  }

  /// Consistency Heatmap
  static Widget consistencyHeatmap({
    required Map<DateTime, ConsistencyHeat> heatData,
    required double chartHeight,
    required Color primaryColor,
  }) {
    if (heatData.isEmpty) {
      return _buildEmptyChart('No consistency data available', chartHeight);
    }

    // Group by weeks for display
    final weeks = _groupHeatDataByWeeks(heatData);

    return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(NeuroGraphConfig.chartPadding),
      child: Column(
        children: [
          // Current streak
          _buildStreakIndicator(heatData, primaryColor),
          const SizedBox(height: 16),
          // Heatmap grid
          Expanded(
            child: _buildHeatmapGrid(weeks, primaryColor),
          ),
        ],
      ),
    );
  }

  // Helper methods

  static Widget _buildEmptyChart(String message, double height) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(NeuroGraphConfig.chartPadding),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildForgettingCurvePreview(
      Map<String, RecallModel> models, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Forgetting Curve Preview\n${models.length} items tracked',
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  static Widget _buildSimpleLineChart(List<double> values,
      List<double> emaValues, Color primaryColor, Color secondaryColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Line Chart\n${values.length} data points',
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColor),
        ),
      ),
    );
  }

  static Widget _buildSimpleBarChart(List<double> values, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Bar Chart\n${values.length} weeks',
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  static Widget _buildSimpleScatterPlot(
      List<CalibrationBin> bins, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Scatter Plot\n${bins.length} bins',
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  static Widget _buildSimpleStackedChart(List<WeekStack> weekStacks,
      Color newColor, Color practicingColor, Color masteredColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Stacked Chart\n${weekStacks.length} weeks',
          textAlign: TextAlign.center,
          style: TextStyle(color: newColor),
        ),
      ),
    );
  }

  static Widget _buildMetricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStreakIndicator(
      Map<DateTime, ConsistencyHeat> heatData, Color color) {
    final currentStreak = _calculateCurrentStreak(heatData);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department, color: color),
          const SizedBox(width: 8),
          Text(
            '$currentStreak day${currentStreak == 1 ? '' : 's'} streak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHeatmapGrid(
      List<List<ConsistencyHeat?>> weeks, Color color) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // Days of week
        childAspectRatio: 1,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: weeks.length * 7,
      itemBuilder: (context, index) {
        final weekIndex = index ~/ 7;
        final dayIndex = index % 7;

        if (weekIndex >= weeks.length || dayIndex >= weeks[weekIndex].length) {
          return Container(color: Colors.grey[100]);
        }

        final heat = weeks[weekIndex][dayIndex];
        if (heat == null) {
          return Container(color: Colors.grey[100]);
        }

        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(heat.intensity),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              heat.attempts.toString(),
              style: TextStyle(
                fontSize: 8,
                color: heat.intensity > 0.5 ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildChartLegend(List<_LegendItem> items) {
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

  static List<List<ConsistencyHeat?>> _groupHeatDataByWeeks(
      Map<DateTime, ConsistencyHeat> heatData) {
    final weeks = <List<ConsistencyHeat?>>[];
    final sortedDates = heatData.keys.toList()..sort();

    if (sortedDates.isEmpty) return weeks;

    final startDate = sortedDates.first;
    final endDate = sortedDates.last;

    // Group by weeks
    DateTime currentWeek =
        startDate.subtract(Duration(days: startDate.weekday - 1));

    while (currentWeek.isBefore(endDate) ||
        currentWeek.isAtSameMomentAs(endDate)) {
      final week = <ConsistencyHeat?>[];

      for (int day = 0; day < 7; day++) {
        final date = currentWeek.add(Duration(days: day));
        week.add(heatData[date]);
      }

      weeks.add(week);
      currentWeek = currentWeek.add(const Duration(days: 7));
    }

    return weeks;
  }

  static int _calculateCurrentStreak(Map<DateTime, ConsistencyHeat> heatData) {
    final sortedDates = heatData.keys.toList()..sort();
    if (sortedDates.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();

    while (true) {
      final dateKey =
          DateTime(currentDate.year, currentDate.month, currentDate.day);
      if (heatData.containsKey(dateKey) && heatData[dateKey]!.studied) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

class _LegendItem {
  final String label;
  final Color color;

  _LegendItem(this.label, this.color);
}

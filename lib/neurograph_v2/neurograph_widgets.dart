import 'package:flutter/material.dart';
import '../theme.dart';
import 'neurograph_config.dart';
import 'neurograph_models.dart';

/// Chart widgets for NeuroGraph V2 analytics
/// Simplified version focusing on core functionality

class NeuroGraphWidgets {
  /// Learning Curve Chart with EMA and goal band
  static Widget learningCurveChart({
    required BuildContext context,
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
      return _buildEmptyChart(
          context, 'No learning data available', chartHeight);
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
              context,
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
    required BuildContext context,
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
                  context,
                  'Due Today',
                  dueItems.toString(),
                  accentColor,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  context,
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
    required BuildContext context,
    required List<WeekPoint> weekPoints,
    required double chartHeight,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    if (weekPoints.isEmpty) {
      return _buildEmptyChart(
          context, 'No retrieval practice data', chartHeight);
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
              context,
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
    required BuildContext context,
    required CalibrationSummary calibration,
    required double chartHeight,
    required Color primaryColor,
    required Color errorColor,
  }) {
    if (calibration.bins.isEmpty) {
      return _buildEmptyChart(
          context, 'No confidence data available', chartHeight);
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
                  context,
                  'ECE',
                  calibration.expectedCalibrationError.toStringAsFixed(3),
                  errorColor),
              _buildMetricBadge(context, 'Brier',
                  calibration.brierScore.toStringAsFixed(3), primaryColor),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleScatterPlot(
                context, calibration.bins, primaryColor),
          ),
        ],
      ),
    );
  }

  /// Mastery Progress Stacked Area Chart
  static Widget masteryProgressChart({
    required BuildContext context,
    required List<WeekStack> weekStacks,
    required double chartHeight,
    required Color newColor,
    required Color practicingColor,
    required Color masteredColor,
  }) {
    if (weekStacks.isEmpty) {
      return _buildEmptyChart(
          context, 'No mastery data available', chartHeight);
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
              context,
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
    required BuildContext context,
    required Map<DateTime, ConsistencyHeat> heatData,
    required double chartHeight,
    required Color primaryColor,
  }) {
    if (heatData.isEmpty) {
      return _buildEmptyChart(
          context, 'No consistency data available', chartHeight);
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
            child: _buildHeatmapGrid(context, weeks, primaryColor),
          ),
        ],
      ),
    );
  }

  // Helper methods

  static Widget _buildEmptyChart(
      BuildContext context, String message, double height) {
    final tokens = context.tokens;
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
              color: tokens.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: tokens.textSecondary,
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

  static Widget _buildSummaryCard(BuildContext context, String title,
      String value, Color color, IconData icon) {
    final tokens = context.tokens;
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
              color: tokens.textSecondary,
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

  static Widget _buildSimpleLineChart(BuildContext context, List<double> values,
      List<double> emaValues, Color primaryColor, Color secondaryColor) {
    final tokens = context.tokens;

    if (values.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: tokens.borderMuted),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: tokens.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderMuted),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Learning Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: tokens.borderMuted.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CustomPaint(
                painter: SimpleLineChartPainter(
                  values: values,
                  emaValues: emaValues,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  gridColor: tokens.borderMuted.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSimpleBarChart(
      BuildContext context, List<double> values, Color color) {
    final tokens = context.tokens;

    if (values.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: tokens.borderMuted),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: tokens.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderMuted),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Retrieval Sessions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: tokens.borderMuted.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CustomPaint(
                painter: SimpleBarChartPainter(
                  values: values,
                  barColor: color,
                  gridColor: tokens.borderMuted.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSimpleScatterPlot(
      BuildContext context, List<CalibrationBin> bins, Color color) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderMuted),
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

  static Widget _buildSimpleStackedChart(
      BuildContext context,
      List<WeekStack> weekStacks,
      Color newColor,
      Color practicingColor,
      Color masteredColor) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderMuted),
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

  static Widget _buildMetricBadge(
      BuildContext context, String label, String value, Color color) {
    final tokens = context.tokens;
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
              color: tokens.textSecondary,
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
      BuildContext context, List<List<ConsistencyHeat?>> weeks, Color color) {
    final tokens = context.tokens;
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
          return Container(color: tokens.surfaceAlt);
        }

        final heat = weeks[weekIndex][dayIndex];
        if (heat == null) {
          return Container(color: tokens.surfaceAlt);
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
                color: heat.intensity > 0.5
                    ? tokens.textInverse
                    : tokens.textPrimary,
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

class SimpleLineChartPainter extends CustomPainter {
  final List<double> values;
  final List<double> emaValues;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;

  SimpleLineChartPainter({
    required this.values,
    required this.emaValues,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final emaPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = gridColor;

    // Draw grid lines
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw primary line
    if (values.length > 1) {
      paint.color = primaryColor;
      final path = Path();

      for (int i = 0; i < values.length; i++) {
        final x = size.width * i / (values.length - 1);
        final y = size.height * (1 - values[i]);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }

    // Draw EMA line
    if (emaValues.length > 1) {
      emaPaint.color = secondaryColor;
      final emaPath = Path();

      for (int i = 0; i < emaValues.length; i++) {
        final x = size.width * i / (emaValues.length - 1);
        final y = size.height * (1 - emaValues[i]);

        if (i == 0) {
          emaPath.moveTo(x, y);
        } else {
          emaPath.lineTo(x, y);
        }
      }

      canvas.drawPath(emaPath, emaPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimpleBarChartPainter extends CustomPainter {
  final List<double> values;
  final Color barColor;
  final Color gridColor;

  SimpleBarChartPainter({
    required this.values,
    required this.barColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = barColor;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = gridColor;

    // Draw grid lines
    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Find max value for scaling
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return;

    // Draw bars
    final barWidth = size.width / values.length * 0.8;
    final barSpacing = size.width / values.length * 0.2;

    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxValue) * size.height * 0.8;
      final x = i * (barWidth + barSpacing) + barSpacing / 2;
      final y = size.height - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      canvas.drawRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SimpleScatterPlotPainter extends CustomPainter {
  final List<CalibrationBin> bins;
  final Color pointColor;
  final Color gridColor;

  SimpleScatterPlotPainter({
    required this.bins,
    required this.pointColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bins.isEmpty) return;

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pointColor;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = gridColor;

    // Draw grid lines
    for (int i = 0; i <= 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw diagonal line (perfect calibration)
    final diagonalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = gridColor.withOpacity(0.5);
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, 0), diagonalPaint);

    // Draw points
    for (final bin in bins) {
      final x = ((bin.confidenceMin + bin.confidenceMax) / 2) * size.width;
      final y = (1 - bin.actualAccuracy) * size.height;

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

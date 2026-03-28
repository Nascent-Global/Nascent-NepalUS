import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/burnout_score.dart';
import '../theme/app_theme.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({required this.scores, super.key});

  final List<BurnoutScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No trend data yet')),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < scores.length; i++) {
      spots.add(FlSpot(i.toDouble(), scores[i].score.toDouble()));
    }

    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.blueGrey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: AppTheme.cobalt,
              barWidth: 3,
              isCurved: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.cobalt.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

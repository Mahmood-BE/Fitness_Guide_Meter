import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

class EMGChart extends StatelessWidget {
  final List<double> data;
  final int channel;
  const EMGChart({super.key, required this.data, required this.channel});

  @override
  Widget build(BuildContext context) {
    final displayCount = 200;
    final visibleData = data.length > displayCount
        ? data.sublist(data.length - displayCount)
        : data;

    final points = visibleData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();
    //set colors based on channel
    Color color;
    switch (channel) {
      case 0:
        color = AppColors.primary;
        break;
      case 1:
        color = AppColors.secondary;
        break;
      case 2:
        color = Colors.purpleAccent;
        break;
      case 3:
      default:
        color = Colors.orangeAccent;
        break;
    }

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minX: 0,
        maxX: displayCount.toDouble(),
        minY: -1,
        maxY: 4, 
        backgroundColor: AppColors.card,
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: color,
            barWidth: 1.2,
            dotData: const FlDotData(show: false),
            curveSmoothness: 0.35,
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color.fromARGB(255, 255, 255, 255).withValues(),
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: const Color.fromARGB(255, 255, 255, 255).withValues(),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.textSecondary.withValues()),
        ),
      ),
    );
  }
}

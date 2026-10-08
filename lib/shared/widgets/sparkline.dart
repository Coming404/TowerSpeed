import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class SpeedSparkline extends StatelessWidget {
  final List<double> points;
  final double height;
  const SpeedSparkline({super.key, required this.points, this.height = 60});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('开始测速后显示实时曲线', style: t.caption)),
      );
    }
    final maxY = points.reduce((a, b) => a > b ? a : b) * 1.2;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY < 1 ? 1 : maxY,
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: c.accent,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.accent.withOpacity(0.28),
                    c.accent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
        duration: const Duration(milliseconds: 120),
        curve: Curves.linear,
      ),
    );
  }
}

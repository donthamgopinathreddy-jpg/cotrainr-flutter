import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MiniBarChart7 extends StatelessWidget {
  final List<double> values;
  final Color accent;
  final int? highlightIndex;

  const MiniBarChart7({
    super.key,
    required this.values,
    required this.accent,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox(height: 40);

    final maxY = values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) return const SizedBox(height: 40);

    return SizedBox(
      height: 40,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: values.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            final isHighlighted = highlightIndex != null && index == highlightIndex;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 5,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: isHighlighted ? accent : accent.withValues(alpha: 0.65),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class MiniLineSpark7 extends StatelessWidget {
  final List<double> values;
  final Color accent;

  const MiniLineSpark7({
    super.key,
    required this.values,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox(height: 40);

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final pad = range > 0 ? range * 0.18 : 1.0;

    return SizedBox(
      height: 40,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.6,
              barWidth: 2.5,
              color: accent,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isLast = index == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 3.5 : 2.5,
                    color: accent,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.00),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      ),
    );
  }
}

class MiniStackedBar extends StatelessWidget {
  final double consumed;
  final double target;
  final Color accent;

  const MiniStackedBar({
    super.key,
    required this.consumed,
    required this.target,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final burnedRatio = 0.4; // Mock data
    final intakeRatio = 0.6; // Mock data

    return SizedBox(
      width: 8,
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            flex: (intakeRatio * 100).round(),
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
          Expanded(
            flex: (burnedRatio * 100).round(),
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'analytics_tile_base.dart';

class CaloriesTile extends StatelessWidget {
  final int calories;
  final int target;
  final int burned;
  final int intake;
  final List<double> weekData;
  final VoidCallback? onTap;

  const CaloriesTile({
    super.key,
    required this.calories,
    required this.target,
    required this.burned,
    required this.intake,
    required this.weekData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accentColor = const Color(0xFFFF7A00);
    final burnedRatio = burned / (burned + intake).clamp(0.001, 1.0);
    final intakeRatio = intake / (burned + intake).clamp(0.001, 1.0);

    return AnalyticsTileBase(
      onTap: onTap,
      accentColor: accentColor,
      child: SizedBox(
        height: 175,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calories',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Value Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatNumber(calories),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                            height: 1.0,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Burned',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Intake',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target ${_formatNumber(target)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stacked Mini Bar
                SizedBox(
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
                            color: accentColor.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (burnedRatio * 100).round(),
                        child: Container(
                          width: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Bar Spark Chart
            SizedBox(
              height: 40,
              child: _BarSparkChart(
                values: weekData,
                accent: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class _BarSparkChart extends StatelessWidget {
  final List<double> values;
  final Color accent;

  const _BarSparkChart({required this.values, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox();
    }

    final maxY = values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) return const SizedBox();

    return BarChart(
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
          final isToday = index == values.length - 1;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                width: 8,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                color: isToday ? accent : accent.withValues(alpha: 0.6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}


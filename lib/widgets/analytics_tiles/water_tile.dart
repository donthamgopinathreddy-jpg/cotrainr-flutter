import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'analytics_tile_base.dart';

class WaterTile extends StatelessWidget {
  final double waterLiters;
  final double goalLiters;
  final List<double> weekData;
  final VoidCallback? onTap;
  final Function(double)? onQuickAdd;

  const WaterTile({
    super.key,
    required this.waterLiters,
    required this.goalLiters,
    required this.weekData,
    this.onTap,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accentColor = const Color(0xFF4DA3FF);
    final progress = (waterLiters / goalLiters).clamp(0.0, 1.0);

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
                  Icons.water_drop_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Water',
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
                          '${waterLiters.toStringAsFixed(1)}',
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
                        'L',
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
                          Text(
                            'Goal ${goalLiters.toStringAsFixed(1)}L',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Water Drop Gauge
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      accentColor.withValues(alpha: 0.3),
                                      accentColor,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.water_drop_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Quick Add Chips
            if (onQuickAdd != null) ...[
              Row(
                children: [
                  _QuickAddChip(
                    label: '+200ml',
                    onTap: () => onQuickAdd!(0.2),
                    accent: accentColor,
                  ),
                  const SizedBox(width: 6),
                  _QuickAddChip(
                    label: '+500ml',
                    onTap: () => onQuickAdd!(0.5),
                    accent: accentColor,
                  ),
                  const SizedBox(width: 6),
                  _QuickAddChip(
                    label: '+1L',
                    onTap: () => onQuickAdd!(1.0),
                    accent: accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Sparkline Chart
            SizedBox(
              height: 32,
              child: _SparklineChart(
                values: weekData,
                accent: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color accent;

  const _QuickAddChip({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: onSurface.withValues(alpha: 0.18),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _SparklineChart extends StatelessWidget {
  final List<double> values;
  final Color accent;

  const _SparklineChart({required this.values, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final pad = range > 0 ? range * 0.18 : 1.0;

    return LineChart(
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
            barWidth: 3,
            color: accent,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.00),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }
}


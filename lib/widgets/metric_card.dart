import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String valueText;
  final String subText;
  final IconData icon;
  final double progress; // 0..1
  final List<double> week; // 7 points
  final Color accent;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.subText,
    required this.icon,
    required this.progress,
    required this.week,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1F2937) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          gradient: !isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFFFF8E1).withValues(alpha: 0.3),
                    const Color(0xFFFFE0B2).withValues(alpha: 0.2),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                )
              : null,
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row - Perfectly Aligned
            Row(
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Value and Progress Row - Perfectly Aligned
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    valueText,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _RingProgress(progress: progress, accent: accent, isDark: isDark),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              subText,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 14),

            // Sparkline Graph - Consistent Height
            SizedBox(
              height: 48,
              child: _Sparkline(
                values: week,
                accent: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingProgress extends StatelessWidget {
  final double progress;
  final Color accent;
  final bool isDark;

  const _RingProgress({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF374151) : Colors.grey[200]!,
            ),
          ),
          CircularProgressIndicator(
            value: p,
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            backgroundColor: Colors.transparent,
          ),
          Text(
            "${(p * 100).round()}%",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color accent;

  const _Sparkline({required this.values, required this.accent});

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
                  accent.withValues(alpha: 0.30),
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


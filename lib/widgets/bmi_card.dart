import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class BMICard extends StatelessWidget {
  final double? bmi;
  final String? bmiStatus;
  final List<double> week;
  final VoidCallback? onTap;

  const BMICard({
    super.key,
    required this.bmi,
    required this.bmiStatus,
    required this.week,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1F2937) : Colors.white;
    final bmiValue = bmi ?? 22.5;
    final status = bmiStatus?.toUpperCase() ?? 'NORMAL';
    final accentColor = _getBMIColor(bmiStatus);

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
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.monitor_weight_rounded,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BMI',
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
            const SizedBox(height: 16),

            // BMI Value and Gauge Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // BMI Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bmiValue.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Mini Gauge
                _BMIGauge(
                  bmi: bmiValue,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sparkline Graph
            SizedBox(
              height: 48,
              child: _Sparkline(
                values: week,
                accent: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBMIColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'underweight':
        return const Color(0xFF3B82F6); // Blue
      case 'normal':
        return const Color(0xFF10B981); // Green
      case 'overweight':
        return const Color(0xFFF59E0B); // Orange
      case 'obese':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Neutral gray
    }
  }
}

class _BMIGauge extends StatelessWidget {
  final double bmi;
  final Color accentColor;
  final bool isDark;

  const _BMIGauge({
    required this.bmi,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // BMI ranges: Underweight (<18.5), Normal (18.5-24.9), Overweight (25-29.9), Obese (>=30)
    final normalizedBMI = ((bmi - 15) / (35 - 15)).clamp(0.0, 1.0);

    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: normalizedBMI,
          accentColor: accentColor,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final bool isDark;

  _GaugePainter({
    required this.progress,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF374151) : Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final backgroundPath = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        math.pi, // Start from left
        math.pi, // 180 degrees
        false,
      );
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final progressAngle = progress * math.pi;
    final progressPath = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        math.pi, // Start from left
        progressAngle,
        false,
      );
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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


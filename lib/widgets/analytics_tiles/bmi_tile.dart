import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'analytics_tile_base.dart';

class BMITile extends StatelessWidget {
  final double bmi;
  final String status;
  final List<double> trendData;
  final VoidCallback? onTap;

  const BMITile({
    super.key,
    required this.bmi,
    required this.status,
    required this.trendData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accentColor = _getBMIColor(status);

    return AnalyticsTileBase(
      onTap: onTap,
      accentColor: accentColor,
      child: SizedBox(
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  Icons.monitor_weight_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BMI',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gauge and Value Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gauge
                SizedBox(
                  width: 80,
                  height: 60,
                  child: _BMIGauge(
                    bmi: bmi,
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                // Value and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          bmi.toStringAsFixed(1),
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getRangeText(status),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Mini Trend
                SizedBox(
                  width: 40,
                  height: 40,
                  child: _MiniTrendChart(
                    values: trendData,
                    accent: accentColor,
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Color _getBMIColor(String status) {
    switch (status.toLowerCase()) {
      case 'underweight':
        return const Color(0xFF3B82F6);
      case 'normal':
        return const Color(0xFF10B981);
      case 'overweight':
        return const Color(0xFFF59E0B);
      case 'obese':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9B7CFF);
    }
  }

  String _getRangeText(String status) {
    switch (status.toLowerCase()) {
      case 'underweight':
        return 'Range <18.5';
      case 'normal':
        return 'Range 18.5–24.9';
      case 'overweight':
        return 'Range 25–29.9';
      case 'obese':
        return 'Range ≥30';
      default:
        return 'Healthy range';
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
    // Normalize BMI to 0-1 (assuming range 15-40)
    final normalized = ((bmi - 15) / (40 - 15)).clamp(0.0, 1.0);
    final angle = normalized * math.pi; // 0 to 180 degrees

    return CustomPaint(
      painter: _GaugePainter(
        bmi: bmi,
        normalized: normalized,
        angle: angle,
        accentColor: accentColor,
        isDark: isDark,
      ),
      size: const Size(80, 60),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double bmi;
  final double normalized;
  final double angle;
  final Color accentColor;
  final bool isDark;

  _GaugePainter({
    required this.bmi,
    required this.normalized,
    required this.angle,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;

    // Define segments
    final segments = [
      _Segment(0.0, 0.25, const Color(0xFF3B82F6)), // Underweight
      _Segment(0.25, 0.5, const Color(0xFF10B981)), // Normal
      _Segment(0.5, 0.75, const Color(0xFFF59E0B)), // Overweight
      _Segment(0.75, 1.0, const Color(0xFFEF4444)), // Obese
    ];

    // Draw segments
    for (final segment in segments) {
      final startAngle = math.pi * (1 - segment.end);
      final sweepAngle = math.pi * (segment.end - segment.start);
      final isActive = normalized >= segment.start && normalized <= segment.end;

      final inactiveColor = (isDark ? const Color(0xFF374151) : Colors.grey[300]!);
      final paint = Paint()
        ..color = isActive
            ? accentColor
            : inactiveColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 5 : 4
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        );
      canvas.drawPath(path, paint);
    }

    // Draw needle
    final needleAngle = math.pi * (1 - normalized);
    final needleLength = radius - 2;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Draw needle pointer (small triangle)
    final trianglePath = Path()
      ..moveTo(needleEnd.dx, needleEnd.dy)
      ..lineTo(
        needleEnd.dx + 4 * math.cos(needleAngle + math.pi / 2),
        needleEnd.dy + 4 * math.sin(needleAngle + math.pi / 2),
      )
      ..lineTo(
        needleEnd.dx + 4 * math.cos(needleAngle - math.pi / 2),
        needleEnd.dy + 4 * math.sin(needleAngle - math.pi / 2),
      )
      ..close();

    final trianglePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(trianglePath, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Segment {
  final double start;
  final double end;
  final Color color;

  _Segment(this.start, this.end, this.color);
}

class _MiniTrendChart extends StatelessWidget {
  final List<double> values;
  final Color accent;

  const _MiniTrendChart({required this.values, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || values.length < 2) {
      return const SizedBox();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final pad = range > 0 ? range * 0.2 : 0.5;

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
            barWidth: 2,
            color: accent,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
    );
  }
}


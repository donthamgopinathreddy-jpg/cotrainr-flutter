import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

enum ChartType { circular, line, bar }

class MorphingAnalyticsWidget extends StatefulWidget {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final int currentValue;
  final int goal;
  final List<int> weeklyData;
  final String unit;
  final bool isDark;
  final VoidCallback? onTap;

  const MorphingAnalyticsWidget({
    super.key,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.currentValue,
    required this.goal,
    required this.weeklyData,
    required this.unit,
    required this.isDark,
    this.onTap,
  });

  @override
  State<MorphingAnalyticsWidget> createState() => _MorphingAnalyticsWidgetState();
}

class _MorphingAnalyticsWidgetState extends State<MorphingAnalyticsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ChartType _currentChartType = ChartType.circular;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSwipeUp() {
    if (_currentChartType == ChartType.circular) {
      setState(() {
        _currentChartType = ChartType.line;
      });
      _controller.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  void _handleSwipeLeft() {
    if (_currentChartType == ChartType.circular) {
      setState(() {
        _currentChartType = ChartType.bar;
      });
      _controller.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapDown() {
    if (_currentChartType == ChartType.circular && widget.onTap != null) {
      widget.onTap?.call();
    }
  }

  void _handleDataPointTap(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
    HapticFeedback.selectionClick();
  }

  void _resetToCircular() {
    if (_currentChartType != ChartType.circular) {
      setState(() {
        _currentChartType = ChartType.circular;
        _selectedIndex = null;
      });
      _controller.reverse(from: 1.0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Swipe up
          _handleSwipeUp();
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Swipe left
          _handleSwipeLeft();
        } else if (details.primaryVelocity! > 0 && _currentChartType != ChartType.circular) {
          // Swipe right - reset
          _resetToCircular();
        }
      },
      onTapDown: (_) => _handleTapDown(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _buildChart(),
      ),
    );
  }

  Widget _buildChart() {
    switch (_currentChartType) {
      case ChartType.circular:
        return _CircularChart(
          key: const ValueKey('circular'),
          icon: widget.icon,
          gradientStart: widget.gradientStart,
          gradientEnd: widget.gradientEnd,
          progress: (widget.currentValue / widget.goal).clamp(0.0, 1.0),
          currentValue: widget.currentValue,
          goal: widget.goal,
          unit: widget.unit,
          isDark: widget.isDark,
        );
      case ChartType.line:
        return _LineChart(
          key: const ValueKey('line'),
          icon: widget.icon,
          gradientStart: widget.gradientStart,
          gradientEnd: widget.gradientEnd,
          data: widget.weeklyData,
          goal: widget.goal,
          unit: widget.unit,
          isDark: widget.isDark,
          selectedIndex: _selectedIndex,
          onDataPointTap: _handleDataPointTap,
          animationValue: Curves.easeOutCubic.transform(_controller.value),
        );
      case ChartType.bar:
        return _BarChart(
          key: const ValueKey('bar'),
          icon: widget.icon,
          gradientStart: widget.gradientStart,
          gradientEnd: widget.gradientEnd,
          data: widget.weeklyData,
          goal: widget.goal,
          unit: widget.unit,
          isDark: widget.isDark,
          selectedIndex: _selectedIndex,
          onDataPointTap: _handleDataPointTap,
          animationValue: Curves.easeOutCubic.transform(_controller.value),
        );
    }
  }
}

// Circular Progress Ring
class _CircularChart extends StatefulWidget {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final double progress;
  final int currentValue;
  final int goal;
  final String unit;
  final bool isDark;

  const _CircularChart({
    super.key,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.progress,
    required this.currentValue,
    required this.goal,
    required this.unit,
    required this.isDark,
  });

  @override
  State<_CircularChart> createState() => _CircularChartState();
}

class _CircularChartState extends State<_CircularChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final breathingValue = 0.95 + (_breathingController.value * 0.05);
          return CustomPaint(
            painter: _CircularProgressPainter(
              progress: widget.progress,
              gradientStart: widget.gradientStart,
              gradientEnd: widget.gradientEnd,
              breathingValue: breathingValue,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 32,
                    color: widget.gradientStart,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.currentValue}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color gradientStart;
  final Color gradientEnd;
  final double breathingValue;

  _CircularProgressPainter({
    required this.progress,
    required this.gradientStart,
    required this.gradientEnd,
    required this.breathingValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * breathingValue - 10;
    final strokeWidth = 8.0;

    // Background ring
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
      colors: [gradientStart, gradientEnd],
    );
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.breathingValue != breathingValue;
  }
}

// Line Chart
class _LineChart extends StatelessWidget {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final List<int> data;
  final int goal;
  final String unit;
  final bool isDark;
  final int? selectedIndex;
  final Function(int) onDataPointTap;
  final double animationValue;

  const _LineChart({
    super.key,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.data,
    required this.goal,
    required this.unit,
    required this.isDark,
    this.selectedIndex,
    required this.onDataPointTap,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: gradientStart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                // Chart
                CustomPaint(
                  size: Size.infinite,
                  painter: _LineChartPainter(
                    data: data,
                    maxValue: maxValue,
                    gradientStart: gradientStart,
                    gradientEnd: gradientEnd,
                    selectedIndex: selectedIndex,
                    animationValue: animationValue,
                  ),
                ),
                // Data points
                ...List.generate(data.length, (index) {
                  final x = (index / (data.length - 1)) * MediaQuery.of(context).size.width;
                  final y = 150 - ((data[index] / maxValue) * 150 * animationValue);
                  return Positioned(
                    left: x - 12,
                    top: y - 12,
                    child: GestureDetector(
                      onTap: () => onDataPointTap(index),
                      child: AnimatedScale(
                        scale: selectedIndex == index ? 1.3 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [gradientStart, gradientEnd],
                            ),
                            boxShadow: selectedIndex == index
                                ? [
                                    BoxShadow(
                                      color: gradientStart.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // Tooltip
                if (selectedIndex != null)
                  Positioned(
                    left: ((selectedIndex! / (data.length - 1)) * (MediaQuery.of(context).size.width - 32)) - 50,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${data[selectedIndex!]}$unit',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            days[selectedIndex!],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Date labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              return Text(
                day,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> data;
  final double maxValue;
  final Color gradientStart;
  final Color gradientEnd;
  final int? selectedIndex;
  final double animationValue;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.gradientStart,
    required this.gradientEnd,
    this.selectedIndex,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final path = Path();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw gradient line
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] / maxValue) * size.height * animationValue);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final gradient = LinearGradient(
      colors: [gradientStart, gradientEnd],
    );
    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.animationValue != animationValue;
  }
}

// Bar Chart
class _BarChart extends StatelessWidget {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final List<int> data;
  final int goal;
  final String unit;
  final bool isDark;
  final int? selectedIndex;
  final Function(int) onDataPointTap;
  final double animationValue;

  const _BarChart({
    super.key,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.data,
    required this.goal,
    required this.unit,
    required this.isDark,
    this.selectedIndex,
    required this.onDataPointTap,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: gradientStart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(data.length, (index) {
                final height = (data[index] / maxValue) * 150 * animationValue;
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () => onDataPointTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: (MediaQuery.of(context).size.width - 64) / data.length - 4,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [gradientStart, gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: gradientStart.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    transform: Matrix4.identity()
                      ..scale(isSelected ? 1.05 : 1.0),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              return Text(
                day,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


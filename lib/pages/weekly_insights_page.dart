import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/sensor_service.dart';

enum MetricType { steps, calories, water, bmi }

class WeeklyInsightsPage extends StatefulWidget {
  final MetricType metricType;
  
  const WeeklyInsightsPage({
    super.key,
    this.metricType = MetricType.steps,
  });

  @override
  State<WeeklyInsightsPage> createState() => _WeeklyInsightsPageState();
}

class _WeeklyInsightsPageState extends State<WeeklyInsightsPage>
    with SingleTickerProviderStateMixin {
  final SensorService _sensorService = SensorService();
  late AnimationController _animationController;
  late Animation<double> _graphAnimation;
  
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());
  List<int> _weeklyData = [];
  int _currentValue = 0;
  int _goal = 0;
  double _average = 0;
  int _bestDay = 0;
  int _lowestDay = 0;
  double _goalCompletion = 0;

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _graphAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      switch (widget.metricType) {
        case MetricType.steps:
          _currentValue = _sensorService.stepCount > 0 ? _sensorService.stepCount : 9500;
          _goal = 10000;
          _weeklyData = [8500, 9200, 7800, 10500, 9800, 11200, _currentValue];
          break;
        case MetricType.calories:
          _currentValue = 2200;
          _goal = 2500;
          _weeklyData = [2100, 2300, 2000, 2400, 2200, 2500, _currentValue];
          break;
        case MetricType.water:
          _currentValue = 1500;
          _goal = 2000;
          _weeklyData = [1800, 2000, 1600, 2200, 1900, 2100, _currentValue];
          break;
        case MetricType.bmi:
          _currentValue = 0; // BMI doesn't use this
          _goal = 0;
          _weeklyData = [22.1, 22.2, 22.0, 22.3, 22.1, 22.4, 22.5].map((e) => (e * 10).round()).toList();
          break;
      }
      
      _average = _weeklyData.reduce((a, b) => a + b) / _weeklyData.length;
      _bestDay = _weeklyData.reduce(math.max);
      _lowestDay = _weeklyData.reduce(math.min);
      _goalCompletion = widget.metricType == MetricType.bmi
          ? 0
          : (_average / _goal * 100).clamp(0.0, 100.0);
    });
  }

  List<Color> _getGradientColors() {
    switch (widget.metricType) {
      case MetricType.steps:
        return [const Color(0xFF14B8A6), const Color(0xFF06B6D4)]; // Green/Teal
      case MetricType.calories:
        return [const Color(0xFFF59E0B), const Color(0xFFEF4444)]; // Orange/Red
      case MetricType.water:
        return [const Color(0xFF3B82F6), const Color(0xFF06B6D4)]; // Blue/Cyan
      case MetricType.bmi:
        return [const Color(0xFF6B7280), const Color(0xFF9CA3AF)]; // Neutral
    }
  }

  IconData _getMetricIcon() {
    switch (widget.metricType) {
      case MetricType.steps:
        return Icons.directions_walk;
      case MetricType.calories:
        return Icons.local_fire_department;
      case MetricType.water:
        return Icons.water_drop;
      case MetricType.bmi:
        return Icons.monitor_weight;
    }
  }

  String _getMetricName() {
    switch (widget.metricType) {
      case MetricType.steps:
        return 'Steps';
      case MetricType.calories:
        return 'Calories';
      case MetricType.water:
        return 'Water';
      case MetricType.bmi:
        return 'BMI';
    }
  }

  String _getUnit() {
    switch (widget.metricType) {
      case MetricType.steps:
        return 'steps';
      case MetricType.calories:
        return 'kcal';
      case MetricType.water:
        return 'ml';
      case MetricType.bmi:
        return '';
    }
  }

  String _getInsightNote() {
    if (widget.metricType == MetricType.steps) {
      return 'You walked more on weekdays. Keep it up!';
    } else if (widget.metricType == MetricType.calories) {
      return 'Your calorie burn was consistent this week.';
    } else if (widget.metricType == MetricType.water) {
      return 'Water intake dropped on weekends. Try to stay hydrated!';
    } else {
      return 'Your BMI is within a healthy range.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _getGradientColors();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getMetricIcon(),
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getMetricName(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Weekly Insights',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selector
                  _buildDateSelector(isDark),
                  const SizedBox(height: 24),

                  // Main Analytics Graph
                  _buildMainGraph(isDark, gradientColors),
                  const SizedBox(height: 24),

                  // Summary Cards
                  _buildSummaryCards(isDark),
                  const SizedBox(height: 24),

                  // Insight Notes
                  _buildInsightNotes(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    final weekDays = List.generate(7, (index) {
      return _selectedWeekStart.add(Duration(days: index));
    });
    final today = DateTime.now();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final date = weekDays[index];
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final dayName = _getDayName(date.weekday);
          final dayNumber = date.day;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              // Update analytics for selected date
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.only(right: index < weekDays.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isToday
                    ? _getGradientColors()[0].withValues(alpha: 0.2)
                    : (isDark ? const Color(0xFF1F2937) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: isToday
                    ? Border.all(color: _getGradientColors()[0], width: 2)
                    : null,
                gradient: !isDark && !isToday
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          const Color(0xFFFFF8E1).withValues(alpha: 0.3),
                        ],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isToday
                          ? _getGradientColors()[0]
                          : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? _getGradientColors()[0]
                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
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

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildMainGraph(bool isDark, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _graphAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GraphPainter(
                    data: _weeklyData,
                    goal: _goal,
                    metricType: widget.metricType,
                    gradientColors: gradientColors,
                    isDark: isDark,
                    animationValue: _graphAnimation.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Average',
            widget.metricType == MetricType.bmi
                ? '${(_average / 10).toStringAsFixed(1)}'
                : _average.toInt().toString(),
            _getUnit(),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Best Day',
            widget.metricType == MetricType.bmi
                ? '${(_bestDay / 10).toStringAsFixed(1)}'
                : _bestDay.toString(),
            _getUnit(),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Lowest',
            widget.metricType == MetricType.bmi
                ? '${(_lowestDay / 10).toStringAsFixed(1)}'
                : _lowestDay.toString(),
            _getUnit(),
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Goal',
            widget.metricType == MetricType.bmi
                ? '-'
                : '${_goalCompletion.toInt()}%',
            '',
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, String unit, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        gradient: !isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFFF8E1).withValues(alpha: 0.2),
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightNotes(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: !isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFFF8E1).withValues(alpha: 0.3),
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: _getGradientColors()[0],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getInsightNote(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<int> data;
  final int goal;
  final MetricType metricType;
  final List<Color> gradientColors;
  final bool isDark;
  final double animationValue;

  _GraphPainter({
    required this.data,
    required this.goal,
    required this.metricType,
    required this.gradientColors,
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce(math.max).toDouble();
    final minValue = data.reduce(math.min).toDouble();
    final range = maxValue - minValue;
    final padding = 40.0;
    final graphWidth = size.width - (padding * 2);
    final graphHeight = size.height - (padding * 2);
    final stepX = graphWidth / (data.length - 1);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gradient = LinearGradient(
      colors: gradientColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    switch (metricType) {
      case MetricType.steps:
        _drawLineGraph(canvas, size, paint, gradient, stepX, graphHeight, padding, maxValue, range);
        if (goal > 0) {
          _drawGoalLine(canvas, size, paint, graphHeight, padding, maxValue, range);
        }
        break;
      case MetricType.calories:
        _drawLineGraph(canvas, size, paint, gradient, stepX, graphHeight, padding, maxValue, range);
        _drawAverageLine(canvas, size, paint, graphHeight, padding, maxValue, range);
        break;
      case MetricType.water:
        _drawBarGraph(canvas, size, paint, gradient, stepX, graphHeight, padding, maxValue, range);
        if (goal > 0) {
          _drawGoalLine(canvas, size, paint, graphHeight, padding, maxValue, range);
        }
        break;
      case MetricType.bmi:
        _drawLineGraph(canvas, size, paint, gradient, stepX, graphHeight, padding, maxValue, range);
        _drawBMIZones(canvas, size, graphHeight, padding);
        break;
    }
  }

  void _drawLineGraph(Canvas canvas, Size size, Paint paint, Gradient gradient, double stepX,
      double graphHeight, double padding, double maxValue, double range) {
    final path = Path();
    final points = <Offset>[];
    final minValue = data.reduce(math.min).toDouble();

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX);
      final normalizedValue = range > 0
          ? ((data[i] - minValue) / range)
          : 0.5;
      final y = padding + graphHeight - (normalizedValue * graphHeight * animationValue);
      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        final prevPoint = points[i - 1];
        final controlPoint1 = Offset(prevPoint.dx + (point.dx - prevPoint.dx) / 2, prevPoint.dy);
        final controlPoint2 = Offset(prevPoint.dx + (point.dx - prevPoint.dx) / 2, point.dy);
        path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy,
            point.dx, point.dy);
      }
    }

    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 6, Paint()..color = gradientColors[0]);
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  void _drawBarGraph(Canvas canvas, Size size, Paint paint, Gradient gradient, double stepX,
      double graphHeight, double padding, double maxValue, double range) {
    final barWidth = stepX * 0.6;
    final minValue = data.reduce(math.min).toDouble();

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * stepX) - (barWidth / 2);
      final normalizedValue = range > 0
          ? ((data[i] - minValue) / range)
          : 0.5;
      final barHeight = normalizedValue * graphHeight * animationValue;
      final y = padding + graphHeight - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

      paint.shader = gradient.createShader(rect);
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(rrect, paint);
    }
  }

  void _drawGoalLine(Canvas canvas, Size size, Paint paint, double graphHeight, double padding,
      double maxValue, double range) {
    final minValue = data.reduce(math.min).toDouble();
    final normalizedGoal = range > 0
        ? ((goal - minValue) / range)
        : 0.5;
    final y = padding + graphHeight - (normalizedGoal * graphHeight);

    paint
      ..shader = null
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw dashed line manually
    final dashWidth = 5.0;
    final dashSpace = 5.0;
    final startX = padding;
    final endX = size.width - padding;
    double currentX = startX;
    
    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, y),
        Offset(math.min(currentX + dashWidth, endX), y),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawAverageLine(Canvas canvas, Size size, Paint paint, double graphHeight, double padding,
      double maxValue, double range) {
    final minValue = data.reduce(math.min).toDouble();
    final average = data.reduce((a, b) => a + b) / data.length;
    final normalizedAvg = range > 0
        ? ((average - minValue) / range)
        : 0.5;
    final y = padding + graphHeight - (normalizedAvg * graphHeight);

    paint
      ..shader = null
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw dashed line manually
    final dashWidth = 5.0;
    final dashSpace = 5.0;
    final startX = padding;
    final endX = size.width - padding;
    double currentX = startX;
    
    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, y),
        Offset(math.min(currentX + dashWidth, endX), y),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawBMIZones(Canvas canvas, Size size, double graphHeight, double padding) {
    final zones = [
      {'min': 0, 'max': 18.5, 'color': Colors.blue},
      {'min': 18.5, 'max': 25, 'color': Colors.green},
      {'min': 25, 'max': 30, 'color': Colors.orange},
      {'min': 30, 'max': 40, 'color': Colors.red},
    ];

    for (final zone in zones) {
      final minY = padding + graphHeight - ((zone['min'] as num) / 40 * graphHeight);
      final maxY = padding + graphHeight - ((zone['max'] as num) / 40 * graphHeight);
      final zoneHeight = maxY - minY;

      final paint = Paint()
        ..color = (zone['color'] as Color).withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(padding, minY, size.width - (padding * 2), zoneHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

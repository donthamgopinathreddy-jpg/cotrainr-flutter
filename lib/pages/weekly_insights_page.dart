import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class WeeklyInsightsPage extends StatefulWidget {
  final String type; // 'steps', 'calories', or 'water'
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final int currentValue;
  final int goal;
  final List<int> weeklyData;

  const WeeklyInsightsPage({
    super.key,
    required this.type,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.currentValue,
    required this.goal,
    required this.weeklyData,
  });

  @override
  State<WeeklyInsightsPage> createState() => _WeeklyInsightsPageState();
}

class _WeeklyInsightsPageState extends State<WeeklyInsightsPage>
    with TickerProviderStateMixin {
  late AnimationController _ringAnimationController;
  late AnimationController _valueAnimationController;
  late AnimationController _chartAnimationController;
  int _selectedDay = DateTime.now().weekday - 1; // 0-6 for Mon-Sun
  final DateTime _selectedWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ringAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _valueAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _ringAnimationController.forward();
    _valueAnimationController.forward();
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _ringAnimationController.dispose();
    _valueAnimationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  String _formatValue(int value) {
    if (widget.type == 'water') {
      return '${(value / 1000).toStringAsFixed(1)}L';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (widget.currentValue / widget.goal).clamp(0.0, 1.0);
    final total = widget.weeklyData.reduce((a, b) => a + b);
    final average = (total / widget.weeklyData.length).round();
    final maxValue = widget.weeklyData.reduce(math.max);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            _buildHeader(isDark),

            // Hero Section with Progress Ring
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildHeroSection(progress, isDark),
              ),
            ),

            // Calendar Strip
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDayBreakdown(isDark),
              ),
            ),

            // Weekly Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildWeeklyChart(isDark),
              ),
            ),

            // Summary Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
                child: _buildSummaryStats(average, maxValue, isDark),
              ),
            ),

            // Water Quick Actions (only for water type)
            if (widget.type == 'water')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
                  child: _buildWaterQuickActions(isDark),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: widget.type == 'water'
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showWaterPresetsSheet(isDark);
              },
              backgroundColor: widget.gradientColors[0],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // Header
  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFFAFAFA),
      toolbarHeight: 72,
      leading:
          const SizedBox.shrink(), // Hide default leading, we'll add it in Stack
      flexibleSpace: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.gradientColors[0].withValues(alpha: 0.1),
                widget.gradientColors[1].withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Left: Back button
                Positioned(
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                // Center: Title and date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.title} Insights',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dec 04 - Dec 10, 2024',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                // Right: Calendar icon
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Date picker
                    },
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hero Section with Progress Ring
  Widget _buildHeroSection(double progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.gradientColors[0].withValues(alpha: 0.15),
            widget.gradientColors[1].withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.gradientColors[0].withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left: Icon and Label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.gradientColors[0].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.type == 'steps'
                      ? Icons.directions_run_rounded
                      : widget.icon,
                  color: widget.gradientColors[0],
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Center: Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _valueAnimationController,
                  builder: (context, child) {
                    final animatedValue =
                        (widget.currentValue * _valueAnimationController.value)
                            .round();
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatValue(animatedValue),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'of ${_formatValue(widget.goal)} goal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Right: Progress Ring
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _ringAnimationController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: progress * _ringAnimationController.value,
                        strokeWidth: 7,
                        backgroundColor: isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.gradientColors[0],
                        ),
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.gradientColors[0],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Weekly Chart - Line Graph
  Widget _buildWeeklyChart(bool isDark) {
    final now = DateTime.now();
    final weekStart = _selectedWeek.subtract(
      Duration(days: _selectedWeek.weekday - 1),
    );
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Overview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Line Chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _LineChartPainter(
                data: widget.weeklyData,
                selectedIndex: _selectedDay,
                gradientColors: widget.gradientColors,
                isDark: isDark,
                animationValue: _chartAnimationController.value,
              ),
              child: GestureDetector(
                onTapDown: (details) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(
                    details.globalPosition,
                  );
                  final chartWidth = box.size.width;
                  final itemWidth = chartWidth / widget.weeklyData.length;
                  final tappedIndex = (localPosition.dx / itemWidth).floor();
                  if (tappedIndex >= 0 &&
                      tappedIndex < widget.weeklyData.length) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedDay = tappedIndex;
                    });
                  }
                },
                child: Container(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.weeklyData.length, (index) {
              final day = weekStart.add(Duration(days: index));
              final isSelected = _selectedDay == index;
              final isToday =
                  day.day == now.day &&
                  day.month == now.month &&
                  day.year == now.year;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedDay = index;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.gradientColors[0],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatValue(widget.weeklyData[index]),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const SizedBox(height: 19),
                      Text(
                        dayLabels[index],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? widget.gradientColors[0]
                              : (isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isToday
                              ? widget.gradientColors[0]
                              : (isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Summary Stats
  Widget _buildSummaryStats(int average, int maxValue, bool isDark) {
    final total = widget.weeklyData.reduce((a, b) => a + b);
    final goalHit = widget.weeklyData
        .where((value) => value >= widget.goal)
        .length;

    final stats = [
      {
        'label': 'Total',
        'value': _formatValue(total),
        'icon': Icons.calculate_rounded,
      },
      {
        'label': 'Average',
        'value': _formatValue(average),
        'icon': Icons.equalizer_rounded,
      },
      {
        'label': 'Best Day',
        'value': _formatValue(maxValue),
        'icon': Icons.star_rounded,
      },
      {
        'label': 'Goal Hit',
        'value': '$goalHit days',
        'icon': Icons.check_circle_rounded,
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                Expanded(child: _buildStatItem(stats[i], isDark)),
                if (i < stats.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(Map<String, dynamic> stat, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: widget.gradientColors[0].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            stat['icon'] as IconData,
            color: widget.gradientColors[0],
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            stat['value'] as String,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat['label'] as String,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Calendar Strip
  Widget _buildDayBreakdown(bool isDark) {
    final now = DateTime.now();
    final weekStart = _selectedWeek.subtract(
      Duration(days: _selectedWeek.weekday - 1),
    );

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected = _selectedDay == index;
          final isToday =
              day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedDay = index;
              });
            },
            child: Container(
              width: 56,
              margin: EdgeInsets.only(right: index < 6 ? 12 : 0),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: widget.gradientColors)
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? const Color(0xFF1F2937) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: widget.gradientColors[0], width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: widget.gradientColors[0].withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Water Quick Actions
  Widget _buildWaterQuickActions(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Add',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWaterButton('250ml', 250, isDark),
              _buildWaterButton('500ml', 500, isDark),
              _buildWaterButton('750ml', 750, isDark),
              _buildWaterButton('1L', 1000, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton(String label, int ml, bool isDark) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Add water
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: widget.gradientColors[0].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.gradientColors[0].withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.gradientColors[0],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _showWaterPresetsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Water',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWaterButton('250ml', 250, isDark),
                _buildWaterButton('500ml', 500, isDark),
                _buildWaterButton('750ml', 750, isDark),
                _buildWaterButton('1L', 1000, isDark),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Line Chart Painter
class _LineChartPainter extends CustomPainter {
  final List<int> data;
  final int selectedIndex;
  final List<Color> gradientColors;
  final bool isDark;
  final double animationValue;

  _LineChartPainter({
    required this.data,
    required this.selectedIndex,
    required this.gradientColors,
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce(math.max);
    if (maxValue == 0) return;

    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final pointSpacing = chartWidth / (data.length - 1);

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * pointSpacing);
      final normalizedValue = (data[i] / maxValue) * animationValue;
      final y = size.height - padding - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw gradient area under line
    final path = Path();
    path.moveTo(points[0].dx, size.height - padding);
    for (var point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, size.height - padding);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        gradientColors[0].withValues(alpha: 0.2),
        gradientColors[1].withValues(alpha: 0.05),
      ],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Draw line
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cp1x = p0.dx + (p1.dx - p0.dx) / 2;
      final cp1y = p0.dy;
      final cp2x = p0.dx + (p1.dx - p0.dx) / 2;
      final cp2y = p1.dy;
      linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p1.dx, p1.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = gradientColors[0]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final isSelected = i == selectedIndex;
      final point = points[i];

      // Outer circle
      canvas.drawCircle(
        point,
        isSelected ? 8.0 : 5.0,
        Paint()
          ..color = isSelected
              ? gradientColors[0]
              : gradientColors[0].withValues(alpha: 0.6)
          ..style = PaintingStyle.fill,
      );

      // Inner circle
      canvas.drawCircle(
        point,
        isSelected ? 4.0 : 2.5,
        Paint()
          ..color = isDark ? const Color(0xFF1F2937) : Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.animationValue != animationValue;
  }
}

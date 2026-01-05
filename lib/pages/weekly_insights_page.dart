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

class _WeeklyInsightsPageState extends State<WeeklyInsightsPage> with TickerProviderStateMixin {
  late AnimationController _ringAnimationController;
  late AnimationController _valueAnimationController;
  late AnimationController _chartAnimationController;
  int _selectedDay = DateTime.now().weekday - 1; // 0-6 for Mon-Sun
  DateTime _selectedWeek = DateTime.now();
  
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
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sticky Header (60-90px with gradient accent)
          _buildStickyHeader(isDark),
          
          // Hero Metric Card
          SliverToBoxAdapter(
            child: _buildHeroMetricCard(progress, isDark),
          ),
          
          // Calendar Strip
          SliverToBoxAdapter(
            child: _buildCalendarStrip(isDark),
          ),
          
          // Graph Card
          SliverToBoxAdapter(
            child: _buildGraphCard(isDark),
          ),
          
          // Breakdown Cards (Horizontal)
          SliverToBoxAdapter(
            child: _buildBreakdownCards(average, maxValue, isDark),
          ),
          
          // Water Presets (only for water type)
          if (widget.type == 'water')
            SliverToBoxAdapter(
              child: _buildWaterSection(isDark),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: widget.type == 'water'
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showWaterPresetsSheet(isDark);
              },
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // Sticky Header (60-90px with accent gradient)
  Widget _buildStickyHeader(bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.gradientColors[0].withValues(alpha: 0.12),
              widget.gradientColors[1].withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.title} Insights',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Dec 04 - Dec 10',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Date picker
                  },
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hero Metric Card
  Widget _buildHeroMetricCard(double progress, bool isDark) {
    final trendPercent = 8.0; // vs Last Week
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Metric Name + Today Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _valueAnimationController,
                      builder: (context, child) {
                        final animatedValue = (widget.currentValue * _valueAnimationController.value).round();
                        return Text(
                          _formatValue(animatedValue),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Right: Animated Ring with Center Icon
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ringAnimationController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: progress * _ringAnimationController.value,
                            strokeWidth: 8,
                            backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(widget.gradientColors[0]),
                          ),
                        );
                      },
                    ),
                    Icon(
                      widget.icon,
                      color: widget.gradientColors[0],
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Trend Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.gradientColors[0].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 4),
                Text(
                  '+$trendPercent% vs Last Week',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.gradientColors[0],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calendar Strip (7 days)
  Widget _buildCalendarStrip(bool isDark) {
    final now = DateTime.now();
    final weekStart = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected = _selectedDay == index;
          final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedDay = index;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: widget.gradientColors,
                      )
                    : null,
                color: isSelected ? null : (isDark ? const Color(0xFF1F2937) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: widget.gradientColors[0], width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: widget.gradientColors[0].withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
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

  // Graph Card
  Widget _buildGraphCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Overview',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.weeklyData.length, (index) {
                final value = widget.weeklyData[index];
                final maxValue = widget.weeklyData.reduce(math.max);
                final height = (value / maxValue) * 160;
                final isSelected = _selectedDay == index;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedDay = index;
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _chartAnimationController,
                      builder: (context, child) {
                        final animatedHeight = height * _chartAnimationController.value;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isSelected
                                  ? widget.gradientColors
                                  : [
                                      widget.gradientColors[0].withValues(alpha: 0.6),
                                      widget.gradientColors[1].withValues(alpha: 0.6),
                                    ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: widget.gradientColors[0].withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, -4),
                                    ),
                                  ]
                                : null,
                          ),
                          height: animatedHeight,
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Breakdown Cards (Horizontal: BestDay, Avg, GoalHit, Streak)
  Widget _buildBreakdownCards(int average, int maxValue, bool isDark) {
    final breakdowns = [
      {'label': 'Best Day', 'value': maxValue.toString(), 'icon': Icons.emoji_events},
      {'label': 'Average', 'value': average.toString(), 'icon': Icons.calculate},
      {'label': 'Goal Hit', 'value': '5', 'icon': Icons.check_circle},
      {'label': 'Streak', 'value': '7', 'icon': Icons.local_fire_department},
    ];
    
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: breakdowns.length,
        itemBuilder: (context, index) {
          final item = breakdowns[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showBreakdownDetail(item['label'] as String, isDark);
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                ),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: widget.gradientColors[0],
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['value'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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

  // Water Section (only for water type)
  Widget _buildWaterSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Add Water',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildWaterPresetChip('250ml', 250, isDark),
              _buildWaterPresetChip('500ml', 500, isDark),
              _buildWaterPresetChip('750ml', 750, isDark),
              _buildWaterPresetChip('1L', 1000, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterPresetChip(String label, int ml, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Add water
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
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
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildWaterPresetChip('250ml', 250, isDark),
                _buildWaterPresetChip('500ml', 500, isDark),
                _buildWaterPresetChip('750ml', 750, isDark),
                _buildWaterPresetChip('1L', 1000, isDark),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBreakdownDetail(String label, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

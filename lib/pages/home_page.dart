import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notifications_page.dart';
import 'messages_page.dart' show ConversationsListPage;
import 'meal_tracker_page.dart';
import 'video_sessions_page.dart';
import 'weekly_insights_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _streakController;
  late AnimationController _chartController;
  late ScrollController _scrollController;
  
  // Data
  final String _userName = 'Diana Soe';
  final String _userID = '@dianasoe';
  final int _steps = 8234;
  final int _goalSteps = 10000;
  final int _calories = 1856;
  double _water = 1500; // ml
  final double _waterGoal = 2500; // ml
  final int _streak = 7; // days
  final double _bmi = 24.3;
  final double _height = 170; // cm
  final double _weight = 70; // kg
  final int _notificationCount = 3;
  final List<int> _weeklySteps = [7500, 8200, 6900, 8500, 9100, 8800, 8234];
  
  @override
  void initState() {
    super.initState();
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollController = ScrollController();
    
    _streakController.forward();
    _chartController.forward();
  }

  @override
  void dispose() {
    _streakController.dispose();
    _chartController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarSize = 60.0; // 56-64 range
    final avatarRadius = avatarSize / 2;
    final coverHeight = 240.0; // Fixed height 220-260 range
    final headerBottomPadding = avatarRadius + 16; // Avatar radius + spacing
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(seconds: 1));
        },
        color: const Color(0xFF14B8A6),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Area: Cover + Profile with SliverAppBar
            _buildTopAreaSliver(coverHeight, avatarSize, isDark),
            
            // Padding for avatar overlap (avatarRadius + spacing)
            SliverToBoxAdapter(
              child: SizedBox(height: headerBottomPadding),
            ),
            
            // Streak Card
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildStreakCard(isDark), 0),
            ),
            
            // Analytics Tiles Section
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildAnalyticsSection(isDark), 60),
            ),
            
            // Quick Actions Grid
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildQuickActionsGrid(isDark), 120),
            ),
            
            // CoCircle Preview
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildCoCirclePreview(isDark), 180),
            ),
            
            // Nearby Centers Preview
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildNearbyCentersPreview(isDark), 240),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // Top Area: Cover Image + Profile with SliverAppBar
  Widget _buildTopAreaSliver(double coverHeight, double avatarSize, bool isDark) {
    final avatarRadius = avatarSize / 2;
    final avatarTop = coverHeight - avatarRadius; // Position: coverHeight - (avatarSize/2)
    
    return SliverAppBar(
      expandedHeight: coverHeight + avatarRadius, // Extra height for avatar
      floating: false,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
        clipBehavior: Clip.none, // Remove clipping
        children: [
          // Cover Image (full height)
          Positioned.fill(
            bottom: avatarRadius, // Extend below to account for avatar
            child: _buildCoverImage(coverHeight, isDark),
          ),
          
          // Dark Gradient Overlay (bottom to top, opacity 0.55)
          Positioned.fill(
            bottom: avatarRadius,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // Content: Bell Icon (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: SizedBox(
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (_notificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Avatar (positioned at bottom, overlapping)
          Positioned(
            left: 16,
            top: avatarTop,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Text Column (aligned to avatar center, right of avatar)
          Positioned(
            left: 16 + avatarSize + 12, // Left padding + avatar size + gap
            right: 16 + 44 + 16, // Right padding + bell width + padding
            top: avatarTop,
            child: SizedBox(
              height: avatarSize,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome text (small, above name)
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Name (right of avatar, maxLines=1, ellipsis)
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Cover Image (Full Width, No Blur - only on this layer)
  Widget _buildCoverImage(double coverHeight, bool isDark) {
    return Container(
      width: double.infinity,
      height: coverHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF14B8A6).withValues(alpha: 0.3),
            const Color(0xFF84CC16).withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Image.network(
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        width: double.infinity,
        height: coverHeight,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          // Loading placeholder - gradient only, NO BLUR
          return Container(
            width: double.infinity,
            height: coverHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF14B8A6).withValues(alpha: 0.5),
                  const Color(0xFF84CC16).withValues(alpha: 0.7),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: coverHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF14B8A6),
                  const Color(0xFF84CC16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Streak Card
  Widget _buildStreakCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Flame icon + "Daily Streak"
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Text(
            'Daily Streak',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Center: Big "7 Days"
          Text(
            '$_streak Days',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          // Right: Mini 7 bar sticks animated fill
          Row(
            children: List.generate(7, (index) {
              final isActive = index < _streak;
              return AnimatedBuilder(
                animation: _streakController,
                builder: (context, child) {
                  final delay = index * 0.1;
                  final progress = ((_streakController.value - delay).clamp(0.0, 1.0) * 1.0).clamp(0.0, 1.0);
                  return Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: 4,
                    height: isActive ? 20 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFF59E0B).withOpacity(0.3 + (progress * 0.7))
                          : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // Analytics Tiles Section
  Widget _buildAnalyticsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Row 1: Steps Big Tile (full width or 2/3 width)
          _buildStepsBigTile(isDark),
          const SizedBox(height: 12),
          // Row 2: Calories (left) + Water (right)
          Row(
            children: [
              Expanded(child: _buildCaloriesSmallTile(isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildWaterSmallTile(isDark)),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: BMI Wide Tile (full width)
          _buildBMITile(isDark),
        ],
      ),
    );
  }

  // Steps Big Tile
  Widget _buildStepsBigTile(bool isDark) {
    final progress = (_steps / _goalSteps).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeeklyInsightsPage(
              type: 'steps',
              title: 'Steps',
              icon: Icons.directions_walk,
              gradientColors: const [Color(0xFF14B8A6), Color(0xFF84CC16)],
              currentValue: _steps,
              goal: _goalSteps,
              weeklyData: _weeklySteps,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: footprint icon, "Steps", chevron
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_walk,
                        color: Color(0xFF14B8A6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Steps',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right_rounded, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            // Main Value: 8234 (large) + Goal Text "/10000"
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(_steps),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Text(
                    '/ $_goalSteps',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Graph: 7-day bar graph with today highlight
            SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _chartController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: StepsBarGraphPainter(
                      data: _weeklySteps,
                      goal: _goalSteps,
                      animationValue: _chartController.value,
                      isDark: isDark,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Progress Ring (optional mini ring top right) - animate from 0 to 82%
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% of goal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: AnimatedBuilder(
                    animation: _chartController,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: progress * _chartController.value,
                        strokeWidth: 4,
                        backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Calories Small Tile
  Widget _buildCaloriesSmallTile(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeeklyInsightsPage(
              type: 'calories',
              title: 'Calories',
              icon: Icons.whatshot,
              gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFF8FA3)],
              currentValue: _calories,
              goal: 2000,
              weeklyData: const [1800, 1900, 1750, 2000, 1850, 1950, 1856],
            ),
          ),
        );
      },
      child: Container(
        height: 140, // Fixed height to match water tile
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.whatshot, color: Color(0xFFFF6B6B), size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_calories',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const Text(
                  'kcal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            // Mini line graph
            SizedBox(
              height: 30,
              child: AnimatedBuilder(
                animation: _chartController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CaloriesLineGraphPainter(
                      animationValue: _chartController.value,
                      isDark: isDark,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Water Small Tile
  Widget _buildWaterSmallTile(bool isDark) {
    final progress = (_water / _waterGoal).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeeklyInsightsPage(
              type: 'water',
              title: 'Water',
              icon: Icons.water_drop,
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
              currentValue: _water.round(),
              goal: _waterGoal.round(),
              weeklyData: [2000, 2200, 1800, 2400, 2100, 2300, _water.round()],
            ),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showAddWaterSheet(isDark);
      },
      child: Container(
        height: 140, // Fixed height to match calories tile
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.water_drop, color: Color(0xFF3B82F6), size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(_water / 1000).toStringAsFixed(1)}L',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '/ ${(_waterGoal / 1000).toStringAsFixed(1)}L',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            // Mini progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWaterSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            // Preset buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterPresetButtonSheet('150ml', 150, isDark),
                _buildWaterPresetButtonSheet('250ml', 250, isDark),
                _buildWaterPresetButtonSheet('500ml', 500, isDark),
                _buildWaterPresetButtonSheet('750ml', 750, isDark),
              ],
            ),
            const SizedBox(height: 20),
            // Custom slider
            Text(
              'Custom: ${_water.round()}ml',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            Slider(
              value: _water,
              min: 0,
              max: _waterGoal,
              divisions: 50,
              onChanged: (value) {
                setState(() {
                  _water = value;
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterPresetButtonSheet(String label, int ml, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _water = (_water + ml).clamp(0.0, _waterGoal);
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
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

  // BMI Wide Tile
  Widget _buildBMITile(bool isDark) {
    String status;
    Color statusColor;
    if (_bmi < 18.5) {
      status = 'Underweight';
      statusColor = const Color(0xFF2196F3);
    } else if (_bmi < 25) {
      status = 'Normal';
      statusColor = const Color(0xFF4CAF50);
    } else if (_bmi < 30) {
      status = 'Overweight';
      statusColor = const Color(0xFFFF9800);
    } else {
      status = 'Obese';
      statusColor = const Color(0xFFF44336);
    }
    
    final bmiPosition = ((_bmi - 15) / 20).clamp(0.0, 1.0); // Scale 15-35 to 0-1
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to Body Metrics
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BMI',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _bmi.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Height: ${_height.toStringAsFixed(0)}cm • Weight: ${_weight.toStringAsFixed(1)}kg',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            // Graph: BMI scale gradient bar with marker (animated slide)
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF2196F3),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  bottomLeft: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF44336),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(6),
                                  bottomRight: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 800),
                      left: constraints.maxWidth * bmiPosition - 10,
                      top: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Quick Actions Horizontal Strip (New Design)
  Widget _buildQuickActionsGrid(bool isDark) {
    final actions = [
      {'icon': Icons.restaurant_menu_rounded, 'label': 'Meal Tracker', 'color': const Color(0xFF10B981)},
      {'icon': Icons.videocam_rounded, 'label': 'Video Sessions', 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.auto_awesome_rounded, 'label': 'AI Planner', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.people_rounded, 'label': 'CoCircle', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.message_rounded, 'label': 'Messages', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.location_on_rounded, 'label': 'Nearby', 'color': const Color(0xFFEF4444)},
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return Padding(
                  padding: EdgeInsets.only(right: index < actions.length - 1 ? 12 : 0),
                  child: _buildQuickAccessTile(
                    action['icon'] as IconData,
                    action['label'] as String,
                    action['color'] as Color,
                    isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessTile(IconData icon, String label, Color color, bool isDark) {
    return _QuickAccessTileWidget(
      icon: icon,
      label: label,
      color: color,
      isDark: isDark,
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToQuickAction(label);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        // Show quick actions bottom sheet
      },
    );
  }

  void _navigateToQuickAction(String label) {
    switch (label) {
      case 'Meal Tracker':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MealTrackerPage()),
        );
        break;
      case 'Video Sessions':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VideoSessionsPage()),
        );
        break;
      case 'Messages':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConversationsListPage()),
        );
        break;
      case 'Nearby':
        // Navigate to Discover page with map
        break;
      default:
        break;
    }
  }

  // CoCircle Preview Feed Section
  Widget _buildCoCirclePreview(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CoCircle',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to CoCircle tab
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&index=$index',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '@user$index',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.favorite_rounded, size: 12, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  '${42 + index * 10}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  // Nearby Centers Preview
  Widget _buildNearbyCentersPreview(bool isDark) {
    final categories = [
      'Gyms', 'Yoga', 'Pilates', 'MMA', 'Physio', 'Wellness',
      'Meditation', 'Nutrition Clinic', 'Running Club', 'Cycling Club',
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nearby',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          // Category Chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: index == 0
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // List Cards (3)
          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Center ${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.${5 + index}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${1.2 + index * 0.5} km',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Toggle favorite
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        size: 24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Open in Google Maps
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.directions_rounded,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Animation helper
  Widget _buildAnimatedSection(Widget child, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 480 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}

// Quick Access Tile - Horizontal Strip Design (120x96, rounded 24)
class _QuickAccessTileWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _QuickAccessTileWidget({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_QuickAccessTileWidget> createState() => _QuickAccessTileWidgetState();
}

class _QuickAccessTileWidgetState extends State<_QuickAccessTileWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          final scale = 1.0 - (_scaleController.value * 0.04); // 0.96 -> 1.0
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 120,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withValues(alpha: widget.isDark ? 0.15 : 0.1),
                    widget.color.withValues(alpha: widget.isDark ? 0.05 : 0.03),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: _isPressed ? 0.25 : 0.15),
                    blurRadius: _isPressed ? 18 : 12,
                    spreadRadius: 0,
                    offset: Offset(0, _isPressed ? 8 : 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon (top left, 28-32 size)
                        Icon(
                          widget.icon,
                          color: widget.color,
                          size: 30,
                        ),
                        const Spacer(),
                        // Title (bottom left)
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Glow dot (top right - optional indicator)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
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

// Custom Painters
class StepsBarGraphPainter extends CustomPainter {
  final List<int> data;
  final int goal;
  final double animationValue;
  final bool isDark;

  StepsBarGraphPainter({
    required this.data,
    required this.goal,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = goal.toDouble();
    final barWidth = size.width / data.length;
    final todayIndex = data.length - 1;

    for (int i = 0; i < data.length; i++) {
      final height = (data[i] / maxValue) * size.height * animationValue;
      final isToday = i == todayIndex;
      
      final barPaint = Paint()
        ..color = isToday ? const Color(0xFF14B8A6) : const Color(0xFF14B8A6).withOpacity(0.6)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * barWidth + 2,
            size.height - height,
            barWidth - 4,
            height,
          ),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CaloriesLineGraphPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  CaloriesLineGraphPainter({
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width, size.height * 0.2),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    final visiblePoints = (points.length * animationValue).ceil();
    for (int i = 1; i < visiblePoints && i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

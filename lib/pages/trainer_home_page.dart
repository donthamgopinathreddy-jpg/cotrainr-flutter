import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notifications_page.dart';
import 'weekly_insights_page.dart';
import 'nearby_map_screen.dart';
import '../services/streak_service.dart';
import '../services/daily_stats_service.dart';
import '../services/step_counter_service.dart';
import '../widgets/home_header_stack.dart';
import '../widgets/quick_access_widget.dart';
import '../widgets/home_shared_components.dart';
import '../config/home_tiles_config.dart';
import 'dart:async';

class TrainerHomePage extends StatefulWidget {
  const TrainerHomePage({super.key});

  @override
  State<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends State<TrainerHomePage> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _streakController;
  late AnimationController _chartController;
  late ScrollController _scrollController;

  // Data - Same as client home (trainer sees their own stats)
  String _userName = 'Loading...';
  int _steps = 0;
  final int _goalSteps = 10000;
  int _calories = 0;
  double _water = 0; // ml
  double _waterGoal = 2500; // ml
  int _streak = 0; // days
  double? _bmi;
  double? _height; // cm
  double? _weight; // kg
  int _notificationCount = 0;
  List<int> _weeklySteps = [0, 0, 0, 0, 0, 0, 0];
  List<int> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];
  List<int> _weeklyWater = [0, 0, 0, 0, 0, 0, 0];
  
  // Profile images
  String? _coverImageUrl;
  String? _avatarImageUrl;
  
  bool _isLoading = true;
  Timer? _stepUpdateTimer;

  @override
  void initState() {
    super.initState();
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollController = ScrollController();

    _streakController.forward();
    _chartController.forward();
    
    StreakService.recordLogin();
    _fetchUserProfile();
    _fetchStreak();
    _fetchDailyStats();
    _fetchNotificationCount();
    _startStepUpdates();
  }
  
  void _startStepUpdates() {
    _stepUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted) {
        await _updateStepsFromSensor();
      }
    });
    _updateStepsFromSensor();
  }
  
  Future<void> _updateStepsFromSensor() async {
    try {
      final sensorSteps = await StepCounterService.getCurrentStepCount();
      final todayStats = await DailyStatsService.getTodayStats();
      final dbSteps = todayStats['steps'] as int? ?? 0;
      final maxSteps = sensorSteps > dbSteps ? sensorSteps : dbSteps;
      
      if (maxSteps > _steps && mounted) {
        setState(() {
          _steps = maxSteps;
          _calories = DailyStatsService.calculateCaloriesFromSteps(_steps);
        });
        
        if (sensorSteps > dbSteps) {
          await DailyStatsService.updateSteps(sensorSteps);
        }
      }
    } catch (e) {
      print('Error updating steps from sensor: $e');
    }
  }
  
  Future<void> _fetchStreak() async {
    try {
      final streak = await StreakService.getCurrentStreak();
      if (mounted) {
        setState(() {
          _streak = streak;
        });
      }
    } catch (e) {
      print('Error fetching streak: $e');
    }
  }

  Future<void> _fetchDailyStats() async {
    try {
      final todayStats = await DailyStatsService.getTodayStats();
      final weeklyData = await DailyStatsService.getWeeklyStats('all');
      
      if (mounted) {
        setState(() {
          _steps = todayStats['steps'] as int? ?? 0;
          final storedCalories = todayStats['calories_burned'] as int? ?? 0;
          final calculatedCalories = DailyStatsService.calculateCaloriesFromSteps(_steps);
          if (storedCalories == 0 || (calculatedCalories - storedCalories).abs() > 50) {
            _calories = calculatedCalories;
            DailyStatsService.updateTodayStats(caloriesBurned: calculatedCalories).catchError((e) {
              print('Error auto-updating calories: $e');
            });
          } else {
            _calories = storedCalories;
          }
          
          _water = (todayStats['water_ml'] as int? ?? 0).toDouble();
          
          if (weeklyData.isNotEmpty) {
            _weeklySteps = weeklyData.map((d) => d['steps'] as int? ?? 0).toList();
            _weeklyCalories = weeklyData.map((d) {
              final steps = d['steps'] as int? ?? 0;
              final stored = d['calories_burned'] as int? ?? 0;
              return stored > 0 ? stored : DailyStatsService.calculateCaloriesFromSteps(steps);
            }).toList();
            _weeklyWater = weeklyData.map((d) => d['water_ml'] as int? ?? 0).toList();
          }
        });
      }
    } catch (e) {
      print('❌ [TRAINER_HOME] Error fetching daily stats: $e');
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      int count = 0;
      // TODO: Count trainer-specific notifications
      
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      print('❌ [TRAINER_HOME] Error fetching notification count: $e');
    }
  }
  
  Future<void> _fetchUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null && mounted) {
        setState(() {
          _userName = response['display_name'] ?? 
                     '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim();
          if (_userName.isEmpty) {
            _userName = response['user_id'] ?? 'Trainer';
          }
          _height = response['height_cm'] != null ? (response['height_cm'] as num).toDouble() : null;
          _weight = response['weight_kg'] != null ? (response['weight_kg'] as num).toDouble() : null;
          _bmi = response['bmi'] != null ? (response['bmi'] as num).toDouble() : null;
          
          if (_weight != null && _weight! > 0) {
            _waterGoal = DailyStatsService.calculateRecommendedWater(_weight!).toDouble();
          }
          
          _coverImageUrl = response['cover_path'] != null 
              ? supabase.storage.from('covers').getPublicUrl(response['cover_path'])
              : null;
          _avatarImageUrl = response['avatar_path'] != null
              ? supabase.storage.from('avatars').getPublicUrl(response['avatar_path'])
              : null;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ [TRAINER_HOME] Error fetching profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _stepUpdateTimer?.cancel();
    _streakController.dispose();
    _chartController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF6F7FB),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await StreakService.recordLogin();
          await _fetchStreak();
          await _fetchUserProfile();
          await _fetchDailyStats();
          await _fetchNotificationCount();
        },
        color: const Color(0xFF14B8A6),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Stack - Using shared widget
            SliverToBoxAdapter(
              child: HomeHeaderStack(
                userName: _userName,
                coverImageUrl: _coverImageUrl,
                avatarImageUrl: _avatarImageUrl,
                notificationCount: _notificationCount,
                onNotificationTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
                onAvatarTap: () {
                  // TODO: Open avatar picker
                },
                onCoverEditTap: () {
                  // TODO: Open cover picker
                },
                isLoading: _isLoading,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Streak Tile - Same as client
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStreakCard(isDark),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Analytics Tiles Section - Same as client (steps, calories, water, BMI)
            SliverToBoxAdapter(
              child: buildAnimatedSection(_buildAnalyticsSection(isDark), 60),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Quick Access - Using shared widget with role config
            SliverToBoxAdapter(
              child: buildAnimatedSection(
                QuickAccessWidget(
                  title: 'Quick access',
                  tiles: HomeTilesConfig(UserRole.trainer).getQuickAccessTiles(context),
                  isDark: isDark,
                ),
                120,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // CoCircle Preview - Same as client
            SliverToBoxAdapter(
              child: buildAnimatedSection(_buildCoCirclePreview(isDark), 180),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Nearby Centers Preview - Same as client
            SliverToBoxAdapter(
              child: buildAnimatedSection(
                _buildNearbyCentersPreview(isDark),
                240,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // Streak Card - Same as client
  Widget _buildStreakCard(bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _streakController, curve: Curves.easeOut),
          ),
      child: FadeTransition(
        opacity: _streakController,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_streak Day Streak',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keep it up!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 50,
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final dayIndex = 6 - index;
                    final isActive = dayIndex < _streak;
                    return Container(
                      width: 4,
                      height: isActive ? (dayIndex % 2 == 0 ? 18 : 14) : 4,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                              )
                            : null,
                        color: isActive
                            ? null
                            : (isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Analytics Section - Same as client (steps, calories, water, BMI)
  Widget _buildAnalyticsSection(bool isDark) {
    final shouldShowBMI = _bmi != null || (_height != null && _weight != null);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildStepsBigTile(isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCaloriesSmallTile(isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildWaterSmallTile(isDark)),
            ],
          ),
          if (shouldShowBMI) ...[
            const SizedBox(height: 12),
            _buildBMITile(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsBigTile(bool isDark) {
    final progress = (_steps / _goalSteps).clamp(0.0, 1.0);
    return CardPressWrapper(
      onTap: () {
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
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.directions_walk_rounded,
                                color: Color(0xFF14B8A6),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Steps',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${formatNumber(_steps)}/$_goalSteps',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 20,
                          child: AnimatedBuilder(
                            animation: _chartController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: SparklinePainter(
                                  data: _weeklySteps,
                                  animationValue: _chartController.value,
                                  isDark: isDark,
                                  color: const Color(0xFF14B8A6),
                                ),
                                size: Size.infinite,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _chartController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress * _chartController.value,
                              strokeWidth: 10,
                              backgroundColor: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF14B8A6),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        );
                      },
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
              weeklyData: _weeklyCalories,
            ),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              height: 130,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                  const Icon(
                    Icons.whatshot,
                    color: Color(0xFFFF6B6B),
                    size: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_calories',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
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
                  SizedBox(
                    height: 24,
                    child: AnimatedBuilder(
                      animation: _chartController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SparklinePainter(
                            data: _weeklyCalories.isNotEmpty 
                                ? _weeklyCalories
                                : const [1800, 1900, 1750, 2000, 1850, 1950, 1856],
                            animationValue: _chartController.value,
                            isDark: isDark,
                            color: const Color(0xFFFF6B6B),
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
        },
      ),
    );
  }

  Widget _buildWaterSmallTile(bool isDark) {
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
              weeklyData: _weeklyWater.isNotEmpty ? _weeklyWater : [2000, 2200, 1800, 2400, 2100, 2300, _water.round()],
            ),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showAddWaterSheet(isDark);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              height: 130,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.water_drop,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          try {
                            await DailyStatsService.addWater(250);
                            await _fetchDailyStats();
                          } catch (e) {
                            print('Error adding 250ml water: $e');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '+250ml',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_water / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        '/ ${(_waterGoal / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 22,
                    child: AnimatedBuilder(
                      animation: _chartController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SparklinePainter(
                            data: _weeklyWater.isNotEmpty 
                                ? _weeklyWater
                                : [2000, 2200, 1800, 2400, 2100, 2300, _water.round()],
                            animationValue: _chartController.value,
                            isDark: isDark,
                            color: const Color(0xFF3B82F6),
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
        },
      ),
    );
  }

  Widget _buildBMITile(bool isDark) {
    double? bmi = _bmi;
    if (bmi == null && _height != null && _weight != null && _height! > 0) {
      final heightM = _height! / 100.0;
      bmi = _weight! / (heightM * heightM);
    }
    
    if (bmi == null) return Container();
    
    String status;
    Color statusColor;
    if (bmi < 18.5) {
      status = 'Underweight';
      statusColor = const Color(0xFF2196F3);
    } else if (bmi < 25) {
      status = 'Normal';
      statusColor = const Color(0xFF4CAF50);
    } else if (bmi < 30) {
      status = 'Overweight';
      statusColor = const Color(0xFFFF9800);
    } else {
      status = 'Obese';
      statusColor = const Color(0xFFF44336);
    }

    final bmiPosition = ((bmi - 15) / 20).clamp(0.0, 1.0);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
              bmi.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Height: ${_height?.toStringAsFixed(0) ?? 'N/A'}cm • Weight: ${_weight?.toStringAsFixed(1) ?? 'N/A'}kg',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterPresetButton('250ml', 250, isDark),
                _buildWaterPresetButton('500ml', 500, isDark),
                _buildWaterPresetButton('750ml', 750, isDark),
                _buildWaterPresetButton('1L', 1000, isDark),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterPresetButton(String label, int ml, bool isDark) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        try {
          await DailyStatsService.addWater(ml);
          await _fetchDailyStats();
        } catch (e) {
          print('Error adding water: $e');
        }
        if (mounted) {
          Navigator.pop(context);
        }
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

  // CoCircle Preview - Same as client
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&index=$index',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
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
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${42 + index * 10}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
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

  // Nearby Centers Preview - Same as client
  Widget _buildNearbyCentersPreview(bool isDark) {
    final categories = [
      'Gyms',
      'Yoga',
      'Pilates',
      'MMA',
      'Physio',
      'Wellness',
      'Meditation',
      'Nutrition Clinic',
      'Running Club',
      'Cycling Club',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              IconButton(
                icon: const Icon(Icons.map_outlined),
                color: const Color(0xFF14B8A6),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NearbyMapScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFF6366F1)
                        : (isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFF3F4F6)),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_rounded,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categories[index],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(index + 1) * 0.5} km away',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'dart:async';
import '../services/streak_service.dart';
import '../services/daily_stats_service.dart';
import '../services/step_counter_service.dart';

class NutritionistHomePage extends StatefulWidget {
  const NutritionistHomePage({super.key});

  @override
  State<NutritionistHomePage> createState() => _NutritionistHomePageState();
}

class _NutritionistHomePageState extends State<NutritionistHomePage> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _streakController;
  late AnimationController _chartController;
  late ScrollController _scrollController;

  // Data
  String _userName = 'Loading...';
  int _steps = 0;
  final int _goalSteps = 10000;
  int _calories = 0;
  double _water = 0;
  double _waterGoal = 2500;
  int _streak = 0;
  double? _bmi;
  double? _height;
  double? _weight;
  int _notificationCount = 0;
  
  // Nutritionist specific stats
  int _pendingMealReviews = 0;
  int _expiringPlans = 0;
  int _upcomingSessions = 0;
  
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
    _fetchNutritionistStats();
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
          
          if (_weight != null && _weight! > 0) {
            _waterGoal = DailyStatsService.calculateRecommendedWater(_weight!).toDouble();
          }
        });
      }
    } catch (e) {
      print('❌ [NUTRITIONIST_HOME] Error fetching daily stats: $e');
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      int count = 0;
      // TODO: Count nutritionist-specific notifications
      
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      print('❌ [NUTRITIONIST_HOME] Error fetching notification count: $e');
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
            _userName = response['user_id'] ?? 'Nutritionist';
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
      print('❌ [NUTRITIONIST_HOME] Error fetching profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchNutritionistStats() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // TODO: Fetch actual stats from connections and meal logs
      // For now, use placeholder values
      if (mounted) {
        setState(() {
          _pendingMealReviews = 0;
          _expiringPlans = 0;
          _upcomingSessions = 0;
        });
      }
    } catch (e) {
      print('❌ [NUTRITIONIST_HOME] Error fetching nutritionist stats: $e');
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
    final avatarSize = 50.0;

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
          await _fetchNutritionistStats();
        },
        color: const Color(0xFF14B8A6),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Stack (same as client home)
            SliverToBoxAdapter(child: _buildHeaderStack(avatarSize, isDark)),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Streak Tile
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStreakCard(isDark),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Analytics Tiles Section
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildAnalyticsSection(isDark), 60),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Nutritionist Workload Tiles
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildWorkloadSection(isDark), 120),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Quick Actions Grid
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildQuickActionsGrid(isDark), 180),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Client Spotlight
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildClientSpotlight(isDark), 240),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // Reuse header from home_page.dart structure
  Widget _buildHeaderStack(double avatarSize, bool isDark) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bodyBg = isDarkMode
        ? const Color(0xFF0B1220)
        : const Color(0xFFF6F7FB);
    final coverH = 300.0;
    final blurH = 180.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: SizedBox(
              height: coverH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _buildCoverImage(isDarkMode),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [_buildNotificationButtonTopRight()],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: coverH - blurH,
                    child: _buildSmoothBlurBlend(bodyBg),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmoothBlurBlend(Color bodyBg) {
    return ClipRect(
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 0.65, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.4),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  bodyBg.withValues(alpha: 0.3),
                  bodyBg.withValues(alpha: 0.7),
                  bodyBg,
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 24,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBottomLeftAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: bodyBg == const Color(0xFF0B1220)
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF1F2937).withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoading ? 'Loading...' : _userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: bodyBg == const Color(0xFF0B1220)
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLeftAvatar() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: _avatarImageUrl != null
            ? Image.network(
                _avatarImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    child: const Icon(Icons.person, color: Colors.white, size: 36),
                  );
                },
              )
            : Container(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
      ),
    );
  }

  Widget _buildNotificationButtonTopRight() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to notifications
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
          if (_notificationCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(bool isDark) {
    if (_coverImageUrl != null) {
      return Image.network(
        _coverImageUrl!,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCover(isDark);
        },
      );
    }
    return _buildDefaultCover(isDark);
  }
  
  Widget _buildDefaultCover(bool isDark) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.3),
            const Color(0xFF84CC16).withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }

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
            ],
          ),
        ),
      ),
    );
  }

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
    return Container(
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatNumber(_steps)}/$_goalSteps',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesSmallTile(bool isDark) {
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildWaterSmallTile(bool isDark) {
    return Container(
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
        ],
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

    return Container(
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
        ],
      ),
    );
  }

  Widget _buildWorkloadSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Workload',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWorkloadCard(
                  'Meal Reviews',
                  '$_pendingMealReviews',
                  Icons.restaurant_menu_rounded,
                  const Color(0xFF10B981),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWorkloadCard(
                  'Off Plan',
                  '0',
                  Icons.warning_rounded,
                  const Color(0xFFFF9800),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWorkloadCard(
                  'Plans Expiring',
                  '$_expiringPlans',
                  Icons.calendar_today_rounded,
                  const Color(0xFF6366F1),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWorkloadCard(
                  'Sessions',
                  '$_upcomingSessions',
                  Icons.videocam_rounded,
                  const Color(0xFFEC4899),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(bool isDark) {
    final actions = [
      {
        'icon': Icons.people_rounded,
        'label': 'Clients',
        'color': const Color(0xFF6366F1),
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'label': 'Meal Reviews',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.assignment_rounded,
        'label': 'Create Diet Plan',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.videocam_rounded,
        'label': 'Video Sessions',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.message_rounded,
        'label': 'Messages',
        'color': const Color(0xFF3B82F6),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick access',
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
                  padding: EdgeInsets.only(
                    right: index < actions.length - 1 ? 12 : 0,
                  ),
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

  Widget _buildQuickAccessTile(
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to respective pages
      },
      child: Container(
        width: 140,
        height: 96,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2937)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSpotlight(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Client Spotlight',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'No clients yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notifications_page.dart';
import 'messages_page.dart' show ConversationsListPage;
import 'meal_tracker_page_v2.dart';
import 'video_sessions_page.dart';
import 'weekly_insights_page.dart';
import 'ai_planner_page.dart';
import 'nearby_map_screen.dart';
import '../services/streak_service.dart';
import '../services/daily_stats_service.dart';
import '../services/step_counter_service.dart';
import 'dart:async';

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

  // Data - Now fetched from Supabase
  String _userName = 'Loading...';
  String? _userID;
  int _steps = 0;
  final int _goalSteps = 10000;
  int _calories = 0;
  double _water = 0; // ml
  double _waterGoal = 2500; // ml - will be calculated from weight
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
      duration: const Duration(milliseconds: 160), // Slide up + fade 160ms
    );
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollController = ScrollController();

    _streakController.forward();
    _chartController.forward();
    
    // Record daily login
    StreakService.recordLogin();
    
    // Fetch user profile data, streak, daily stats, and notification count
    _fetchUserProfile();
    _fetchStreak();
    _fetchDailyStats();
    _fetchNotificationCount();
    
    // Start periodic step updates from sensor
    _startStepUpdates();
  }
  
  void _startStepUpdates() {
    // Update steps every 10 seconds from step counter service
    _stepUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted) {
        await _updateStepsFromSensor();
      }
    });
    
    // Initial update
    _updateStepsFromSensor();
  }
  
  Future<void> _updateStepsFromSensor() async {
    try {
      // Get current step count from sensor
      final sensorSteps = await StepCounterService.getCurrentStepCount();
      
      // Get database steps
      final todayStats = await DailyStatsService.getTodayStats();
      final dbSteps = todayStats['steps'] as int? ?? 0;
      
      // Use the higher value (sensor might reset, but we keep the max)
      final maxSteps = sensorSteps > dbSteps ? sensorSteps : dbSteps;
      
      if (maxSteps > _steps && mounted) {
        setState(() {
          _steps = maxSteps;
          // Recalculate calories
          _calories = DailyStatsService.calculateCaloriesFromSteps(_steps);
        });
        
        // Sync to database if sensor has more steps
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
      // Fetch all weekly data (not just steps)
      final weeklyData = await DailyStatsService.getWeeklyStats('all');
      
      if (mounted) {
        setState(() {
          _steps = todayStats['steps'] as int? ?? 0;
          final storedCalories = todayStats['calories_burned'] as int? ?? 0;
          
          // Auto-calculate calories from steps if calories is 0 or needs updating
          // Only update if stored calories is 0 or significantly different from calculated
          final calculatedCalories = DailyStatsService.calculateCaloriesFromSteps(_steps);
          if (storedCalories == 0 || (calculatedCalories - storedCalories).abs() > 50) {
            // Update calories in database
            _calories = calculatedCalories;
            DailyStatsService.updateTodayStats(caloriesBurned: calculatedCalories).catchError((e) {
              print('Error auto-updating calories: $e');
            });
          } else {
            _calories = storedCalories;
          }
          
          _water = (todayStats['water_ml'] as int? ?? 0).toDouble();
          
          // Update weekly data - extract all three metrics
          if (weeklyData.isNotEmpty) {
            _weeklySteps = weeklyData.map((d) => d['steps'] as int? ?? 0).toList();
            _weeklyCalories = weeklyData.map((d) {
              final steps = d['steps'] as int? ?? 0;
              final stored = d['calories_burned'] as int? ?? 0;
              // Auto-calculate if missing
              return stored > 0 ? stored : DailyStatsService.calculateCaloriesFromSteps(steps);
            }).toList();
            _weeklyWater = weeklyData.map((d) => d['water_ml'] as int? ?? 0).toList();
          }
        });
      }
    } catch (e) {
      print('❌ [HOME] Error fetching daily stats: $e');
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Count unread notifications from various sources
      int count = 0;

      // Count unread follows (last 7 days)
      try {
        final follows = await supabase
            .from('follows')
            .select('created_at')
            .eq('following_id', userId)
            .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
            .limit(10);
        count += (follows as List).length;
      } catch (e) {
        print('Error counting follows: $e');
      }

      // Count unread likes (last 7 days) - likes on current user's posts
      try {
        // First get user's post IDs
        final userPosts = await supabase
            .from('posts')
            .select('id')
            .eq('user_id', userId);
        
        if ((userPosts as List).isNotEmpty) {
          final postIds = (userPosts as List).map((p) => p['id'] as String).toList();
          
          // Count likes on user's posts
          final likes = await supabase
              .from('post_likes')
              .select('id')
              .inFilter('post_id', postIds)
              .neq('user_id', userId)
              .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
              .limit(10);
          count += (likes as List).length;
        }
      } catch (e) {
        print('Error counting likes: $e');
      }

      // Count unread comments (last 7 days) - comments on current user's posts
      try {
        // First get user's post IDs
        final userPosts = await supabase
            .from('posts')
            .select('id')
            .eq('user_id', userId);
        
        if ((userPosts as List).isNotEmpty) {
          final postIds = (userPosts as List).map((p) => p['id'] as String).toList();
          
          // Count comments on user's posts
          final comments = await supabase
              .from('post_comments')
              .select('id')
              .inFilter('post_id', postIds)
              .neq('user_id', userId)
              .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
              .limit(10);
          count += (comments as List).length;
        }
      } catch (e) {
        print('Error counting comments: $e');
      }

      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      print('❌ [HOME] Error fetching notification count: $e');
    }
  }
  
  Future<void> _fetchUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        print('⚠️ [HOME] No user ID found');
        setState(() => _isLoading = false);
        return;
      }
      
      print('🔵 [HOME] Fetching profile for user: $userId');
      
      // Fetch profile data
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null && mounted) {
        print('✅ [HOME] Profile data received: ${response.keys}');
        print('🔵 [HOME] User ID: ${response['user_id']}');
        print('🔵 [HOME] Display name: ${response['display_name']}');
        print('🔵 [HOME] First name: ${response['first_name']}, Last name: ${response['last_name']}');
        print('🔵 [HOME] Height: ${response['height_cm']}, Weight: ${response['weight_kg']}');
        
        setState(() {
          // Use display_name if available, otherwise combine first_name + last_name, fallback to user_id
          _userName = response['display_name'] ?? 
                     '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim();
          if (_userName.isEmpty) {
            _userName = response['user_id'] ?? 'User';
          }
          _userID = response['user_id'] != null ? '@${response['user_id']}' : null;
          _height = response['height_cm'] != null ? (response['height_cm'] as num).toDouble() : null;
          _weight = response['weight_kg'] != null ? (response['weight_kg'] as num).toDouble() : null;
          _bmi = response['bmi'] != null ? (response['bmi'] as num).toDouble() : null;
          
          // Calculate recommended water intake based on weight (33ml per kg)
          if (_weight != null && _weight! > 0) {
            _waterGoal = DailyStatsService.calculateRecommendedWater(_weight!).toDouble();
          }
          
          // Log BMI data for debugging
          print('🔵 [HOME] BMI: $_bmi, Height: $_height, Weight: $_weight');
          if (_bmi == null && _height != null && _weight != null) {
            print('⚠️ [HOME] BMI is null but height and weight are available. Database trigger may not have run.');
          }
          // Get image URLs from storage paths
          _coverImageUrl = response['cover_path'] != null 
              ? supabase.storage.from('covers').getPublicUrl(response['cover_path'])
              : null;
          _avatarImageUrl = response['avatar_path'] != null
              ? supabase.storage.from('avatars').getPublicUrl(response['avatar_path'])
              : null;
          _isLoading = false;
        });
        
        print('✅ [HOME] Profile data loaded: Name=$_userName, UserID=$_userID, Height=$_height, Weight=$_weight');
      } else {
        print('⚠️ [HOME] No profile data found');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ [HOME] Error fetching profile: $e');
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
    final avatarSize = 50.0; // 44-56dp range

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF6F7FB), // Body background colors
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          // Record login and refresh all data
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
            // Header Stack (cover image with profile and notification inside) - now scrollable
            SliverToBoxAdapter(child: _buildHeaderStack(avatarSize, isDark)),

            // Spacing Fix: BelowHeaderContentStartPadding (blur panel height is 135, so content starts after it)
            const SliverToBoxAdapter(
              child: SizedBox(height: 12), // Small gap after blur panel
            ),

            // Streak Tile Must Not Overlap Header: Place Streak As First Card Below Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStreakCard(isDark),
              ),
            ),

            // Consistent spacing between tiles
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Analytics Tiles Section
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildAnalyticsSection(isDark), 60),
            ),

            // Consistent spacing between tiles
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Quick Actions Grid
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildQuickActionsGrid(isDark), 120),
            ),

            // Consistent spacing between tiles
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // CoCircle Preview
            SliverToBoxAdapter(
              child: _buildAnimatedSection(_buildCoCirclePreview(isDark), 180),
            ),

            // Consistent spacing between tiles
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Nearby Centers Preview
            SliverToBoxAdapter(
              child: _buildAnimatedSection(
                _buildNearbyCentersPreview(isDark),
                240,
              ),
            ),

            // Bottom padding to avoid hiding cards behind bottom nav
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // Header Stack: Cover image with smooth blur blend
  Widget _buildHeaderStack(double avatarSize, bool isDark) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bodyBg = isDarkMode
        ? const Color(0xFF0B1220)
        : const Color(0xFFF6F7FB);
    final coverH = 300.0;
    final blurH = 180.0; // Increased height to start blur higher up

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
                  // Blur effect starts from mid-height and extends to bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: coverH - blurH, // Start blur from mid-height
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

  // Smooth Blur Blend: Blur effect between cover and profile picture area
  Widget _buildSmoothBlurBlend(Color bodyBg) {
    return ClipRect(
      child: Stack(
        children: [
          // Blur effect with gradient mask - starts transparent at top, becomes opaque
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
              filter: ImageFilter.blur(
                sigmaX: 32,
                sigmaY: 32,
              ), // Increased blur
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
          // Background gradient overlay - fades from transparent to body background
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
          // Profile picture and welcome text side by side
          Positioned(
            left: 16,
            right: 16,
            top: 24,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Profile Avatar beside text
                _buildBottomLeftAvatar(),
                const SizedBox(width: 16),
                // Welcome text
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

  // Bottom Left Avatar: Overlapping the blur band
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
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                    child: const Icon(Icons.person, color: Colors.white, size: 36),
                  );
                },
              )
            : Container(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
      ),
    );
  }

  // Notification Button Top Right (44, circle, glass, red dot 8)
  Widget _buildNotificationButtonTopRight() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        );
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

  // Cover Image (Full Width, Fixed Height 280-320, fit cover)
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
            const Color(0xFF14B8A6).withValues(alpha: 0.3),
            const Color(0xFF84CC16).withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }

  // Streak Card (Compact design with continuous streak count)
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
              // Left: Flame Gradient Chip
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
              // Center: Streak count with continuous number
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
              // Right: Mini progress indicator (7 bars showing recent days)
              SizedBox(
                width: 50,
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    // Show last 7 days, with most recent on right
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

  // Analytics Tiles Section - Analytical Style
  Widget _buildAnalyticsSection(bool isDark) {
    // Show BMI tile if BMI is available OR if both height and weight are available
    final shouldShowBMI = _bmi != null || (_height != null && _weight != null);
    
    // Debug logging
    if (shouldShowBMI) {
      print('🔵 [HOME] Showing BMI tile - BMI: $_bmi, Height: $_height, Weight: $_weight');
    } else {
      print('⚠️ [HOME] Not showing BMI tile - BMI: $_bmi, Height: $_height, Weight: $_weight');
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Steps Main Card (full width, large, radius 22)
          _buildStepsBigTile(isDark),
          const SizedBox(height: 12),
          // Row 2: Calories and Water (equal height 120-140, radius 22)
          Row(
            children: [
              Expanded(child: _buildCaloriesSmallTile(isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildWaterSmallTile(isDark)),
            ],
          ),
          // Row 3: BMI Tile (full width, if BMI data is available) - Below calories and water
          if (shouldShowBMI) ...[
            const SizedBox(height: 12),
            _buildBMITile(isDark),
          ],
        ],
      ),
    );
  }

  // Steps Big Tile - Analytical Style
  Widget _buildStepsBigTile(bool isDark) {
    final progress = (_steps / _goalSteps).clamp(0.0, 1.0);
    return _CardPressWrapper(
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
                borderRadius: BorderRadius.circular(22), // Radius 22
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
                  // Left: Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Icon + Title + Chevron
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF14B8A6,
                                ).withValues(alpha: 0.1),
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
                        // Big Value: 8.2k/10000
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
                        const SizedBox(height: 12),
                        // Tiny Sparkline (thin line)
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
                  // Right: Ring Progress (stroke 10)
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
            child: GestureDetector(
              onTapDown: (_) => HapticFeedback.lightImpact(),
              onTapUp: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyInsightsPage(
                      type: 'calories',
                      title: 'Calories',
                      icon: Icons.whatshot,
                      gradientColors: const [
                        Color(0xFFFF6B6B),
                        Color(0xFFFF8FA3),
                      ],
                      currentValue: _calories,
                      goal: 2000,
                      weeklyData: const [
                        1800,
                        1900,
                        1750,
                        2000,
                        1850,
                        1950,
                        1856,
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 130, // Height 120-140
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(22), // Radius 22
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
                    // Thin Sparkline
                    SizedBox(
                      height: 24,
                      child: AnimatedBuilder(
                        animation: _chartController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: SparklinePainter(
                              data: _weeklyCalories.isNotEmpty 
                                  ? _weeklyCalories
                                  : const [
                                      1800,
                                      1900,
                                      1750,
                                      2000,
                                      1850,
                                      1950,
                                      1856,
                                    ],
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
            ),
          );
        },
      ),
    );
  }

  // Water Small Tile
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
              weeklyData: [2000, 2200, 1800, 2400, 2100, 2300, _water.round()],
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
            child: GestureDetector(
              onTapDown: (_) => HapticFeedback.lightImpact(),
              onTapUp: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyInsightsPage(
                      type: 'water',
                      title: 'Water',
                      icon: Icons.water_drop,
                      gradientColors: const [
                        Color(0xFF3B82F6),
                        Color(0xFF06B6D4),
                      ],
                      currentValue: _water.round(),
                      goal: _waterGoal.round(),
                      weeklyData: _weeklyWater,
                    ),
                  ),
                );
              },
              child: Container(
                height: 130, // Height 120-140
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(22), // Radius 22
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
                        // 250ml preset button
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
                    // Thin Sparkline
                    SizedBox(
                      height: 22,
                      child: AnimatedBuilder(
                        animation: _chartController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: SparklinePainter(
                              data: _weeklyWater.isNotEmpty 
                                  ? _weeklyWater
                                  : [
                                      2000,
                                      2200,
                                      1800,
                                      2400,
                                      2100,
                                      2300,
                                      _water.round(),
                                    ],
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
            ),
          );
        },
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
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
            Slider(
              value: _water,
              min: 0,
              max: _waterGoal,
              divisions: 50,
              onChanged: (value) async {
                setState(() {
                  _water = value;
                });
                // Update in database
                try {
                  await DailyStatsService.updateTodayStats(waterMl: value.round());
                } catch (e) {
                  print('Error updating water: $e');
                }
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
      onTap: () async {
        HapticFeedback.mediumImpact();
        try {
          await DailyStatsService.addWater(ml);
          await _fetchDailyStats(); // Refresh data
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

  // BMI Wide Tile
  Widget _buildBMITile(bool isDark) {
    // Calculate BMI if not available from database but height and weight are
    double? bmi = _bmi;
    if (bmi == null && _height != null && _weight != null && _height! > 0) {
      // Calculate BMI: weight (kg) / (height (m))^2
      final heightM = _height! / 100.0;
      bmi = _weight! / (heightM * heightM);
    }
    
    // Return empty container if BMI still cannot be calculated
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

    final bmiPosition = ((bmi - 15) / 20).clamp(
      0.0,
      1.0,
    ); // Scale 15-35 to 0-1

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

  // Quick Actions - Sliding Horizontal Style
  Widget _buildQuickActionsGrid(bool isDark) {
    final actions = [
      {
        'icon': Icons.restaurant_menu_rounded,
        'label': 'Meal Tracker',
        'color': const Color(0xFF10B981),
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
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'AI Planner',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.school_rounded,
        'label': 'Become a Trainer',
        'color': const Color(0xFFEC4899),
      },
      {
        'icon': Icons.local_dining_rounded,
        'label': 'Become a Nutritionist',
        'color': const Color(0xFF10B981),
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
          // Horizontal sliding list (3.2 visible)
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
        _navigateToQuickAction(label);
      },
      child: Container(
        width: 140, // Tile size 140x96
        height: 96,
        padding: const EdgeInsets.all(12), // Inner padding 12
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2937)
              : Colors.white, // Surface variant
          borderRadius: BorderRadius.circular(22), // Radius 22
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            // Subtle accent glow
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Icon Top Left
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
            // Gradient Dot Top Right
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
            // Title Bottom Left
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

  void _navigateToQuickAction(String label) {
    switch (label) {
      case 'Meal Tracker':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MealTrackerPageV2()),
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
          MaterialPageRoute(
            builder: (context) => const ConversationsListPage(),
          ),
        );
        break;
      case 'AI Planner':
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AiPlannerPage(),
          ),
        );
        break;
      case 'Become a Trainer':
        HapticFeedback.mediumImpact();
        // TODO: Implement become trainer page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Become a trainer feature coming soon')),
        );
        break;
      case 'Become a Nutritionist':
        HapticFeedback.mediumImpact();
        // TODO: Implement become nutritionist page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Become a nutritionist feature coming soon')),
        );
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
                      // Image Top, Rounded
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
                      // Bottom Info Row: Avatar + @user + Likes
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Avatar
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
                            // @user
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
                            // Likes
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

  // Nearby Centers Preview
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
          // Category Chips
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
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1F2937),
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
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${1.2 + index * 0.5} km',
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
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
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

// Card Press Wrapper for scale animation
class _CardPressWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _CardPressWrapper({required this.child, required this.onTap});

  @override
  State<_CardPressWrapper> createState() => _CardPressWrapperState();
}

class _CardPressWrapperState extends State<_CardPressWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
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
        ..color = isToday
            ? const Color(0xFF14B8A6)
            : const Color(0xFF14B8A6).withOpacity(0.6)
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

// Sparkline Painter (thin line graph)
class SparklinePainter extends CustomPainter {
  final List<int> data;
  final double animationValue;
  final bool isDark;
  final Color color;

  SparklinePainter({
    required this.data,
    required this.animationValue,
    required this.isDark,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = data.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxValue - minValue;
    final stepX = size.width / (data.length - 1);

    final paint = Paint()
      ..color = color
      ..strokeWidth =
          1.5 // Thin line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final visibleCount = (data.length * animationValue).ceil();

    for (int i = 0; i < visibleCount && i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y =
          size.height -
          (normalizedValue * size.height * 0.8) -
          (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots on points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < visibleCount && i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y =
          size.height -
          (normalizedValue * size.height * 0.8) -
          (size.height * 0.1);

      canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

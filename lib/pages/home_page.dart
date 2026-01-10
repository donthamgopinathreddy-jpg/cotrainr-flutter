import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sensor_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/header_cover.dart';
import '../widgets/analytics_tiles/streak_wide_tile.dart';
import '../widgets/home_tiles/steps_tile_new.dart';
import '../widgets/home_tiles/calories_tile_new.dart';
import '../widgets/home_tiles/water_tile_new.dart';
import 'weekly_insights_page.dart' show WeeklyInsightsPage, MetricType;
import 'quests_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final SensorService _sensorService = SensorService();
  final UserProfileService _profileService = UserProfileService();
  late AnimationController _animationController;

  int _steps = 0;
  int _water = 0;
  int _calories = 0;
  int _burned = 0;
  int _intake = 0;
  int _dailyStreak = 0;
  String? _userName;
  String? _avatarUrl;
  String? _coverImageUrl;

  // Weekly data for mini graphs (as doubles for fl_chart)
  List<double> _weeklySteps = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyWater = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyCalories = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile = await _profileService.getCurrentUserProfile();
    final stepsFromSensor = _sensorService.stepCount;

    setState(() {
      _userName = profile?['first_name'] as String? ?? 'Diana Soe';
      _avatarUrl = profile?['profile_photo_url'] as String?;
      _coverImageUrl = profile?['cover_photo_url'] as String?;
      _steps = stepsFromSensor > 0 ? stepsFromSensor : 8200; // Demo: 8.2k
      _water = 1500; // Demo: 1.5L
      _calories = 1856; // Demo value
      _burned = 1200;
      _intake = 1800;
      _dailyStreak = 7; // Demo: 7 Day Streak

      // Generate weekly data (convert to doubles and add realistic variation)
      _weeklySteps = [
        (_steps * 0.8).roundToDouble(),
        (_steps * 0.9).roundToDouble(),
        (_steps * 0.7).roundToDouble(),
        (_steps * 1.1).roundToDouble(),
        (_steps * 1.0).roundToDouble(),
        (_steps * 1.2).roundToDouble(),
        _steps.toDouble(),
      ];
      // Water data in liters for the chart
      final waterLiters = _water / 1000.0;
      _weeklyWater = [
        (waterLiters * 1.2),
        (waterLiters * 1.3),
        (waterLiters * 1.1),
        (waterLiters * 1.4),
        (waterLiters * 1.3),
        (waterLiters * 1.4),
        waterLiters,
      ];
      _weeklyCalories = [
        (_calories * 0.95).roundToDouble(),
        (_calories * 1.05).roundToDouble(),
        (_calories * 0.9).roundToDouble(),
        (_calories * 1.1).roundToDouble(),
        (_calories * 1.0).roundToDouble(),
        (_calories * 1.15).roundToDouble(),
        _calories.toDouble(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0F14)
          : const Color(0xFFF6F7FB),
      body: CustomScrollView(
        slivers: [
          // Header Cover with Blur
          HeaderCover(
            userName: _userName ?? 'User',
            avatarUrl: _avatarUrl,
            coverImageUrl: _coverImageUrl,
            hasNotifications: true,
            onNotificationTap: () {
              // Navigate to notifications
            },
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Streak Wide Card (First card, no overlap with header)
                  StreakWideTile(
                    streakDays: _dailyStreak,
                    weeklyProgress: 0.7,
                    last7Days: List.generate(
                      7,
                      (i) => i >= 3,
                    ), // Last 4 days active
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuestsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Steps (Full Width)
                  StepsTileNew(
                    steps: _steps,
                    goal: 10000,
                    weekData: _weeklySteps,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeeklyInsightsPage(
                            metricType: MetricType.steps,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Row 3: Calories + Water (Side by Side)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CaloriesTileNew(
                          calories: _calories,
                          target: 2200,
                          burned: _burned,
                          intake: _intake,
                          weekData: _weeklyCalories,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WeeklyInsightsPage(
                                  metricType: MetricType.calories,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: WaterTileNew(
                          waterLiters: _water / 1000.0,
                          goalLiters: 2.5,
                          weekData: _weeklyWater,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WeeklyInsightsPage(
                                  metricType: MetricType.water,
                                ),
                              ),
                            );
                          },
                          onQuickAdd: (liters) {
                            setState(() {
                              _water += (liters * 1000).toInt();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'subscription_page.dart';
import '../services/subscription_service.dart';
import '../services/ai_planner_service.dart';

class AiPlannerPage extends StatefulWidget {
  const AiPlannerPage({super.key});

  @override
  State<AiPlannerPage> createState() => _AiPlannerPageState();
}

class _AiPlannerPageState extends State<AiPlannerPage>
    with SingleTickerProviderStateMixin {
  // Services
  final _aiPlannerService = AiPlannerService();
  
  // User plan (loaded from SubscriptionService)
  String _userPlan = 'FREE'; // FREE, BASIC, PREMIUM

  // Tab selection
  int _selectedTab = 0; // 0: Meal Planner, 1: Workout Planner

  // Form inputs
  String? _selectedGoal;
  double _daysPerWeek = 4.0;
  double _timePerSession = 45.0;
  List<String> _dietPreferences = [];
  List<String> _allergens = [];
  int _mealsPerDay = 3;
  List<String> _equipment = [];

  // Goal options with icons
  final List<Map<String, dynamic>> _goalOptions = [
    {
      'label': 'Fat Loss',
      'icon': Icons.trending_down_rounded,
      'value': 'fat_loss',
    },
    {
      'label': 'Muscle Gain',
      'icon': Icons.trending_up_rounded,
      'value': 'muscle_gain',
    },
    {
      'label': 'Endurance',
      'icon': Icons.directions_run_rounded,
      'value': 'endurance',
    },
    {
      'label': 'Boxing Performance',
      'icon': Icons.sports_mma_rounded,
      'value': 'boxing',
    },
    {
      'label': 'General Fitness',
      'icon': Icons.fitness_center_rounded,
      'value': 'general',
    },
  ];

  // Diet preferences
  final List<String> _dietOptions = ['Veg', 'Non-Veg', 'Eggetarian'];

  // Allergen options
  final List<String> _allergenOptions = [
    'Peanuts',
    'Dairy',
    'Gluten',
    'Eggs',
    'Soy',
    'Fish',
    'Shellfish',
    'Nuts',
  ];

  // Equipment options
  final List<String> _equipmentOptions = ['Gym', 'Home', 'Bodyweight'];

  // State
  bool _isGenerating = false;
  bool _hasResult = false;
  Map<String, dynamic>? _generatedPlan;
  late AnimationController _resultAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Expanded days for accordion
  Set<int> _expandedDays = {};

  // Shimmer animation
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _resultAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultAnimationController,
      curve: Curves.easeOut,
    ));
    _loadUserPlan();
  }

  Future<void> _loadUserPlan() async {
    try {
      final plan = await SubscriptionService.getUserPlan();
      if (mounted) {
        setState(() {
          _userPlan = plan;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userPlan = 'FREE';
        });
      }
    }
  }

  @override
  void dispose() {
    _resultAnimationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // Check if workout planner is locked
  bool get _isWorkoutPlannerLocked {
    return _selectedTab == 1 && _userPlan == 'BASIC';
  }

  // Check if can generate
  bool get _canGenerate {
    if (_selectedTab == 0) {
      // Meal planner: need goal and diet preference
      return _selectedGoal != null && _dietPreferences.isNotEmpty;
    } else {
      // Workout planner: need goal and equipment
      return _selectedGoal != null &&
          _equipment.isNotEmpty &&
          !_isWorkoutPlannerLocked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Navigate to history page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History coming soon')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Planner',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'generate a plan based on your profile, goals, and schedule',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disclaimer
                  _buildDisclaimer(colorScheme, isDark),
                  const SizedBox(height: 24),

                  // Segmented Selector
                  _buildSegmentedSelector(colorScheme, isDark),
                  const SizedBox(height: 24),

                  // Locked State (if Basic user on Workout Planner)
                  if (_isWorkoutPlannerLocked) ...[
                    _buildLockedState(colorScheme, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Inputs Card
                  if (!_isWorkoutPlannerLocked) ...[
                    _buildInputsCard(colorScheme, isDark),
                    const SizedBox(height: 24),

                    // Generate Button
                    _buildGenerateButton(colorScheme, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Result View
                  if (_hasResult) _buildResultView(colorScheme, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI-generated plans are suggestions only and not medical advice. Consult a healthcare professional before starting any new diet or exercise program.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSelector(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Meal Planner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedTab == 0
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Workout Planner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 1
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (_userPlan == 'BASIC' && _selectedTab == 1) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_rounded,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Workout Planner Locked',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Premium to unlock AI Workout Planner',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputsCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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
          // Goal Selector
          Text(
            'Goal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _goalOptions.map((goal) {
              final isSelected = _selectedGoal == goal['value'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedGoal = goal['value']);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        goal['icon'],
                        size: 18,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        goal['label'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Days per Week Slider
          Text(
            'Days per Week: ${_daysPerWeek.toInt()}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _daysPerWeek,
            min: 3,
            max: 6,
            divisions: 3,
            label: _daysPerWeek.toInt().toString(),
            activeColor: colorScheme.primary,
            onChanged: (value) {
              setState(() => _daysPerWeek = value);
            },
          ),
          const SizedBox(height: 24),

          // Time per Session Slider
          Text(
            'Time per Session: ${_timePerSession.toInt()} min',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _timePerSession,
            min: 20,
            max: 90,
            divisions: 14,
            label: '${_timePerSession.toInt()} min',
            activeColor: colorScheme.primary,
            onChanged: (value) {
              setState(() => _timePerSession = value);
            },
          ),
          const SizedBox(height: 24),

          // Meal Planner specific inputs
          if (_selectedTab == 0) ...[
            // Diet Preference
            Text(
              'Diet Preference',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dietOptions.map((diet) {
                final isSelected = _dietPreferences.contains(diet);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _dietPreferences.remove(diet);
                      } else {
                        _dietPreferences = [diet]; // Single selection
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      diet,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Allergens (Optional)
            Text(
              'Allergens (Optional)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allergenOptions.map((allergen) {
                final isSelected = _allergens.contains(allergen);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _allergens.remove(allergen);
                      } else {
                        _allergens.add(allergen);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      allergen,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Meals per Day
            Text(
              'Meals per Day: $_mealsPerDay',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                final meals = index + 2; // 2 to 6 meals
                final isSelected = _mealsPerDay == meals;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _mealsPerDay = meals);
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < 4 ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meals.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],

          // Workout Planner specific inputs
          if (_selectedTab == 1) ...[
            // Equipment Selector
            Text(
              'Equipment',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipmentOptions.map((equip) {
                final isSelected = _equipment.contains(equip);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _equipment.remove(equip);
                      } else {
                        _equipment.add(equip);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      equip,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton(ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTapDown: (_) {
        if (_canGenerate && !_isGenerating) {
          _shimmerController.forward();
        }
      },
      onTapUp: (_) {
        _shimmerController.reset();
        if (_canGenerate && !_isGenerating) {
          _generatePlan();
        }
      },
      onTapCancel: () {
        _shimmerController.reset();
      },
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _canGenerate && !_isGenerating
                  ? LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : LinearGradient(
                      colors: [
                        colorScheme.onSurface.withValues(alpha: 0.1),
                        colorScheme.onSurface.withValues(alpha: 0.1),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _canGenerate && !_isGenerating
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Shimmer overlay
                if (_canGenerate &&
                    !_isGenerating &&
                    _shimmerController.isAnimating)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(_shimmerAnimation.value - 1, 0),
                            end: Alignment(_shimmerAnimation.value, 0),
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.overlay,
                        child: Container(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Content
                Center(
                  child: _isGenerating
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Generate Plan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _canGenerate
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generatePlan() async {
    HapticFeedback.lightImpact();
    
    // Check subscription access
    if (_selectedTab == 0) {
      // Meal Planner: Check if user has BASIC or PREMIUM
      if (_userPlan == 'FREE') {
        _showUpgradeDialog(context);
        return;
      }
    } else {
      // Workout Planner: Check if user has PREMIUM
      if (_userPlan != 'PREMIUM') {
        _showUpgradeDialog(context);
        return;
      }
    }

    setState(() {
      _isGenerating = true;
      _hasResult = false;
    });

    try {
      Map<String, dynamic> planData;

      if (_selectedTab == 0) {
        // Generate Meal Plan via Supabase Edge Function
        planData = await _aiPlannerService.generateMealPlan(
          goal: _selectedGoal!,
          daysPerWeek: _daysPerWeek.toInt(),
          timePerSession: _timePerSession.toInt(),
          dietPreference: _dietPreferences.first,
          allergens: _allergens,
          mealsPerDay: _mealsPerDay,
        );
      } else {
        // Generate Workout Plan via Supabase Edge Function
        planData = await _aiPlannerService.generateWorkoutPlan(
          goal: _selectedGoal!,
          daysPerWeek: _daysPerWeek.toInt(),
          timePerSession: _timePerSession.toInt(),
          equipment: _equipment,
        );
      }

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasResult = true;
          _generatedPlan = planData;
        });

        // Animate result reveal
        _resultAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        // Show error message
        String errorMessage = 'Failed to generate plan';
        if (e.toString().contains('rate limit')) {
          errorMessage = 'Rate limit reached. Please try again later.';
        } else if (e.toString().contains('subscription')) {
          errorMessage = 'Please upgrade your plan to use this feature.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: Text(
          _selectedTab == 0
              ? 'AI Meal Planner is available for Basic and Premium plans.'
              : 'AI Workout Planner is available for Premium plans only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(ColorScheme colorScheme, bool isDark) {
    if (_generatedPlan == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Summary Tiles
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    'Today\'s Focus',
                    _generatedPlan!['todayFocus'],
                    Icons.today_rounded,
                    colorScheme,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    'Calories',
                    '${_generatedPlan!['calories']}',
                    Icons.local_fire_department_rounded,
                    colorScheme,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    'Protein',
                    '${_generatedPlan!['protein']}g',
                    Icons.egg_rounded,
                    colorScheme,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    'Carbs',
                    '${_generatedPlan!['carbs']}g',
                    Icons.bakery_dining_rounded,
                    colorScheme,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryTile(
                    'Fats',
                    '${_generatedPlan!['fats']}g',
                    Icons.water_drop_rounded,
                    colorScheme,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly Schedule
            Text(
              'Weekly Schedule',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...(_generatedPlan!['weeklySchedule'] as List).asMap().entries.map(
              (entry) {
                final index = entry.key;
                final day = entry.value;
                return _buildDayTile(
                  day['day'],
                  day['focus'],
                  day['details'],
                  index,
                  colorScheme,
                  isDark,
                );
              },
            ),
            const SizedBox(height: 24),

            // Share to Trainer Button
            ElevatedButton.icon(
              onPressed: () => _showShareToTrainerSheet(colorScheme, isDark),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share to Trainer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTile(
    String day,
    String focus,
    String details,
    int index,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isExpanded = _expandedDays.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isExpanded) {
                  _expandedDays.remove(index);
                } else {
                  _expandedDays.add(index);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          focus,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to view details',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                details,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showShareToTrainerSheet(ColorScheme colorScheme, bool isDark) {
    // Mock trainer list (TODO: Get from Supabase)
    final trainers = [
      {'id': '1', 'name': 'John Trainer', 'specialization': 'Strength'},
      {'id': '2', 'name': 'Sarah Coach', 'specialization': 'Cardio'},
      {'id': '3', 'name': 'Mike Fitness', 'specialization': 'Boxing'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Select Trainer',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Trainer List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trainers.length,
                itemBuilder: (context, index) {
                  final trainer = trainers[index];
                  return GestureDetector(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      
                      // Share plan with trainer via service
                      if (_generatedPlan != null && _generatedPlan!['id'] != null) {
                        try {
                          await _aiPlannerService.sharePlanWithTrainer(
                            planId: _generatedPlan!['id'] as String,
                            trainerId: trainer['id'] as String,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Plan shared with ${trainer['name']}',
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to share plan: ${e.toString()}'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      } else {
                        // Fallback if plan ID not available
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Plan ID not available'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trainer['name'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trainer['specialization'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


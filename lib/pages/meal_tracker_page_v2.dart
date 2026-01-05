import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/meal_tracker_service.dart';
import 'meal_details_page.dart';
import 'add_food_bottom_sheet.dart';
import 'meal_weekly_insights_page.dart';

/// Modern Analytics-Style Meal Tracker Page
class MealTrackerPageV2 extends StatefulWidget {
  const MealTrackerPageV2({super.key});

  @override
  State<MealTrackerPageV2> createState() => _MealTrackerPageV2State();
}

class _MealTrackerPageV2State extends State<MealTrackerPageV2> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _ringController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Date
  DateTime _selectedDate = DateTime.now();

  // Daily Goals & Totals
  int _calorieTarget = 2000;
  double _proteinTarget = 120;
  double _carbsTarget = 250;
  double _fatTarget = 65;

  int _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  int _totalWater = 0;
  int _streakDays = 0;

  // Meal Data
  List<MealData> _meals = [
    MealData(mealType: 'breakfast', name: 'Breakfast', items: []),
    MealData(mealType: 'lunch', name: 'Lunch', items: []),
    MealData(mealType: 'snacks', name: 'Snacks', items: []),
    MealData(mealType: 'dinner', name: 'Dinner', items: []),
  ];

  bool _isLoading = true;
  bool _shareWithTrainer = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _fadeController.forward();
    _slideController.forward();
    _loadMealData();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadMealData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load meal day data
      final mealDay = await MealTrackerService.getMealDay(_selectedDate);
      if (mealDay != null) {
        setState(() {
          _calorieTarget = mealDay['calorie_target'] as int? ?? 2000;
          _proteinTarget = (mealDay['protein_target'] as num?)?.toDouble() ?? 120;
          _carbsTarget = (mealDay['carbs_target'] as num?)?.toDouble() ?? 250;
          _fatTarget = (mealDay['fat_target'] as num?)?.toDouble() ?? 65;
          _totalCalories = mealDay['total_kcal'] as int? ?? 0;
          _totalProtein = (mealDay['total_protein'] as num?)?.toDouble() ?? 0;
          _totalCarbs = (mealDay['total_carbs'] as num?)?.toDouble() ?? 0;
          _totalFat = (mealDay['total_fat'] as num?)?.toDouble() ?? 0;
          _totalWater = mealDay['total_water_ml'] as int? ?? 0;
        });
      }

      // Reset to standard meals first
      final standardMealTypes = {'breakfast', 'lunch', 'snacks', 'dinner'};
      _meals = [
        MealData(mealType: 'breakfast', name: 'Breakfast', items: []),
        MealData(mealType: 'lunch', name: 'Lunch', items: []),
        MealData(mealType: 'snacks', name: 'Snacks', items: []),
        MealData(mealType: 'dinner', name: 'Dinner', items: []),
      ];

      // Load all items for the date (single query)
      final allItems = await MealTrackerService.getMealItems(
        date: _selectedDate,
        mealType: null, // Get all items
      );
      
      // Load standard meal items
      for (var meal in _meals) {
        meal.items = allItems.where((item) => (item['meal_type'] as String?) == meal.mealType).toList();
      }

      // Find and add custom meals (meal types that don't match standard ones)
      final customMealTypes = <String>{};
      
      for (var item in allItems) {
        final mealType = item['meal_type'] as String? ?? '';
        if (!standardMealTypes.contains(mealType) && mealType.isNotEmpty) {
          customMealTypes.add(mealType);
        }
      }
      
      // Add custom meals to the list
      for (var customType in customMealTypes) {
        // Extract meal name from custom type (format: "custom_meal_name" or just "meal_name")
        final mealName = customType.startsWith('custom_') 
            ? customType.substring(7).split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')
            : customType.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
        
        _meals.add(MealData(
          mealType: customType,
          name: mealName,
          items: allItems.where((item) => (item['meal_type'] as String?) == customType).toList(),
        ));
      }

      // Start ring animation
      _ringController.forward(from: 0);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading meal data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _previousDay() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadMealData();
  }

  void _nextDay() {
    HapticFeedback.lightImpact();
    final today = DateTime.now();
    if (_selectedDate.isBefore(today)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _loadMealData();
    }
  }

  void _selectToday() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadMealData();
  }

  Future<void> _showDatePicker() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7A00),
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _loadMealData();
    }
  }

  bool get _isToday {
    final today = DateTime.now();
    return _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
  }

  String get _dateDisplay {
    if (_isToday) {
      return 'Today';
    }
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(_selectedDate);
  }

  double get _calorieProgress => _calorieTarget > 0 ? (_totalCalories / _calorieTarget).clamp(0.0, 1.0) : 0.0;
  double get _proteinProgress => _proteinTarget > 0 ? (_totalProtein / _proteinTarget).clamp(0.0, 1.0) : 0.0;
  double get _carbsProgress => _carbsTarget > 0 ? (_totalCarbs / _carbsTarget).clamp(0.0, 1.0) : 0.0;
  double get _fatProgress => _fatTarget > 0 ? (_totalFat / _fatTarget).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_slideController),
                  child: RefreshIndicator(
                    onRefresh: _loadMealData,
                    child: CustomScrollView(
                      slivers: [
                        // Top App Bar
                        _buildTopAppBar(isDark),
                        
                        // Summary Row
                        _buildSummaryRow(isDark),
                        
                        // Section A: Macro Ring + Trend
                        SliverToBoxAdapter(child: _buildMacroRingSection(isDark)),
                        
                        // Section B: Meal Tiles
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Text(
                              'Meals',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        _buildMealTiles(isDark),
                        
                        // Section C: Daily Insights Cards
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Text(
                              'Insights',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        _buildInsightsCards(isDark),
                        
                        // Section D: Trainer Sharing (if connected)
                        _buildTrainerSharing(isDark),
                        
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: _buildFloatingActionButton(isDark),
    );
  }

  Widget _buildTopAppBar(bool isDark) {
    return SliverAppBar(
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Meal Tracker',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              // Date Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: _previousDay,
                  ),
                  GestureDetector(
                    onTap: _isToday ? null : _selectToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isToday
                            ? const Color(0xFFFF7A00)
                            : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _dateDisplay,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _isToday
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF1F2937)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _isToday
                          ? (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                    onPressed: _isToday ? null : _nextDay,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: _showDatePicker,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('${_totalCalories}', 'kcal', isDark),
            _buildSummaryItem('${_totalProtein.toInt()}g', 'Protein', isDark),
            _buildSummaryItem('${_totalCarbs.toInt()}g', 'Carbs', isDark),
            _buildSummaryItem('${_totalFat.toInt()}g', 'Fat', isDark),
            _buildSummaryItem('${_totalWater}ml', 'Water', isDark),
            if (_streakDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '$_streakDays',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRingSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Macro Ring Chart
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _calorieProgress * _ringController.value,
                        strokeWidth: 16,
                        backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF7A00)),
                        strokeCap: StrokeCap.round,
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_totalCalories',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '/ $_calorieTarget kcal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MealWeeklyInsightsPage(date: _selectedDate),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 14,
                              color: const Color(0xFFFF7A00),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'View Insights',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF7A00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Mini Progress Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniProgressPill('Protein', _totalProtein.toInt(), _proteinTarget.toInt(), _proteinProgress, const Color(0xFF3B82F6), isDark),
              _buildMiniProgressPill('Carbs', _totalCarbs.toInt(), _carbsTarget.toInt(), _carbsProgress, const Color(0xFF10B981), isDark),
              _buildMiniProgressPill('Fat', _totalFat.toInt(), _fatTarget.toInt(), _fatProgress, const Color(0xFFF59E0B), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProgressPill(String label, int current, int target, double progress, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current/$target',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMealTiles(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Show "Add Meal" tile at the end
            if (index == _meals.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAddMealTile(isDark),
              );
            }
            final meal = _meals[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMealTile(meal, isDark),
            );
          },
          childCount: _meals.length + 1, // Include "Add Meal" tile
        ),
      ),
    );
  }

  Widget _buildMealTile(MealData meal, bool isDark) {
    final totalKcal = meal.items.fold<double>(0, (sum, item) {
      final kcal = item['kcal'] as num?;
      return sum + (kcal?.toDouble() ?? 0.0);
    });
    final hasItems = meal.items.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MealDetailsPage(
              date: _selectedDate,
              mealType: meal.mealType,
              mealName: meal.name,
            ),
          ),
        ).then((_) => _loadMealData());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Meal Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getMealColor(meal.mealType).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMealIcon(meal.mealType),
                color: _getMealColor(meal.mealType),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Meal Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        meal.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      if (hasItems) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (hasItems)
                    Row(
                      children: [
                        Text(
                          '${totalKcal.toInt()} kcal',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getMacrosText(meal.items),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No items logged',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      ),
                    ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  String _getMacrosText(List<Map<String, dynamic>> items) {
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (var item in items) {
      protein += (item['protein'] as num?)?.toDouble() ?? 0;
      carbs += (item['carbs'] as num?)?.toDouble() ?? 0;
      fat += (item['fat'] as num?)?.toDouble() ?? 0;
    }

    return '${protein.toInt()}P ${carbs.toInt()}C ${fat.toInt()}F';
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const Color(0xFFFFB020);
      case 'lunch':
        return const Color(0xFF10B981);
      case 'snacks':
        return const Color(0xFF8B5CF6);
      case 'dinner':
        return const Color(0xFF3B82F6);
      default:
        // Custom meals get a unique color based on hash
        return _getColorForCustomMeal(mealType);
    }
  }

  Color _getColorForCustomMeal(String mealType) {
    // Generate a consistent color based on meal type
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFF38181),
      const Color(0xFFAA96DA),
    ];
    final index = mealType.hashCode % colors.length;
    return colors[index.abs()];
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.restaurant_rounded;
      case 'snacks':
        return Icons.cookie_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  Widget _buildInsightsCards(bool isDark) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildInsightCard(
              'Top Protein',
              _getTopProteinSource(),
              Icons.fitness_center_rounded,
              const Color(0xFF3B82F6),
              isDark,
            ),
            const SizedBox(width: 12),
            _buildInsightCard(
              'Most Calories',
              _getMostCalorieDenseMeal(),
              Icons.local_fire_department_rounded,
              const Color(0xFFFF7A00),
              isDark,
            ),
            const SizedBox(width: 12),
            _buildInsightCard(
              'Fiber',
              '${_getFiberTotal().toInt()}g',
              Icons.eco_rounded,
              const Color(0xFF10B981),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getTopProteinSource() {
    String topFood = 'None';
    double maxProtein = 0;

    for (var meal in _meals) {
      for (var item in meal.items) {
        final food = item['foods_catalog'] as Map<String, dynamic>?;
        final protein = (item['protein'] as num?)?.toDouble() ?? 0;
        if (protein > maxProtein) {
          maxProtein = protein;
          topFood = food?['name'] as String? ?? 'Unknown';
        }
      }
    }

    return topFood;
  }

  String _getMostCalorieDenseMeal() {
    String topMeal = 'None';
    double maxCalories = 0;

    for (var meal in _meals) {
      final total = meal.items.fold<double>(0, (sum, item) {
        final kcal = item['kcal'] as num?;
        return sum + (kcal?.toDouble() ?? 0.0);
      });
      if (total > maxCalories) {
        maxCalories = total;
        topMeal = meal.name;
      }
    }

    return topMeal;
  }

  double _getFiberTotal() {
    double total = 0;
    for (var meal in _meals) {
      for (var item in meal.items) {
        total += (item['fiber'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  Widget _buildTrainerSharing(bool isDark) {
    // TODO: Check if user has trainer connection
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.share_rounded,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share with Trainer',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your trainer can view your meals',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _shareWithTrainer,
              onChanged: (value) {
                HapticFeedback.mediumImpact();
                setState(() => _shareWithTrainer = value);
                // TODO: Save to database
              },
              activeColor: const Color(0xFFFF7A00),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        _showAddFoodDialog();
      },
      backgroundColor: const Color(0xFFFF7A00),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Log Food',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showAddFoodDialog() {
    // Show meal selection first
    _showMealSelectionDialog();
  }

  void _showMealSelectionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Meal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _meals.length + 1, // +1 for "Add Custom Meal"
              itemBuilder: (context, index) {
                if (index == _meals.length) {
                  // Add Custom Meal option
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFFFF7A00),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Add Custom Meal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddCustomMealDialog();
                    },
                  );
                }
                
                final meal = _meals[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getMealColor(meal.mealType).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getMealIcon(meal.mealType),
                      color: _getMealColor(meal.mealType),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    meal.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddFoodForMeal(meal.mealType);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddCustomMealDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Text(
          'Add Custom Meal',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Meal name (e.g., Pre-Workout)',
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final mealName = textController.text.trim();
              if (mealName.isNotEmpty) {
                Navigator.pop(context);
                // Create custom meal type (sanitize name)
                final mealType = 'custom_${mealName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';
                // Show add food dialog for this meal (it will be added to the list when food is added)
                _showAddFoodForMeal(mealType);
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(
                color: Color(0xFFFF7A00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodForMeal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodBottomSheet(
        date: _selectedDate,
        mealType: mealType,
        onFoodAdded: () {
          _loadMealData();
        },
      ),
    );
  }

  Widget _buildAddMealTile(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAddCustomMealDialog();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFFFF7A00),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Add Meal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class MealData {
  final String mealType;
  final String name;
  List<Map<String, dynamic>> items;

  MealData({
    required this.mealType,
    required this.name,
    required this.items,
  });
}


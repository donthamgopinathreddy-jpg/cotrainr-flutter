import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/meal_tracker_service.dart';
import '../models/food_model.dart';
import 'quantity_nutrition_modal.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final DateTime date;
  final String? mealType;
  final VoidCallback onFoodAdded;

  const AddFoodBottomSheet({
    super.key,
    required this.date,
    this.mealType,
    required this.onFoodAdded,
  });

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allFoods = [];
  List<Map<String, dynamic>> _recentFoods = [];
  List<Map<String, dynamic>> _favoriteFoods = [];
  List<Map<String, dynamic>> _filteredFoods = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Snacks',
    'Veg',
    'Non veg',
    'South Indian',
    'Street food',
    'Fruits',
    'Dairy',
    'Drinks',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFoods();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    try {
      _allFoods = await MealTrackerService.getFoodsByTags([]);
      _recentFoods = await MealTrackerService.getRecentFoods();
      _favoriteFoods = await MealTrackerService.getFavoriteFoods();
      _filteredFoods = _allFoods;
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading foods: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filterFoods();
    } else {
      setState(() {
        _filteredFoods = _allFoods.where((food) {
          final name = (food['name'] as String? ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      });
    }
  }

  void _filterFoods() {
    if (_selectedCategory == 'All') {
      setState(() {
        _filteredFoods = _allFoods;
      });
    } else {
      setState(() {
        _filteredFoods = _allFoods.where((food) {
          final tags = List<String>.from(food['tags'] as List? ?? []);
          return tags.any((tag) => tag.toLowerCase() == _selectedCategory.toLowerCase());
        }).toList();
      });
    }
  }

  void _selectCategory(String category) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategory = category;
    });
    _filterFoods();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Add Food',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(category),
                    selectedColor: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFFFF7A00),
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFFFF7A00)
                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFFF7A00),
            unselectedLabelColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            indicatorColor: const Color(0xFFFF7A00),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Recent'),
              Tab(text: 'Favorites'),
            ],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFoodList(_filteredFoods, isDark),
                _buildFoodList(_recentFoods, isDark),
                _buildFoodList(_favoriteFoods, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<Map<String, dynamic>> foods, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 48,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              'No foods found',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the database has food items',
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

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _buildFoodItem(food, isDark);
      },
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food, bool isDark) {
    final foodModel = FoodModel.fromMap(food);
    final name = foodModel.name;
    final kcal = foodModel.kcalPer100g.toInt();
    final protein = foodModel.proteinPer100g.toInt();
    final carbs = foodModel.carbsPer100g.toInt();
    final fat = foodModel.fatPer100g.toInt();

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Don't pop immediately - let the quantity modal handle it
        _showQuantityModal(foodModel);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$kcal kcal • ${protein}P ${carbs}C ${fat}F per 100g',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
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

  void _showQuantityModal(FoodModel food) {
    // Ensure mealType is set
    final mealType = widget.mealType ?? 'breakfast';
    
    // Show quantity modal on top of the bottom sheet
    // It will close both modals when food is added
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuantityNutritionModal(
        food: food,
        date: widget.date,
        mealType: mealType,
        onFoodAdded: () {
          // Close both modals
          Navigator.pop(context); // Close quantity modal
          Navigator.pop(context); // Close food selection bottom sheet
          widget.onFoodAdded();
        },
      ),
    );
  }
}


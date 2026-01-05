import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/meal_tracker_service.dart';
import '../models/meal_model.dart';
import '../models/food_model.dart';
import 'add_food_bottom_sheet.dart';
import 'quantity_nutrition_modal.dart';

class MealDetailsPage extends StatefulWidget {
  final DateTime date;
  final String mealType;
  final String mealName;

  const MealDetailsPage({
    super.key,
    required this.date,
    required this.mealType,
    required this.mealName,
  });

  @override
  State<MealDetailsPage> createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealItems();
  }

  Future<void> _loadMealItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await MealTrackerService.getMealItems(
        date: widget.date,
        mealType: widget.mealType,
      );
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading meal items: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _totalKcal {
    return _items.fold<double>(0, (sum, item) => sum + ((item['kcal'] as num?)?.toDouble() ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mealName,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            Text(
              '${_totalKcal.toInt()} kcal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddFoodDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMealItems,
              child: _items.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildFoodItemCard(item, isDark);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 64,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'No items logged yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first food item',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAddFoodDialog();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Food'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemCard(Map<String, dynamic> item, bool isDark) {
    final food = item['foods_catalog'] as Map<String, dynamic>?;
    final foodName = food?['name'] as String? ?? 'Unknown';
    final quantity = item['quantity'] as num? ?? 0;
    final unit = item['unit'] as String? ?? '';
    final kcal = (item['kcal'] as num?)?.toDouble() ?? 0;
    final protein = (item['protein'] as num?)?.toDouble() ?? 0;
    final carbs = (item['carbs'] as num?)?.toDouble() ?? 0;
    final fat = (item['fat'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity $unit • ${kcal.toInt()} kcal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${protein.toInt()}P ${carbs.toInt()}C ${fat.toInt()}F',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Item'),
                  content: Text('Remove $foodName from ${widget.mealName}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final itemId = item['id'] as String?;
                if (itemId != null) {
                  await MealTrackerService.deleteMealItem(itemId);
                  _loadMealItems();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddFoodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodBottomSheet(
        date: widget.date,
        mealType: widget.mealType,
        onFoodAdded: () {
          _loadMealItems();
        },
      ),
    );
  }
}


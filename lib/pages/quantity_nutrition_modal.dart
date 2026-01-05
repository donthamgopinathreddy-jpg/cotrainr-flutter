import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_model.dart';
import '../services/meal_tracker_service.dart';

class QuantityNutritionModal extends StatefulWidget {
  final FoodModel food;
  final DateTime date;
  final String mealType;
  final VoidCallback onFoodAdded;

  const QuantityNutritionModal({
    super.key,
    required this.food,
    required this.date,
    required this.mealType,
    required this.onFoodAdded,
  });

  @override
  State<QuantityNutritionModal> createState() => _QuantityNutritionModalState();
}

class _QuantityNutritionModalState extends State<QuantityNutritionModal> {
  double _quantity = 1.0;
  String _selectedUnit = '';
  NutritionInfo? _nutrition;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.food.defaultUnit;
    _quantityController.text = _quantity.toStringAsFixed(_selectedUnit == 'pcs' ? 0 : 1);
    _calculateNutrition();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateNutrition() {
    setState(() {
      _nutrition = widget.food.calculateNutrition(_quantity, _selectedUnit);
    });
  }

  void _updateQuantityFromText(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() {
        _quantity = parsed;
      });
      _calculateNutrition();
    }
  }

  void _increaseQuantity() {
    HapticFeedback.lightImpact();
    setState(() {
      _quantity += _getQuantityStep();
      _quantityController.text = _quantity.toStringAsFixed(_selectedUnit == 'pcs' ? 0 : 1);
    });
    _calculateNutrition();
  }

  void _decreaseQuantity() {
    HapticFeedback.lightImpact();
    final step = _getQuantityStep();
    if (_quantity > step) {
      setState(() {
        _quantity -= step;
        _quantityController.text = _quantity.toStringAsFixed(_selectedUnit == 'pcs' ? 0 : 1);
      });
      _calculateNutrition();
    }
  }

  double _getQuantityStep() {
    switch (_selectedUnit) {
      case 'pcs':
        return 1.0;
      case 'g':
      case 'ml':
        return 10.0;
      default:
        return 0.5;
    }
  }

  List<String> get _supportedUnits => widget.food.getSupportedUnits();

  Future<void> _addFood() async {
    HapticFeedback.mediumImpact();
    
    final success = await MealTrackerService.addMealItem(
      date: widget.date,
      mealType: widget.mealType,
      foodId: widget.food.id,
      quantity: _quantity,
      unit: _selectedUnit,
    );

    if (success && mounted) {
      // onFoodAdded callback will handle closing modals
      widget.onFoodAdded();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add food item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.85,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.food.kcalPer100g.toInt()} kcal per 100g',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity Control
                  _buildQuantityControl(isDark),
                  const SizedBox(height: 32),
                  // Nutrition Info
                  if (_nutrition != null) _buildNutritionInfo(_nutrition!, isDark),
                  const SizedBox(height: 32),
                  // Micros
                  _buildMicros(_nutrition, isDark),
                ],
              ),
            ),
          ),
          // Add Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Add to ${_getMealTypeName(widget.mealType)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Decrease Button
            IconButton(
              onPressed: _quantity > _getQuantityStep() ? _decreaseQuantity : null,
              icon: Icon(
                Icons.remove_rounded,
                color: _quantity > _getQuantityStep()
                    ? (isDark ? Colors.white : const Color(0xFF1F2937))
                    : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
              ),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(width: 16),
            // Quantity Display with Text Input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                        ),
                      ),
                      onChanged: _updateQuantityFromText,
                      onSubmitted: (value) {
                        _updateQuantityFromText(value);
                      },
                    ),
                    if (_supportedUnits.length > 1)
                      DropdownButton<String>(
                        value: _selectedUnit,
                        underline: const SizedBox(),
                        items: _supportedUnits.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedUnit = value;
                              _quantityController.text = _quantity.toStringAsFixed(_selectedUnit == 'pcs' ? 0 : 1);
                            });
                            _calculateNutrition();
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Increase Button
            IconButton(
              onPressed: _increaseQuantity,
              icon: Icon(
                Icons.add_rounded,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionInfo(NutritionInfo nutrition, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard('Calories', '${nutrition.kcal.toInt()}', 'kcal', const Color(0xFFFF7A00), isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard('Protein', '${nutrition.protein.toInt()}', 'g', const Color(0xFF3B82F6), isDark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard('Carbs', '${nutrition.carbs.toInt()}', 'g', const Color(0xFF10B981), isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard('Fat', '${nutrition.fat.toInt()}', 'g', const Color(0xFFF59E0B), isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionCard(String label, String value, String unit, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicros(NutritionInfo? nutrition, bool isDark) {
    if (nutrition == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Micronutrients',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMicroCard('Fiber', '${nutrition.fiber.toInt()}g', isDark),
            _buildMicroCard('Sugar', '${nutrition.sugar.toInt()}g', isDark),
            _buildMicroCard('Sodium', '${nutrition.sodium.toInt()}mg', isDark),
            _buildMicroCard('Iron', '${nutrition.iron.toStringAsFixed(1)}mg', isDark),
            _buildMicroCard('Calcium', '${nutrition.calcium.toInt()}mg', isDark),
            _buildMicroCard('Potassium', '${nutrition.potassium.toInt()}mg', isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMicroCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  String _getMealTypeName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'snacks':
        return 'Snacks';
      case 'dinner':
        return 'Dinner';
      default:
        // Extract meal name from custom type
        if (mealType.startsWith('custom_')) {
          return mealType.substring(7).split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
        }
        return mealType.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }
}




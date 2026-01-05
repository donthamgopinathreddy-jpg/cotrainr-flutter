import 'package:flutter/material.dart';
import '../services/meal_tracker_service.dart';

class MealWeeklyInsightsPage extends StatefulWidget {
  final DateTime date;

  const MealWeeklyInsightsPage({
    super.key,
    required this.date,
  });

  @override
  State<MealWeeklyInsightsPage> createState() => _MealWeeklyInsightsPageState();
}

class _MealWeeklyInsightsPageState extends State<MealWeeklyInsightsPage> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    setState(() => _isLoading = true);
    try {
      final data = await MealTrackerService.getWeeklyMealData();
      setState(() {
        _weeklyData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading weekly data: $e');
      setState(() => _isLoading = false);
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Weekly Insights',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tabs
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildTab('Calories', 0, isDark),
                      const SizedBox(width: 12),
                      _buildTab('Macros', 1, isDark),
                      const SizedBox(width: 12),
                      _buildTab('Protein', 2, isDark),
                      const SizedBox(width: 12),
                      _buildTab('Micros', 3, isDark),
                    ],
                  ),
                ),
                // Chart Content
                Expanded(
                  child: _buildChartContent(isDark),
                ),
                // Insights
                _buildInsights(isDark),
              ],
            ),
    );
  }

  Widget _buildTab(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartContent(bool isDark) {
    if (_weeklyData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    switch (_selectedTab) {
      case 0:
        return _buildCaloriesChart(isDark);
      case 1:
        return _buildMacrosChart(isDark);
      case 2:
        return _buildProteinChart(isDark);
      case 3:
        return _buildMicrosChart(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCaloriesChart(bool isDark) {
    // Simple bar chart representation
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Average: ${_getAverageCalories().toInt()} kcal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _weeklyData.asMap().entries.map((entry) {
                final data = entry.value;
                final calories = (data['total_kcal'] as num?)?.toInt() ?? 0;
                final maxCalories = _weeklyData
                    .map((d) => (d['total_kcal'] as num?)?.toInt() ?? 0)
                    .reduce((a, b) => a > b ? a : b);
                final height = maxCalories > 0 ? (calories / maxCalories) : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          calories.toString(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosChart(bool isDark) {
    return const Center(
      child: Text('Macros Chart - Coming Soon'),
    );
  }

  Widget _buildProteinChart(bool isDark) {
    return const Center(
      child: Text('Protein Chart - Coming Soon'),
    );
  }

  Widget _buildMicrosChart(bool isDark) {
    return const Center(
      child: Text('Micros Chart - Coming Soon'),
    );
  }

  Widget _buildInsights(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow('Avg Calories', '${_getAverageCalories().toInt()} kcal', isDark),
          const SizedBox(height: 12),
          _buildInsightRow('Best Day', _getBestDay(), isDark),
          const SizedBox(height: 12),
          _buildInsightRow('Most Consistent Meal', 'Breakfast', isDark),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  double _getAverageCalories() {
    if (_weeklyData.isEmpty) return 0;
    final total = _weeklyData.fold<double>(
      0,
      (sum, data) => sum + ((data['total_kcal'] as num?)?.toDouble() ?? 0),
    );
    return total / _weeklyData.length;
  }

  String _getBestDay() {
    if (_weeklyData.isEmpty) return 'N/A';
    int maxCalories = 0;
    String bestDate = 'N/A';

    for (var data in _weeklyData) {
      final calories = (data['total_kcal'] as num?)?.toInt() ?? 0;
      if (calories > maxCalories) {
        maxCalories = calories;
        bestDate = data['date'] as String? ?? 'N/A';
      }
    }

    return bestDate;
  }
}




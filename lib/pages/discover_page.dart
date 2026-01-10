import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  int _selectedSegment = 0; // 0: Trainers, 1: Nutritionists, 2: Centers
  bool _showFilters = false;
  String _currentLocation = 'Current location';

  // Filter values
  double _distance = 10.0;
  double _rating = 0.0;
  String? _selectedGoalFocus;
  int? _selectedExperience;
  String? _selectedCategory;

  final List<String> _goalFocuses = [
    'Fat loss',
    'Muscle gain',
    'Strength',
    'Boxing',
    'Yoga',
    'Running',
    'Rehab',
  ];

  final List<String> _categories = [
    'Gym',
    'Yoga Studio',
    'Physiotherapy',
    'Boxing Gym',
    'CrossFit',
    'Pilates',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discover',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        color: const Color(0xFFFF7A00),
                        onPressed: () {
                          // Open map view
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentLocation,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar with Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: _showFilters ? const Color(0xFFFF7A00) : (isDark ? Colors.white : Colors.black54),
                    ),
                    onPressed: () {
                      setState(() => _showFilters = !_showFilters);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Segmented Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton('Trainers', 0, isDark),
                    _buildSegmentButton('Nutritionists', 1, isDark),
                    _buildSegmentButton('Centers', 2, isDark),
                  ],
                ),
              ),
            ),

            // Filter Sheet
            if (_showFilters) _buildFilterSheet(isDark),

            // Results List
            Expanded(
              child: _buildResultsList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index, bool isDark) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSegment = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSheet(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        gradient: !isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFFF8E1).withValues(alpha: 0.3),
                  const Color(0xFFFFE0B2).withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.6, 1.0],
              )
            : null,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Distance
          Text(
            'Distance: ${_distance.toInt()} km',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          Slider(
            value: _distance,
            min: 0,
            max: 50,
            divisions: 50,
            label: '${_distance.toInt()} km',
            onChanged: (value) => setState(() => _distance = value),
            activeColor: const Color(0xFFFF7A00),
          ),

          // Rating
          Text(
            'Rating: ${_rating >= 1 ? _rating.toStringAsFixed(1) : "Any"}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          Slider(
            value: _rating,
            min: 0,
            max: 5,
            divisions: 10,
            label: _rating >= 1 ? _rating.toStringAsFixed(1) : 'Any',
            onChanged: (value) => setState(() => _rating = value),
            activeColor: const Color(0xFFFF7A00),
          ),

          // Goal Focus (for Trainers/Nutritionists)
          if (_selectedSegment < 2) ...[
            const SizedBox(height: 16),
            Text(
              'Goal Focus',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalFocuses.map((goal) {
                final isSelected = _selectedGoalFocus == goal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedGoalFocus = isSelected ? null : goal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A00)
                          : (isDark ? const Color(0xFF374151) : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      goal,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Category (for Centers)
          if (_selectedSegment == 2) ...[
            const SizedBox(height: 16),
            Text(
              'Category',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = isSelected ? null : category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A00)
                          : (isDark ? const Color(0xFF374151) : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Experience (for Trainers/Nutritionists)
          if (_selectedSegment < 2) ...[
            const SizedBox(height: 16),
            Text(
              'Experience',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedExperience,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF374151) : Colors.grey[100],
                    ),
                    hint: const Text('Any'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any')),
                      const DropdownMenuItem(value: 1, child: Text('1+ years')),
                      const DropdownMenuItem(value: 3, child: Text('3+ years')),
                      const DropdownMenuItem(value: 5, child: Text('5+ years')),
                      const DropdownMenuItem(value: 10, child: Text('10+ years')),
                    ],
                    onChanged: (value) => setState(() => _selectedExperience = value),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _distance = 10.0;
                      _rating = 0.0;
                      _selectedGoalFocus = null;
                      _selectedExperience = null;
                      _selectedCategory = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFF7A00)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _showFilters = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(bool isDark) {
    final segments = ['Trainers', 'Nutritionists', 'Centers'];
    final segment = segments[_selectedSegment];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 10, // Demo count
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            gradient: !isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFFFF8E1).withValues(alpha: 0.3),
                      const Color(0xFFFFE0B2).withValues(alpha: 0.2),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _selectedSegment == 2 ? Icons.fitness_center : Icons.person,
                  size: 40,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$segment ${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < 4 ? Icons.star : Icons.star_border,
                            size: 16,
                            color: const Color(0xFFFFC300),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '4.${index % 5}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark ? Colors.grey : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(index + 1) * 0.5} km away',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFFFF7A00),
                onPressed: () {
                  // View details
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nearby_map_screen.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  int _selectedCategory = 0; // 0: Trainers, 1: Nutritionists, 2: Centers
  String _selectedSort = 'Nearest';
  String _selectedDistance = 'Within 5km';
  String? _selectedRating;
  String? _selectedGoal;
  String? _selectedExperience;
  String? _selectedSpecialization; // For nutritionists only
  final TextEditingController _searchController = TextEditingController();
  
  // Sample data
  final List<Map<String, dynamic>> _trainers = [
    {
      'name': 'John Smith',
      'specialty': 'Strength Training',
      'rating': 4.9,
      'distance': '0.8km',
      'price': '\$50/hr',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'verified': true,
      'available': true,
    },
    {
      'name': 'Sarah Johnson',
      'specialty': 'Yoga & Pilates',
      'rating': 4.8,
      'distance': '1.2km',
      'price': '\$45/hr',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'verified': true,
      'available': true,
    },
    {
      'name': 'Mike Chen',
      'specialty': 'MMA & Boxing',
      'rating': 5.0,
      'distance': '2.1km',
      'price': '\$60/hr',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      'verified': false,
      'available': false,
    },
  ];
  
  final List<Map<String, dynamic>> _nutritionists = [
    {
      'name': 'Dr. Emily Davis',
      'specialty': 'Weight Loss Nutrition',
      'rating': 4.9,
      'distance': '1.5km',
      'price': '\$80/consult',
      'avatar': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200',
      'verified': true,
      'dietType': 'Keto',
    },
    {
      'name': 'James Wilson',
      'specialty': 'Sports Nutrition',
      'rating': 4.7,
      'distance': '3.2km',
      'price': '\$75/consult',
      'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
      'verified': true,
      'dietType': 'Vegan',
    },
  ];
  
  final List<Map<String, dynamic>> _centers = [
    {
      'name': 'FitZone Gym',
      'category': 'Gym',
      'rating': 4.6,
      'distance': '0.5km',
      'price': '\$29/month',
      'logo': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
      'openNow': true,
      'crowdLevel': 'Medium',
    },
    {
      'name': 'Zen Yoga Studio',
      'category': 'Yoga',
      'rating': 4.8,
      'distance': '1.1km',
      'price': '\$45/month',
      'logo': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
      'openNow': true,
      'crowdLevel': 'Low',
    },
  ];
  
  List<Map<String, dynamic>> get _currentList {
    switch (_selectedCategory) {
      case 0:
        return _trainers;
      case 1:
        return _nutritionists;
      case 2:
        return _centers;
      default:
        return _trainers;
    }
  }
  
  // Get search placeholder based on category
  String get _searchPlaceholder {
    switch (_selectedCategory) {
      case 0:
        return 'Search trainers, skills, names';
      case 1:
        return 'Search nutritionists, plans, names';
      case 2:
        return 'Search centers, gyms, studios';
      default:
        return 'Search...';
    }
  }
  
  // Check if any filters are active
  bool get _hasActiveFilters {
    return _selectedDistance != 'Within 5km' ||
        _selectedSort != 'Nearest' ||
        _selectedRating != null ||
        _selectedGoal != null ||
        _selectedExperience != null ||
        _selectedSpecialization != null;
  }
  
  // Get filter summary text
  String? get _filterSummary {
    final parts = <String>[];
    if (_selectedDistance != 'Within 5km') {
      parts.add(_selectedDistance);
    }
    if (_selectedRating != null) {
      parts.add(_selectedRating!);
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(isDark),
            
            // Search Row
            _buildSearchRow(isDark),
            
            // Optional Filter Summary Line
            if (_filterSummary != null) _buildFilterSummary(isDark),
            
            // Type Selector (Segmented)
            _buildTypeSelector(isDark),
            
            // Main List
            Expanded(
              child: _buildMainList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Top Bar
  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
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
          const Spacer(),
          // Map icon - opens map screen
          IconButton(
            icon: Icon(
              Icons.map_outlined,
              color: const Color(0xFF14B8A6),
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
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
    );
  }

  // Search Row
  Widget _buildSearchRow(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: _searchPlaceholder,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter icon button with active state
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFiltersBottomSheet(isDark);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _hasActiveFilters
                      ? const Color(0xFF6366F1)
                      : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  size: 20,
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filter Summary Line (Optional)
  Widget _buildFilterSummary(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _filterSummary!,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // Type Selector (Segmented Control)
  Widget _buildTypeSelector(bool isDark) {
    final types = ['Trainers', 'Nutritionists', 'Centers'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(types.length, (index) {
          final isSelected = _selectedCategory == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = index;
                  // Reset filters when switching category
                  _selectedRating = null;
                  _selectedGoal = null;
                  _selectedExperience = null;
                  _selectedSpecialization = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    types[index],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Main List
  Widget _buildMainList(bool isDark) {
    final items = _currentList;
    
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(seconds: 1));
      },
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildListItemCard(items[index], isDark);
        },
      ),
    );
  }

  // List Item Card
  Widget _buildListItemCard(Map<String, dynamic> item, bool isDark) {
    final hasAvatar = item.containsKey('avatar');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Circular avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: hasAvatar ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: hasAvatar ? null : BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(
                  (hasAvatar ? item['avatar'] : item['logo']) as String,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Center: Name (bold) + Specialty (muted) + Meta row (⭐ rating · distance)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name (bold)
                Text(
                  item['name'] as String,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                // Specialty (muted)
                Text(
                  item['specialty'] ?? item['category'] ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                // Meta row: ⭐ rating · distance
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item['rating']}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['distance'] as String,
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
          
          // Right: Small rounded "View" button (same height as avatar)
          SizedBox(
            height: 56,
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Navigate to detail
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filters Bottom Sheet
  void _showFiltersBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Local state for bottom sheet
          var localDistance = _selectedDistance;
          var localSort = _selectedSort;
          var localRating = _selectedRating;
          var localGoal = _selectedGoal;
          var localExperience = _selectedExperience;
          var localSpecialization = _selectedSpecialization;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header Row
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setSheetState(() {
                            localDistance = 'Within 5km';
                            localSort = 'Nearest';
                            localRating = null;
                            localGoal = null;
                            localExperience = null;
                            localSpecialization = null;
                          });
                        },
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Body - Scrollable sections
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distance Section
                        _buildFilterSection(
                          'Distance',
                          isDark,
                          [
                            '1km',
                            '3km',
                            '5km',
                            '10km',
                            '20km',
                          ],
                          localDistance.replaceAll('Within ', ''),
                          (value) {
                            setSheetState(() {
                              localDistance = 'Within $value';
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Rating Section
                        _buildFilterSection(
                          'Rating',
                          isDark,
                          ['3.5+', '4.0+', '4.5+'],
                          localRating,
                          (value) {
                            setSheetState(() {
                              localRating = localRating == value ? null : value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Goal Section (segment-specific)
                        _buildGoalSection(isDark, localGoal, (value) {
                          setSheetState(() {
                            localGoal = localGoal == value ? null : value;
                          });
                        }),
                        
                        const SizedBox(height: 24),
                        
                        // Experience Section (segment-specific)
                        _buildExperienceSection(isDark, localExperience, (value) {
                          setSheetState(() {
                            localExperience = localExperience == value ? null : value;
                          });
                        }),
                        
                        // Specialization Section (Nutritionists only)
                        if (_selectedCategory == 1) ...[
                          const SizedBox(height: 24),
                          _buildSpecializationSection(isDark, localSpecialization, (value) {
                            setSheetState(() {
                              localSpecialization = localSpecialization == value ? null : value;
                            });
                          }),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Sort Section
                        _buildSortSection(isDark, localSort, (value) {
                          setSheetState(() {
                            localSort = value;
                          });
                        }),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Footer - Apply Button (Sticky)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selectedDistance = localDistance;
                          _selectedSort = localSort;
                          _selectedRating = localRating;
                          _selectedGoal = localGoal;
                          _selectedExperience = localExperience;
                          _selectedSpecialization = localSpecialization;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  // Filter Section Builder
  Widget _buildFilterSection(
    String title,
    bool isDark,
    List<String> options,
    String? selected,
    Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(option);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                      : (isDark ? const Color(0xFF1F2937) : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Goal Section (segment-specific)
  Widget _buildGoalSection(bool isDark, String? selected, Function(String) onSelect) {
    List<String> goals;
    switch (_selectedCategory) {
      case 0: // Trainers
        goals = ['Fat loss', 'Muscle gain', 'Strength', 'Mobility'];
        break;
      case 1: // Nutritionists
        goals = ['Weight loss', 'Muscle gain', 'Diabetes friendly', 'PCOS friendly', 'General wellness'];
        break;
      case 2: // Centers
        goals = ['General gym', 'Crossfit', 'Yoga studio', 'Physio', 'Rehab'];
        break;
      default:
        goals = [];
    }
    
    return _buildFilterSection('Goal', isDark, goals, selected, onSelect);
  }

  // Experience Section (segment-specific)
  Widget _buildExperienceSection(bool isDark, String? selected, Function(String) onSelect) {
    List<String> experiences;
    if (_selectedCategory == 2) {
      // Centers: Facility rating or Amenities
      experiences = ['4.0+ rating', '4.5+ rating', 'Parking', 'Shower', 'Pool'];
    } else {
      // Trainers & Nutritionists: Experience ranges
      experiences = ['0-1 years', '1-3 years', '3-5 years', '5+ years'];
    }
    
    return _buildFilterSection(
      _selectedCategory == 2 ? 'Facility & Amenities' : 'Experience',
      isDark,
      experiences,
      selected,
      onSelect,
    );
  }

  // Specialization Section (Nutritionists only)
  Widget _buildSpecializationSection(bool isDark, String? selected, Function(String) onSelect) {
    final specializations = ['Sports nutrition', 'Clinical', 'Veg plans', 'Keto'];
    return _buildFilterSection('Specialization', isDark, specializations, selected, onSelect);
  }

  // Sort Section
  Widget _buildSortSection(bool isDark, String selected, Function(String) onSelect) {
    final sortOptions = ['Nearest', 'Top rated'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...sortOptions.map((option) {
          final isSelected = selected == option;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(option);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                    : (isDark ? const Color(0xFF1F2937) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

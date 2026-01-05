import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  int _selectedCategory = 0; // 0: Trainers, 1: Nutritionists, 2: Centers
  String _selectedSort = 'Nearest'; // Nearest, Top Rated, Price Low
  String _selectedFilter = 'All'; // Category-specific filters
  
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
    {
      'name': 'Elite MMA',
      'category': 'MMA',
      'rating': 4.9,
      'distance': '2.3km',
      'price': '\$65/month',
      'logo': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
      'openNow': false,
      'crowdLevel': 'High',
    },
  ];
  
  final List<Map<String, dynamic>> _featuredItems = [
    {
      'title': 'Top Rated Trainer',
      'subtitle': 'John Smith - 4.9⭐',
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'type': 'trainer',
    },
    {
      'title': 'Meal Plan Specialist',
      'subtitle': 'Dr. Emily Davis',
      'image': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400',
      'type': 'nutritionist',
    },
    {
      'title': 'Best Gym Deal',
      'subtitle': 'FitZone - \$29/month',
      'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
      'type': 'center',
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
  
  List<String> get _currentFilters {
    switch (_selectedCategory) {
      case 0: // Trainers
        return ['All', 'Goal', 'Price', 'Availability', 'Distance', 'Rating'];
      case 1: // Nutritionists
        return ['All', 'DietType', 'ConsultMode', 'Price', 'Languages'];
      case 2: // Centers
        return ['All', 'Type', 'CrowdLevel', 'OpenNow', 'Distance'];
      default:
        return ['All'];
    }
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
            // Search Bar Header (Pill)
            _buildSearchBar(isDark),
            
            // Category Tabs (Top Segmented: Trainers | Nutritionists | Centers)
            _buildCategoryTabs(isDark),
            
            // Filters Row (Horizontal, category-specific)
            _buildFiltersRow(isDark),
            
            // Featured Carousel (Hero Section)
            _buildFeaturedCarousel(isDark),
            
            // Main List (Vertical Infinite Cards)
            Expanded(
              child: _buildMainList(isDark),
            ),
            
            // Quick Sort Pill (Bottom)
            _buildQuickSortPill(isDark),
          ],
        ),
      ),
    );
  }

  // Search Bar (Pill with voice + filters icon)
  Widget _buildSearchBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          Icon(
            Icons.search,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search trainers, nutritionists, centers...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Voice search
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFiltersSheet(isDark);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Category Tabs (Top Segmented: Trainers | Nutritionists | Centers)
  Widget _buildCategoryTabs(bool isDark) {
    final categories = ['Trainers', 'Nutritionists', 'Centers'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = _selectedCategory == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = index;
                  _selectedFilter = 'All';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? const Color(0xFF374151) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  categories[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Filters Row (Horizontal, category-specific)
  Widget _buildFiltersRow(bool isDark) {
    final filters = _currentFilters;
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Featured Carousel (Hero Section)
  Widget _buildFeaturedCarousel(bool isDark) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: _featuredItems.length,
        onPageChanged: (index) {
          HapticFeedback.selectionClick();
        },
        itemBuilder: (context, index) {
          final item = _featuredItems[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    item['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                      );
                    },
                  ),
                ),
                // Gradient Caption
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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

  // Main List (Vertical Infinite Cards)
  Widget _buildMainList(bool isDark) {
    final items = _currentList;
    
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 800));
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
    final hasLogo = item.containsKey('logo');
    
    return Dismissible(
      key: Key(item['name'] as String),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.bookmark, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.message, color: Colors.white),
      ),
      onDismissed: (direction) {
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          // Save
        } else {
          // Quick message
        }
      },
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showPreviewModal(item, isDark);
        },
        child: Container(
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
              // Left: Avatar/Logo
              Container(
                width: 64,
                height: 64,
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
              
              // Center: Name + Specialty + Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (item['verified'] == true)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['specialty'] ?? item['category'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${item['rating']}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on,
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
                        const SizedBox(width: 12),
                        Text(
                          item['price'] as String,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right: CTA Button ("View")
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Navigate to detail
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            ],
          ),
        ),
      ),
    );
  }

  // Quick Sort Pill (Bottom)
  Widget _buildQuickSortPill(bool isDark) {
    final sortOptions = ['Nearest', 'Top Rated', 'Price Low'];
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sortOptions.map((option) {
          final isSelected = _selectedSort == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedSort = option;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showFiltersSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Advanced Filters',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filter options for ${['Trainers', 'Nutritionists', 'Centers'][_selectedCategory]}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPreviewModal(Map<String, dynamic> item, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(
                      (item['avatar'] ?? item['logo']) as String,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item['name'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

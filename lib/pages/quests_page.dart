import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> with TickerProviderStateMixin {
  int _selectedTab = 0; // 0: Daily, 1: Weekly, 2: Rewards
  final PageController _tabPageController = PageController();
  final PageController _questCarouselController = PageController(viewportFraction: 0.86);
  late AnimationController _progressAnimationController;
  String _selectedCategory = 'All'; // All, Health, Nutrition, Activity
  
  // Progress data
  final int _todayCompleted = 3;
  final int _todayTotal = 5;
  final int _currentStreak = 6;
  final int _coins = 1250;
  
  // Sample quests
  final List<Map<String, dynamic>> _dailyQuests = [
    {
      'id': '1',
      'title': 'Walk 10,000 Steps',
      'icon': Icons.directions_walk,
      'category': 'Health',
      'progress': 0.7,
      'reward': 50,
      'completed': false,
    },
    {
      'id': '2',
      'title': 'Drink 8 Glasses of Water',
      'icon': Icons.water_drop,
      'category': 'Health',
      'progress': 0.5,
      'reward': 30,
      'completed': false,
    },
    {
      'id': '3',
      'title': 'Complete Morning Workout',
      'icon': Icons.fitness_center,
      'category': 'Activity',
      'progress': 1.0,
      'reward': 75,
      'completed': true,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _tabPageController.dispose();
    _questCarouselController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredQuests {
    if (_selectedCategory == 'All') return _dailyQuests;
    return _dailyQuests.where((q) => q['category'] == _selectedCategory).toList();
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
            // Progress Header Card
            _buildProgressHeaderCard(isDark),
            
            // Segmented Tabs
            _buildSegmentedTabs(isDark),
            
            // Category Filters (only for Daily/Weekly tabs)
            if (_selectedTab < 2) _buildCategoryFilters(isDark),
            
            // Tab Content
            Expanded(
              child: PageView(
                controller: _tabPageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                children: [
                  _buildDailyTab(isDark),
                  _buildWeeklyTab(isDark),
                  _buildRewardsTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Progress Header Card: Left=Streak Badge, Center=Today Progress Ring, Right=Coins Balance Pill
  Widget _buildProgressHeaderCard(bool isDark) {
    final progress = _todayCompleted / _todayTotal;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Streak Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$_currentStreak',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Center: Today Progress Ring
          AnimatedBuilder(
            animation: _progressAnimationController,
            builder: (context, child) {
              return SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: progress * _progressAnimationController.value,
                        strokeWidth: 6,
                        backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_todayCompleted',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          '/$_todayTotal',
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
              );
            },
          ),
          
          // Right: Coins Balance Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Segmented Tabs: Daily | Weekly | Rewards
  Widget _buildSegmentedTabs(bool isDark) {
    final tabs = ['Daily', 'Weekly', 'Rewards'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _tabPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? const Color(0xFF374151) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tabs[index],
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

  // Category Filters: All | Health | Nutrition | Activity
  Widget _buildCategoryFilters(bool isDark) {
    final categories = ['All', 'Health', 'Nutrition', 'Activity'];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF59E0B)
                      : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFF59E0B)
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

  // Daily Tab
  Widget _buildDailyTab(bool isDark) {
    return _buildQuestCarousel(isDark);
  }

  // Weekly Tab
  Widget _buildWeeklyTab(bool isDark) {
    return _buildQuestCarousel(isDark);
  }

  // Quest Carousel (Horizontal, 86% width cards)
  Widget _buildQuestCarousel(bool isDark) {
    final filteredQuests = _filteredQuests;
    
    if (filteredQuests.isEmpty) {
      return Center(
        child: Text(
          'No quests available',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      );
    }
    
    return PageView.builder(
      controller: _questCarouselController,
      itemCount: filteredQuests.length,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
      },
      itemBuilder: (context, index) {
        final quest = filteredQuests[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildQuestCard(quest, isDark),
        );
      },
    );
  }

  // Quest Card (86% width, radius 26)
  Widget _buildQuestCard(Map<String, dynamic> quest, bool isDark) {
    final progress = quest['progress'] as double;
    final isCompleted = quest['completed'] as bool;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showQuestDetails(quest, isDark);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Quest Icon + Title + Reward Pill
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      quest['icon'] as IconData,
                      color: const Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quest['title'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${quest['reward']}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Middle: Animated Progress Bar with Moving Highlight
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          value: 1.0,
                          minHeight: 12,
                          backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        ),
                        AnimatedBuilder(
                          animation: _progressAnimationController,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: progress * _progressAnimationController.value,
                              minHeight: 12,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% Complete',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Bottom Row: Primary Action Button + Secondary "Details"
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        if (isCompleted) {
                          _claimReward(quest);
                        } else {
                          _logProgress(quest);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isCompleted ? 'Claim Reward' : 'Log Progress',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showQuestDetails(quest, isDark);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
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

  // Rewards Tab
  Widget _buildRewardsTab(bool isDark) {
    final rewards = [
      {'id': '1', 'title': 'Premium Badge', 'description': 'Complete 30 quests', 'locked': false, 'progress': 0.8},
      {'id': '2', 'title': 'Gold Medal', 'description': '7-day streak', 'locked': false, 'progress': 1.0},
      {'id': '3', 'title': 'Elite Status', 'description': '1000 coins earned', 'locked': true, 'progress': 0.0},
      {'id': '4', 'title': 'Master Trainer', 'description': 'Complete 100 quests', 'locked': true, 'progress': 0.3},
    ];
    
    return Column(
      children: [
        // Rewards Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              return _buildRewardCard(reward, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward, bool isDark) {
    final isLocked = reward['locked'] as bool;
    final progress = reward['progress'] as double;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLocked
              ? (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
              : const Color(0xFFF59E0B),
          width: isLocked ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lock icon or reward icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLocked
                  ? (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
                  : const Color(0xFFF59E0B).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocked ? Icons.lock : Icons.emoji_events,
              color: isLocked
                  ? (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                  : const Color(0xFFF59E0B),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reward['title'] as String,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            reward['description'] as String,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!isLocked && progress < 1.0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _logProgress(Map<String, dynamic> quest) {
    // Log progress logic
    setState(() {
      final index = _dailyQuests.indexWhere((q) => q['id'] == quest['id']);
      if (index != -1) {
        _dailyQuests[index]['progress'] = ((_dailyQuests[index]['progress'] as double) + 0.1).clamp(0.0, 1.0);
        if (_dailyQuests[index]['progress'] >= 1.0) {
          _dailyQuests[index]['completed'] = true;
          HapticFeedback.mediumImpact();
        }
      }
    });
  }

  void _claimReward(Map<String, dynamic> quest) {
    HapticFeedback.heavyImpact();
    // Show coin burst animation and update coins
    setState(() {
      final index = _dailyQuests.indexWhere((q) => q['id'] == quest['id']);
      if (index != -1) {
        _dailyQuests.removeAt(index);
      }
    });
  }

  void _showQuestDetails(Map<String, dynamic> quest, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                quest['title'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
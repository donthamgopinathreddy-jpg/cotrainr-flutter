import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/quest_service.dart';
import '../services/streak_service.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> with TickerProviderStateMixin {
  int _selectedTab = 0; // 0: Daily, 1: Weekly, 2: Competitions
  final PageController _tabPageController = PageController();
  late AnimationController _progressAnimationController;
  
  // Level and Progress data (loaded from Supabase)
  int _currentLevel = 1;
  int _currentStreak = 0; // Active streak days
  int _coins = 0;
  int _totalXP = 0; // Total XP accumulated
  
  // Quest data
  List<Map<String, dynamic>> _dailyQuests = [];
  List<Map<String, dynamic>> _weeklyQuests = [];
  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> _leaderboard = [];
  
  bool _isLoading = true;
  
  // Calculate XP required for level N using formula: 250 + (N × 90)
  int _getXPRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return 250 + (level * 90);
  }
  
  // Calculate cumulative XP needed to reach a level
  int _getCumulativeXPForLevel(int level) {
    int total = 0;
    for (int i = 2; i <= level; i++) {
      total += _getXPRequiredForLevel(i);
    }
    return total;
  }
  
  // Get current level progress
  int get _xpToNextLevel {
    final nextLevelXP = _getCumulativeXPForLevel(_currentLevel + 1);
    return nextLevelXP - _totalXP;
  }
  
  double get _levelProgress {
    final currentLevelXP = _getCumulativeXPForLevel(_currentLevel);
    final nextLevelXP = _getCumulativeXPForLevel(_currentLevel + 1);
    final progress = (_totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP);
    return progress.clamp(0.0, 1.0);
  }
  
  int get _nextLevel => _currentLevel + 1;
  
  // Level names for all 50 levels
  String _getLevelName(int level) {
    if (level <= 0 || level > 50) return 'Unknown';
    
    final names = [
      // Tier 1 - Starter (1-5)
      'Rookie', 'Momentum', 'Starter', 'Builder', 'Consistent',
      // Tier 2 - Active (6-10)
      'Active', 'Committed', 'Tracker', 'Performer', 'Disciplined',
      // Tier 3 - Athlete (11-20)
      'Athlete', 'Pro Athlete', 'Endurance', 'Strength Minded', 'Conditioned',
      'Relentless', 'Peak Ready', 'Elite Path', 'Trained', 'Advanced Athlete',
      // Tier 4 - Elite (21-35)
      'Elite', 'Iron Focus', 'High Performer', 'Optimized', 'Resilient',
      'Power Built', 'Systematic', 'Unbreakable', 'Precision', 'Dominant',
      'Core Elite', 'Maximum Effort', 'Engineered', 'Prime', 'Top Tier',
      // Tier 5 - Legend (36-50)
      'Legend', 'Legend II', 'Legend III', 'Legend IV', 'Legend V',
      'Mythic', 'Mythic II', 'Mythic III', 'Mythic IV', 'Mythic V',
      'Icon', 'Icon II', 'Icon III', 'Icon IV', 'Ultimate',
    ];
    
    return names[level - 1];
  }
  
  // Get tier for a level
  int _getTierForLevel(int level) {
    if (level <= 5) return 1; // Starter
    if (level <= 10) return 2; // Active
    if (level <= 20) return 3; // Athlete
    if (level <= 35) return 4; // Elite
    return 5; // Legend
  }
  
  // Get tier name
  String _getTierName(int tier) {
    switch (tier) {
      case 1: return 'Starter';
      case 2: return 'Active';
      case 3: return 'Athlete';
      case 4: return 'Elite';
      case 5: return 'Legend';
      default: return 'Unknown';
    }
  }
  
  // Get tier colors for level ring
  List<Color> _getTierColors(int tier) {
    switch (tier) {
      case 1: // Starter - soft orange
        return [const Color(0xFFFF7A00), const Color(0xFFFF9A4D)];
      case 2: // Active - orange-yellow gradient
        return [const Color(0xFFFF7A00), const Color(0xFFFFC300)];
      case 3: // Athlete - orange-teal gradient
        return [const Color(0xFFFF7A00), const Color(0xFF06B6D4)];
      case 4: // Elite - amber-purple gradient
        return [const Color(0xFFFFC300), const Color(0xFFA855F7)];
      case 5: // Legend - animated gold gradient
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      default:
        return [const Color(0xFFFF7A00), const Color(0xFFFFC300)];
    }
  }
  
  // Get current rank name
  String get _currentRank => _getLevelName(_currentLevel);
  
  // Calculate streak bonus multiplier (5% per day, capped at 30%)
  double get _streakBonusMultiplier {
    final bonus = (_currentStreak * 0.05).clamp(0.0, 0.30);
    return 1.0 + bonus;
  }
  
  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnimationController.forward();
    _loadData();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Load user stats
      final userStats = await QuestService.getUserStats();
      if (userStats != null && mounted) {
        setState(() {
          _totalXP = userStats['total_xp'] as int? ?? 0;
          _coins = userStats['coins'] as int? ?? 0;
          _currentLevel = _calculateLevelFromXP(_totalXP);
        });
      }
      
      // Load streak
      final streak = await StreakService.getCurrentStreak();
      if (mounted) {
        setState(() => _currentStreak = streak);
      }
      
      // Load quests
      final dailyQuests = await QuestService.getDailyQuests();
      final weeklyQuests = await QuestService.getWeeklyQuests();
      final userProgress = await QuestService.getUserQuestProgress();
      
      // Merge quests with progress
      final dailyWithProgress = await _mergeQuestsWithProgress(dailyQuests, userProgress);
      final weeklyWithProgress = await _mergeQuestsWithProgress(weeklyQuests, userProgress);
      
      if (mounted) {
        setState(() {
          _dailyQuests = dailyWithProgress;
          _weeklyQuests = weeklyWithProgress;
        });
      }
      
      // Load competitions
      final competitions = await QuestService.getCompetitions();
      if (mounted) {
        setState(() => _competitions = competitions);
      }
      
      // Load leaderboard
      final leaderboard = await QuestService.getLeaderboard(limit: 10);
      if (mounted) {
        setState(() => _leaderboard = _formatLeaderboard(leaderboard));
      }
    } catch (e) {
      print('Error loading quest data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Calculate level from total XP
  int _calculateLevelFromXP(int totalXP) {
    int level = 1;
    int cumulativeXP = 0;
    
    while (level < 50) {
      final xpForNextLevel = _getXPRequiredForLevel(level + 1);
      if (cumulativeXP + xpForNextLevel > totalXP) {
        break;
      }
      cumulativeXP += xpForNextLevel;
      level++;
    }
    
    return level;
  }
  
  // Merge quests with user progress
  Future<List<Map<String, dynamic>>> _mergeQuestsWithProgress(
    List<Map<String, dynamic>> quests,
    List<Map<String, dynamic>> userProgress,
  ) async {
    final Map<String, Map<String, dynamic>> progressMap = {};
    for (var progress in userProgress) {
      final questId = progress['quest_id'] as String?;
      if (questId != null) {
        progressMap[questId] = progress;
      }
    }
    
    return quests.map((quest) {
      final questId = quest['id'] as String;
      final progress = progressMap[questId];
      
      final targetValue = (quest['target_value'] as num?)?.toDouble() ?? 0.0;
      final currentValue = (progress?['current_value'] as num?)?.toDouble() ?? 0.0;
      final progressValue = (progress?['progress'] as num?)?.toDouble() ?? 0.0;
      final isCompleted = progress?['is_completed'] as bool? ?? false;
      final isClaimed = progress?['is_claimed'] as bool? ?? false;
      
      // Convert icon name to IconData
      IconData icon = Icons.fitness_center;
      try {
        final iconName = quest['icon_name'] as String? ?? 'fitness_center';
        icon = _getIconFromName(iconName);
      } catch (e) {
        print('Error parsing icon: $e');
      }
      
      // Parse icon color
      Color iconColor = const Color(0xFFFF7A00);
      try {
        final colorString = quest['icon_color'] as String? ?? '#FF7A00';
        iconColor = Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      } catch (e) {
        print('Error parsing color: $e');
      }
      
      return {
        'id': questId,
        'title': quest['title'] as String? ?? '',
        'category': quest['category'] as String? ?? '',
        'icon': icon,
        'iconColor': iconColor,
        'progress': progressValue,
        'current': currentValue,
        'target': targetValue,
        'unit': quest['unit'] as String? ?? '',
        'reward': quest['xp_reward'] as int? ?? 0,
        'completed': isCompleted,
        'claimed': isClaimed,
        'description': quest['description'] as String? ?? '',
      };
    }).toList();
  }
  
  // Convert icon name string to IconData
  IconData _getIconFromName(String name) {
    switch (name) {
      case 'directions_run': return Icons.directions_run;
      case 'water_drop': return Icons.water_drop;
      case 'fitness_center': return Icons.fitness_center;
      case 'sports_gymnastics': return Icons.sports_gymnastics;
      case 'directions_walk': return Icons.directions_walk;
      case 'favorite': return Icons.favorite;
      case 'people': return Icons.people;
      default: return Icons.fitness_center;
    }
  }
  
  // Format leaderboard data
  List<Map<String, dynamic>> _formatLeaderboard(List<Map<String, dynamic>> leaderboard) {
      final userId = QuestService.supabase.auth.currentUser?.id;
    
    return leaderboard.asMap().entries.map((entry) {
      final index = entry.key;
      final user = entry.value;
      final profile = user['profiles'] as Map<String, dynamic>?;
      
      final firstName = profile?['first_name'] as String? ?? '';
      final lastName = profile?['last_name'] as String? ?? '';
      final displayName = profile?['display_name'] as String? ?? '';
      final userIdField = profile?['user_id'] as String? ?? '';
      final name = displayName.isNotEmpty
          ? displayName
          : (firstName.isNotEmpty && lastName.isNotEmpty
              ? '$firstName $lastName'
              : userIdField.isNotEmpty
                  ? userIdField
                  : 'User ${index + 1}');
      
      final userXp = user['total_xp'] as int? ?? 0;
      final userLevel = _calculateLevelFromXP(userXp);
      final isMe = user['user_id'] == userId;
      
      // Get avatar URL from storage path
      final avatarPath = profile?['avatar_path'] as String?;
      final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
          ? Supabase.instance.client.storage.from('avatars').getPublicUrl(avatarPath)
          : '';
      
      return {
        'rank': index + 1,
        'name': name,
        'avatar': avatarUrl,
        'xp': userXp,
        'level': userLevel,
        'isMe': isMe,
      };
    }).toList();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _tabPageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentQuests {
    if (_selectedTab == 0) return _dailyQuests;
    if (_selectedTab == 1) return _weeklyQuests;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  children: [
                    // Top Header: Title, Subtitle, Coins
                    _buildTopHeader(isDark),
                    
                    // User Progress Card with Level
                    _buildLevelProgressCard(isDark),
                    
                    // Quest Type Selection (Daily/Weekly/Competitions)
                    _buildQuestTypeSelector(isDark),
                    
                    // Content Section
                    Expanded(
                      child: PageView(
                        controller: _tabPageController,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedTab = index;
                          });
                        },
                        children: [
                          _buildQuestsSection(isDark),
                          _buildQuestsSection(isDark),
                          _buildCompetitionsSection(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Top Header: Title, Subtitle, Coins
  Widget _buildTopHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Title and Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quests',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep the streak alive!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          // Right: Coins Balance
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(Icons.monetization_on, color: const Color(0xFFFFC300), size: 24),
                  Positioned(
                    left: 8,
                    child: Icon(Icons.monetization_on, color: const Color(0xFFFFC300), size: 24),
                  ),
                  Positioned(
                    left: 16,
                    child: Icon(Icons.monetization_on, color: const Color(0xFFFFC300), size: 24),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                _formatNumber(_coins),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFC300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Level Progress Card (Redesigned with Tier Colors)
  Widget _buildLevelProgressCard(bool isDark) {
    final tier = _getTierForLevel(_currentLevel);
    final tierColors = _getTierColors(tier);
    final tierName = _getTierName(tier);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showLevelsModal(isDark);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1F2937),
                    const Color(0xFF111827),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF9FAFB),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: tierColors[0].withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: tierColors[0].withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Circular Progress with Level (Tier-based colors)
            AnimatedBuilder(
              animation: _progressAnimationController,
              builder: (context, child) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tierColors[0].withValues(alpha: 0.2),
                        tierColors[1].withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: _levelProgress * _progressAnimationController.value,
                          strokeWidth: 6,
                          backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(tierColors[0]),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tierColors[0].withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LVL',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tierColors[0],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_currentLevel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            // Center: Rank and XP (Enhanced with Tier)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: tierColors,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentRank.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tierColors[0].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tierColors[0].withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tierName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tierColors[0],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_xpToNextLevel XP to Level $_nextLevel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // XP Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _levelProgress,
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(tierColors[0]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${_formatNumber(_totalXP)} Total XP',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_currentStreak > 0) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 12,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${(_streakBonusMultiplier * 100 - 100).toStringAsFixed(0)}% XP',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Right: Arrow Icon with tier glow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tierColors[0].withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: tierColors[0],
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show Levels Modal
  void _showLevelsModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level $_currentLevel • $_currentRank',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            // Current Level Card (with tier colors)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(
                builder: (context) {
                  final tier = _getTierForLevel(_currentLevel);
                  final tierColors = _getTierColors(tier);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tierColors[0].withValues(alpha: 0.2),
                          tierColors[1].withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tierColors[0].withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _levelProgress,
                                strokeWidth: 6,
                                backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation<Color>(tierColors[0]),
                              ),
                              Text(
                                '$_currentLevel',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentRank,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_xpToNextLevel XP until Level $_nextLevel',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _levelProgress,
                                  minHeight: 6,
                                  backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                  valueColor: AlwaysStoppedAnimation<Color>(tierColors[0]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // All Levels List (50 levels grouped by tier)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 50,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  final tier = _getTierForLevel(level);
                  final tierColors = _getTierColors(tier);
                  final tierName = _getTierName(tier);
                  final xpRequired = _getXPRequiredForLevel(level);
                  final cumulativeXP = _getCumulativeXPForLevel(level);
                  final isCurrentLevel = level == _currentLevel;
                  final isUnlocked = level <= _currentLevel;
                  final levelName = _getLevelName(level);
                  
                  // Show tier header for first level of each tier
                  final showTierHeader = level == 1 || 
                      (level == 6) || 
                      (level == 11) || 
                      (level == 21) || 
                      (level == 36);
                  
                  return Column(
                    children: [
                      if (showTierHeader) ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: 12, top: level == 1 ? 0 : 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: tierColors),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tierName.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCurrentLevel
                              ? tierColors[0].withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF1F2937) : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrentLevel
                                ? tierColors[0]
                                : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                            width: isCurrentLevel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Level Number Badge
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: isCurrentLevel
                                    ? LinearGradient(colors: tierColors)
                                    : (isUnlocked
                                        ? LinearGradient(
                                            colors: [
                                              tierColors[0].withValues(alpha: 0.2),
                                              tierColors[1].withValues(alpha: 0.1),
                                            ],
                                          )
                                        : null),
                                color: !isUnlocked
                                    ? (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
                                    : null,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCurrentLevel
                                    ? const Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : Text(
                                        '$level',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: isUnlocked
                                              ? (isCurrentLevel
                                                  ? Colors.white
                                                  : tierColors[0])
                                              : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Level Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        levelName,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isCurrentLevel
                                              ? tierColors[0]
                                              : (isUnlocked
                                                  ? (isDark ? Colors.white : const Color(0xFF1F2937))
                                                  : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))),
                                        ),
                                      ),
                                      if (isCurrentLevel) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: tierColors[0],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'CURRENT',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Level $level • ${_formatNumber(cumulativeXP)} XP',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  if (level > 1)
                                    Text(
                                      '+${_formatNumber(xpRequired)} XP needed',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Status Icon
                            if (isUnlocked && !isCurrentLevel)
                              Icon(
                                Icons.check_circle_rounded,
                                color: const Color(0xFF10B981),
                                size: 24,
                              )
                            else if (!isUnlocked)
                              Icon(
                                Icons.lock_rounded,
                                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Quest Type Selector (Daily/Weekly/Competitions)
  Widget _buildQuestTypeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildQuestTypeButton('Daily', 0, isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuestTypeButton('Weekly', 1, isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuestTypeButton('Competitions', 2, isDark),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestTypeButton(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _tabPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A00)
              : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
  
  // Quests Section
  Widget _buildQuestsSection(bool isDark) {
    return Column(
      children: [
        // Section Header: "Today's Quests" with "View All"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTab == 0 ? "Today's Quests" : "This Week's Quests",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to all quests
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF7A00),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Quest Cards List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _currentQuests.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildQuestCard(_currentQuests[index], isDark),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Competitions Section
  Widget _buildCompetitionsSection(bool isDark) {
    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Competitions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to all competitions
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF7A00),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Competitions List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Competition Cards
              ..._competitions.map((comp) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCompetitionCard(comp, isDark),
              )),
              const SizedBox(height: 24),
              // Leaderboard Section
              _buildLeaderboardSection(isDark),
            ],
          ),
        ),
      ],
    );
  }
  
  // Competition Card
  Widget _buildCompetitionCard(Map<String, dynamic> comp, bool isDark) {
    final progress = comp['myProgress'] / comp['topProgress'];
    final rank = comp['myRank'];
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Show competition details
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rank == 1
                ? const Color(0xFFFFC300)
                : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            width: rank == 1 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (comp['iconColor'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    comp['icon'] as IconData,
                    color: comp['iconColor'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp['title'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (comp['iconColor'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              comp['type'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: comp['iconColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${comp['participants']} participants',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Prize Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC300), Color(0xFFFF7A00)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comp['prize'] as String,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Section
            Row(
              children: [
                // Top User Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(comp['topUserAvatar'] as String),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${comp['topUser']} leads',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(comp['iconColor'] as Color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Rank Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? const Color(0xFFFFC300).withValues(alpha: 0.2)
                        : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                    border: rank == 1
                        ? Border.all(color: const Color(0xFFFFC300), width: 1)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: rank == 1
                            ? const Color(0xFFFFC300)
                            : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#$rank',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rank == 1
                              ? const Color(0xFFFFC300)
                              : (isDark ? Colors.white : const Color(0xFF1F2937)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Duration
            Text(
              comp['duration'] as String,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Leaderboard Section
  Widget _buildLeaderboardSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Global Leaderboard',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _leaderboard.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final isLast = index == _leaderboard.length - 1;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '#${user['rank']}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: user['rank'] <= 3
                              ? const Color(0xFFFF7A00)
                              : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                    // Avatar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(user['avatar'] as String),
                        ),
                        if (user['rank'] <= 3)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: user['rank'] == 1
                                    ? const Color(0xFFFFC300)
                                    : user['rank'] == 2
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFFCD7F32),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Name and Level
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user['name'] as String,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: user['isMe'] ? FontWeight.w700 : FontWeight.w600,
                                  color: user['isMe']
                                      ? const Color(0xFFFF7A00)
                                      : (isDark ? Colors.white : const Color(0xFF1F2937)),
                                ),
                              ),
                              if (user['isMe'])
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF7A00),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level ${user['level']} • ${_formatNumber(user['xp'] as int)} XP',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // XP Value
                    Text(
                      '${_formatNumber(user['xp'] as int)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: user['rank'] <= 3
                            ? const Color(0xFFFF7A00)
                            : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  String _formatNumber(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }


  // Quest Card (matching reference design)
  Widget _buildQuestCard(Map<String, dynamic> quest, bool isDark) {
    final progress = quest['progress'] as double;
    final current = quest['current'];
    final target = quest['target'];
    final unit = quest['unit'] as String;
    final iconColor = quest['iconColor'] as Color;
    final percentage = (progress * 100).toStringAsFixed(0);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showQuestDetails(quest, isDark);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // XP Badge in top right
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${quest['reward']} XP',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Title Row
                Row(
                  children: [
                    Icon(
                      quest['icon'] as IconData,
                      color: iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            quest['category'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                AnimatedBuilder(
                  animation: _progressAnimationController,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress * _progressAnimationController.value,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Progress Text and Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$current / $target $unit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _logProgress(Map<String, dynamic> quest) async {
    final questId = quest['id'] as String;
    final current = quest['current'] as double;
    final target = quest['target'] as double;
    final newCurrent = current + (target * 0.1);
    final newProgress = (newCurrent / target).clamp(0.0, 1.0);
    
    final success = await QuestService.updateQuestProgress(
      questId: questId,
      progress: newProgress,
      currentValue: newCurrent,
    );
    
    if (success) {
      setState(() {
        final quests = _selectedTab == 0 ? _dailyQuests : _weeklyQuests;
        final index = quests.indexWhere((q) => q['id'] == questId);
        if (index != -1) {
          quests[index]['progress'] = newProgress;
          quests[index]['current'] = newCurrent;
          if (newProgress >= 1.0) {
            quests[index]['completed'] = true;
            HapticFeedback.mediumImpact();
          }
        }
      });
    }
  }

  Future<void> _claimReward(Map<String, dynamic> quest) async {
    final questId = quest['id'] as String;
    
    final success = await QuestService.claimQuestReward(questId);
    
    if (success) {
      HapticFeedback.heavyImpact();
      
      // Reload user stats and quests
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reward claimed! +${quest['reward']} XP'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to claim reward'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          quest['icon'] as IconData,
                          color: const Color(0xFF6366F1),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              quest['description'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

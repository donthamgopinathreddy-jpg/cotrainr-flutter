import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  int _selectedTab = 0; // 0: Friends, 1: Nearby, 2: Global
  final PageController _tabController = PageController();
  
  // Sample data
  final List<Map<String, dynamic>> _friendsRanking = [
    {'name': 'Alex Johnson', 'rank': 1, 'score': 12500, 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200', 'delta': 250, 'change': '+'},
    {'name': 'Sarah Chen', 'rank': 2, 'score': 11800, 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', 'delta': 180, 'change': '+'},
    {'name': 'You', 'rank': 3, 'score': 11200, 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', 'delta': -50, 'change': '-'},
    {'name': 'Mike Wilson', 'rank': 4, 'score': 10800, 'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200', 'delta': 120, 'change': '+'},
  ];
  
  final List<Map<String, dynamic>> _nearbyRanking = [
    {'name': 'John Smith', 'rank': 1, 'score': 15200, 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200', 'delta': 300, 'change': '+'},
    {'name': 'Emily Davis', 'rank': 2, 'score': 14800, 'avatar': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200', 'delta': 200, 'change': '+'},
    {'name': 'You', 'rank': 15, 'score': 11200, 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', 'delta': -50, 'change': '-'},
  ];
  
  final List<Map<String, dynamic>> _globalRanking = [
    {'name': 'Elite Trainer', 'rank': 1, 'score': 25000, 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200', 'delta': 500, 'change': '+'},
    {'name': 'Pro Athlete', 'rank': 2, 'score': 24800, 'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200', 'delta': 400, 'change': '+'},
    {'name': 'Fitness Master', 'rank': 3, 'score': 24500, 'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200', 'delta': 350, 'change': '+'},
    {'name': 'You', 'rank': 1250, 'score': 11200, 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', 'delta': -50, 'change': '-'},
  ];
  
  List<Map<String, dynamic>> get _currentRanking {
    switch (_selectedTab) {
      case 0:
        return _friendsRanking;
      case 1:
        return _nearbyRanking;
      case 2:
        return _globalRanking;
      default:
        return _friendsRanking;
    }
  }
  
  Map<String, dynamic>? get _myRank {
    return _currentRanking.firstWhere(
      (item) => item['name'] == 'You',
      orElse: () => {'name': 'You', 'rank': 0, 'score': 0},
    );
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
            // Header: Gradient Banner + Your Rank Pill
            _buildHeader(isDark),
            
            // Tabs: Friends | Nearby | Global
            _buildTabs(isDark),
            
            // List: Rank Rows
            Expanded(
              child: PageView(
                controller: _tabController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                children: [
                  _buildRankingList(_friendsRanking, isDark),
                  _buildRankingList(_nearbyRanking, isDark),
                  _buildRankingList(_globalRanking, isDark),
                ],
              ),
            ),
            
            // Weekly Reset Countdown Pill
            _buildResetCountdown(isDark),
          ],
        ),
      ),
    );
  }

  // Header: Gradient Banner + Your Rank Pill
  Widget _buildHeader(bool isDark) {
    final myRank = _myRank;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF59E0B),
            const Color(0xFFEC4899),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Leaderboard',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Your Rank Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your Rank: #${myRank?['rank'] ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tabs: Friends | Nearby | Global
  Widget _buildTabs(bool isDark) {
    final tabs = ['Friends', 'Nearby', 'Global'];
    
    return Container(
      margin: const EdgeInsets.all(20),
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
                _tabController.animateToPage(
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

  // Ranking List
  Widget _buildRankingList(List<Map<String, dynamic>> ranking, bool isDark) {
    // Sort by rank
    final sorted = List<Map<String, dynamic>>.from(ranking)..sort((a, b) => (a['rank'] as int).compareTo(b['rank'] as int));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final item = sorted[index];
        final isMe = item['name'] == 'You';
        return _buildRankRow(item, isMe, isDark);
      },
    );
  }

  // Rank Row
  Widget _buildRankRow(Map<String, dynamic> item, bool isMe, bool isDark) {
    final rank = item['rank'] as int;
    final isTopThree = rank <= 3;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showProfilePreview(item, isDark);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          gradient: !isDark && !isMe
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white,
                    const Color(0xFFFFF8E1).withValues(alpha: 0.3), // Very light yellow
                    const Color(0xFFFFE0B2).withValues(alpha: 0.2), // Very light orange
                  ],
                  stops: const [0.0, 0.5, 0.7, 1.0],
                )
              : null,
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
            // Rank Number
            SizedBox(
              width: 40,
              child: Text(
                isTopThree ? ['🥇', '🥈', '🥉'][rank - 1] : '#$rank',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isTopThree ? 24 : 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(item['avatar'] as String),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Name + Delta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['name'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      if (isMe)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        item['change'] == '+' ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: item['change'] == '+'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['delta']}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item['change'] == '+'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Score + Mini Sparkline (placeholder)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item['score']}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.6),
                        const Color(0xFFEC4899).withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Weekly Reset Countdown Pill
  Widget _buildResetCountdown(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        gradient: !isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFFF8E1).withValues(alpha: 0.3), // Very light yellow
                  const Color(0xFFFFE0B2).withValues(alpha: 0.2), // Very light orange
                ],
                stops: const [0.0, 0.6, 1.0],
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.update, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Text(
            'Weekly reset in 2 days',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfilePreview(Map<String, dynamic> item, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(item['avatar'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item['name'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rank #${item['rank']}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
}



























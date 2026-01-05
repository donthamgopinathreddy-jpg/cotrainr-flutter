import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cocircle_service.dart';
import '../services/daily_stats_service.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? userData;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.userData,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  int _level = 1;
  int _totalSteps = 0;
  Map<String, dynamic>? _userStats;
  List<Map<String, dynamic>> _weeklyInsights = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserPosts();
    _checkFollowingStatus();
    _loadUserStats();
    _loadWeeklyInsights();
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('id, user_id, display_name, first_name, last_name, avatar_path, cover_path, role')
          .eq('id', widget.userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userProfile = response;
        });
      } else if (widget.userData != null && mounted) {
        setState(() {
          _userProfile = widget.userData;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await CoCircleService.getPosts(userId: widget.userId);
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkFollowingStatus() async {
    try {
      final isFollowing = await CoCircleService.isFollowing(widget.userId);
      final followers = await CoCircleService.getFollowerCount(widget.userId);
      final following = await CoCircleService.getFollowingCount(widget.userId);
      
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _followersCount = followers;
          _followingCount = following;
        });
      }
    } catch (e) {
      print('Error checking following status: $e');
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final supabase = Supabase.instance.client;
      // Get user stats (level, XP, total steps)
      final statsResponse = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();
      
      if (statsResponse != null && mounted) {
        setState(() {
          _userStats = statsResponse;
          _level = statsResponse['level'] as int? ?? 1;
        });
      }
      
      // Calculate total steps from daily_stats
      final allStats = await supabase
          .from('daily_stats')
          .select('steps')
          .eq('user_id', widget.userId);
      
      int totalSteps = 0;
      for (var stat in allStats) {
        totalSteps += stat['steps'] as int? ?? 0;
      }
      
      if (mounted) {
        setState(() => _totalSteps = totalSteps);
      }
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  Future<void> _loadWeeklyInsights() async {
    try {
      // Get weekly stats for insights
      final weeklyData = await DailyStatsService.getWeeklyStats('all');
      if (mounted) {
        setState(() => _weeklyInsights = weeklyData);
      }
    } catch (e) {
      print('Error loading weekly insights: $e');
    }
  }

  Future<void> _toggleFollow() async {
    HapticFeedback.mediumImpact();
    try {
      if (_isFollowing) {
        await CoCircleService.unfollowUser(widget.userId);
      } else {
        await CoCircleService.followUser(widget.userId);
      }
      await _checkFollowingStatus();
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supabase = Supabase.instance.client;
    
    final displayName = _userProfile?['display_name'] ?? 
                       '${_userProfile?['first_name'] ?? ''} ${_userProfile?['last_name'] ?? ''}'.trim() ??
                       widget.userData?['display_name'] ?? 'User';
    final userId = _userProfile?['user_id'] ?? widget.userData?['user_id'] ?? 'user';
    final avatarPath = _userProfile?['avatar_path'] ?? widget.userData?['avatar_path'];
    final coverPath = _userProfile?['cover_path'];
    final avatarUrl = avatarPath != null && (avatarPath as String).isNotEmpty
        ? supabase.storage.from('avatars').getPublicUrl(avatarPath)
        : null;
    final coverUrl = coverPath != null && (coverPath as String).isNotEmpty
        ? supabase.storage.from('covers').getPublicUrl(coverPath)
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Cover Image
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          
          // Profile Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  
                  // Name and User ID
                  Text(
                    displayName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@$userId',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level $_level',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Total Steps
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_walk_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Steps',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              _formatNumber(_totalSteps),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Follow/Following button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
                            : Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isFollowing
                              ? (isDark ? Colors.white : const Color(0xFF1F2937))
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Posts', '${_userPosts.length}', isDark),
                      _buildStatItem('Followers', '$_followersCount', isDark),
                      _buildStatItem('Following', '$_followingCount', isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Weekly Insights
                  if (_weeklyInsights.isNotEmpty) ...[
                    Text(
                      'Weekly Insights',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildInsightRow('Steps', _getWeeklyTotal('steps'), Icons.directions_walk_rounded, isDark),
                          const SizedBox(height: 12),
                          _buildInsightRow('Calories', '${_getWeeklyTotal('calories')} kcal', Icons.local_fire_department_rounded, isDark),
                          const SizedBox(height: 12),
                          _buildInsightRow('Water', '${_getWeeklyTotal('water')} ml', Icons.water_drop_rounded, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          
          // Posts Grid
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_userPosts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No posts yet',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _userPosts.length) return null;
                    final post = _userPosts[index];
                    return GestureDetector(
                      onTap: () {
                        // Show post details
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: post['mediaUrl'] != null
                              ? Image.network(
                                  post['mediaUrl'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                    );
                                  },
                                )
                              : Container(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                ),
                        ),
                      ),
                    );
                  },
                  childCount: _userPosts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
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

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  String _getWeeklyTotal(String type) {
    int total = 0;
    for (var day in _weeklyInsights) {
      if (type == 'steps') {
        total += day['steps'] as int? ?? 0;
      } else if (type == 'calories') {
        total += day['calories_burned'] as int? ?? 0;
      } else if (type == 'water') {
        total += day['water_ml'] as int? ?? 0;
      }
    }
    return _formatNumber(total);
  }
}


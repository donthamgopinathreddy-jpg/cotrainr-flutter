import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/cocircle_service.dart';
import 'user_profile_page.dart';
import 'post_detail_page.dart';

class CoCirclePage extends StatefulWidget {
  const CoCirclePage({super.key});

  @override
  State<CoCirclePage> createState() => _CoCirclePageState();
}

class _CoCirclePageState extends State<CoCirclePage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _gradientController;
  
  int _selectedSegment = 0; // 0 = Post, 1 = Following, 2 = Community
  double _headerHeight = 80.0;
  int _followers = 0;
  int _following = 0;
  String? _currentUserId;
  
  // Posts data from Supabase
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;
  
  // Search results (users)
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  // Track following status for search results and posts
  Map<String, bool> _followingStatus = {};
  
  // Handle post submission
  Future<void> _handlePostSubmission({required String text, File? media}) async {
    setState(() => _isLoadingPosts = true);
    
    try {
      final newPost = await CoCircleService.createPost(
        caption: text,
        mediaFile: media,
      );
      
      if (newPost != null && mounted) {
        // Show success message and refresh posts in current segment
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Posted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        // Refresh posts in current segment
        await _fetchPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }
  
  Future<void> _fetchPosts() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      _currentUserId = userId;
      
      // Fetch posts based on selected segment
      List<Map<String, dynamic>> posts;
      if (_selectedSegment == 1) {
        // Following feed - posts from users I follow
        posts = await _fetchFollowingPosts(userId);
      } else if (_selectedSegment == 0) {
        // My Posts only (for Post segment)
        posts = await CoCircleService.getPosts(userId: userId);
      } else {
        // All posts (Community)
        posts = await CoCircleService.getPosts();
      }
      
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFollowingPosts(String? userId) async {
    if (userId == null) return [];
    
    try {
      // Get list of users I'm following
      final following = await CoCircleService.getFollowing(userId);
      if (following.isEmpty) return [];
      
      // Get user IDs I'm following
      final followingIds = following.map((f) => f['id'] as String).toList();
      
      // Get posts from users I'm following
      final posts = await CoCircleService.getPosts();
      return posts.where((post) => followingIds.contains(post['user_id'])).toList();
    } catch (e) {
      print('Error fetching following posts: $e');
      return [];
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      _fetchPosts();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingPosts = false;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Search by user_id (exact match or starts with) - include own account
      final userResults = await supabase
          .from('profiles')
          .select('id, user_id, display_name, first_name, last_name, avatar_path, role')
          .ilike('user_id', '$query%')
          .limit(10);
      
      // Format user results for display
      final formattedUsers = (userResults as List).map((user) {
        final avatarPath = user['avatar_path'];
        final avatarUrl = avatarPath != null && (avatarPath as String).isNotEmpty
            ? supabase.storage.from('avatars').getPublicUrl(avatarPath)
            : null;
        
        return {
          'id': user['id'],
          'user_id': user['user_id'],
          'display_name': user['display_name'] ?? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
          'first_name': user['first_name'],
          'last_name': user['last_name'],
          'avatar_url': avatarUrl,
          'role': user['role'],
        };
      }).toList();
      
      if (mounted) {
        // Check following status for each user
        final currentUserId = supabase.auth.currentUser?.id;
        if (currentUserId != null) {
          for (var user in formattedUsers) {
            final userId = user['id'] as String;
            if (userId != currentUserId) {
              CoCircleService.isFollowing(userId).then((isFollowing) {
                if (mounted) {
                  setState(() {
                    _followingStatus[userId] = isFollowing;
                  });
                }
              });
            }
          }
        }
        setState(() {
          _searchResults = formattedUsers;
          _isSearching = true;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }
  
  Future<void> _fetchFollowCounts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final followers = await CoCircleService.getFollowerCount(userId);
      final following = await CoCircleService.getFollowingCount(userId);
      
      if (mounted) {
        setState(() {
          _followers = followers;
          _following = following;
        });
      }
    } catch (e) {
      print('Error fetching follow counts: $e');
    }
  }
  
  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _scrollController.addListener(_onScroll);
    
    // Fetch initial data
    _fetchPosts();
    _fetchFollowCounts();
  }
  
  @override
  void didUpdateWidget(CoCirclePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when segment changes
    if (_selectedSegment != oldWidget.key) {
      _fetchPosts();
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _gradientController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    // Compress header on scroll down, expand on scroll up
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      setState(() {
        _headerHeight = (80.0 - (offset * 0.1)).clamp(72.0, 80.0);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Sticky Header
                _buildStickyHeader(isDark),
                
                // Search and Filters Row
                SliverToBoxAdapter(
                  child: _buildSearchAndFilters(isDark),
                ),
                
                // Search Results (if searching)
                if (_isSearching && _searchResults.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSearchResults(isDark),
                  ),
                
                // Segment Selector
                SliverToBoxAdapter(
                  child: _buildSegmentSelector(isDark),
                ),
                
                // Post Creation UI (if Post segment selected)
                if (_selectedSegment == 0)
                  SliverToBoxAdapter(
                    child: CoCirclePostComposer(
                      currentUserId: _currentUserId ?? '',
                      onPost: _handlePostSubmission,
                    ),
                  ),
                
                // My Posts in 2-column grid (if Post segment selected)
                if (_selectedSegment == 0)
                  if (_isLoadingPosts)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_posts.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyMyPosts(isDark),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= _posts.length) return null;
                            return _buildPostCardGrid(_posts[index], isDark);
                          },
                          childCount: _posts.length,
                        ),
                      ),
                    ),
                
                // Following Feed (if Following segment selected)
                if (_selectedSegment == 1) ...[
                  if (_isLoadingPosts)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_posts.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyFollowing(isDark),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _posts.length) return null;
                          return _buildPostCard(_posts[index], isDark);
                        },
                        childCount: _posts.length,
                      ),
                    ),
                ],
                
                // Feed (only show in Community segment)
                if (_selectedSegment == 2)
                  if (_isLoadingPosts)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _posts.length) return null;
                          return _buildPostCard(_posts[index], isDark);
                        },
                        childCount: _posts.length,
                      ),
                    ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            
          ],
        ),
      ),
    );
  }
  
  // Sticky Header with Glass Blur and Gradient
  Widget _buildStickyHeader(bool isDark) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: _headerHeight,
      collapsedHeight: _headerHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF8B5CF6), // Purple
                    const Color(0xFF6366F1), // Blue
                    (math.sin(_gradientController.value * 2 * math.pi) + 1) / 2,
                  )!.withValues(alpha: 0.15), // Very subtle opacity
                  Color.lerp(
                    const Color(0xFF6366F1), // Blue
                    const Color(0xFF14B8A6), // Teal
                    (math.sin(_gradientController.value * 2 * math.pi + 1) / 2 + 1) / 2,
                  )!.withValues(alpha: 0.15),
                  const Color(0xFF14B8A6).withValues(alpha: 0.15), // Teal
                ],
              ),
            ),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: (isDark ? const Color(0xFF111827) : Colors.white)
                      .withValues(alpha: 0.8),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CoCircle',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your fitness circle',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Search and Filters Row
  Widget _buildSearchAndFilters(bool isDark) {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(24), // Pill shape
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
                  onChanged: (value) {
                    // Search as user types
                    if (value.trim().isNotEmpty) {
                      _searchUsers(value.trim());
                    } else {
                      // Clear search results immediately
                      setState(() {
                        _isSearching = false;
                        _searchResults = [];
                      });
                      _fetchPosts();
                    }
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _searchUsers(value.trim());
                    }
                  },
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by user_id, hashtag, workout',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Search Results List
  Widget _buildSearchResults(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Users',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          ..._searchResults.map((user) => _buildUserSearchItem(user, isDark)),
        ],
      ),
    );
  }
  
  Widget _buildUserSearchItem(Map<String, dynamic> user, bool isDark) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnProfile = user['id'] == currentUserId;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _navigateToUserProfile(user['id'] as String, user);
            },
            child: CircleAvatar(
              radius: 24,
              backgroundImage: user['avatar_url'] != null
                  ? NetworkImage(user['avatar_url'] as String)
                  : null,
              child: user['avatar_url'] == null
                  ? Icon(
                      Icons.person,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _navigateToUserProfile(user['id'] as String, user);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['display_name'] as String? ?? user['user_id'] as String? ?? 'User',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user['user_id'] ?? 'user'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isOwnProfile)
            Builder(
              builder: (context) {
                final userId = user['id'] as String;
                final isFollowing = _followingStatus[userId] ?? false;
                return GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    try {
                      if (isFollowing) {
                        await CoCircleService.unfollowUser(userId);
                      } else {
                        await CoCircleService.followUser(userId);
                      }
                      setState(() {
                        _followingStatus[userId] = !isFollowing;
                      });
                      // Refresh follow counts
                      _fetchFollowCounts();
                    } catch (e) {
                      print('Error toggling follow: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
                          : const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFollowing
                            ? (isDark ? Colors.white : const Color(0xFF1F2937))
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              size: 20,
            ),
        ],
      ),
    );
  }
  
  void _navigateToUserProfile(String userId, Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: userId,
          userData: userData,
        ),
      ),
    );
  }
  
  void _navigateToPostDetail(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(post: post),
      ),
    );
  }
  
  // Segment Selector
  Widget _buildSegmentSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedSegment = 0;
                });
                // Clear search when switching to Post tab
                _searchController.clear();
                _fetchPosts();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedSegment == 0
                      ? (isDark ? const Color(0xFF374151) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Post',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: _selectedSegment == 0
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _selectedSegment == 0
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedSegment = 1;
                });
                _fetchPosts(); // Refresh to show following feed
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedSegment == 1
                      ? (isDark ? const Color(0xFF374151) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Following',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: _selectedSegment == 1
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _selectedSegment == 1
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedSegment = 2;
                });
                _fetchPosts(); // Refresh to show all posts
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedSegment == 2
                      ? (isDark ? const Color(0xFF374151) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: _selectedSegment == 2
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _selectedSegment == 2
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Empty State for Following
  Widget _buildEmptyFollowing(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts from people you follow',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start following people to see their posts here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
  
  // Empty State for My Posts
  Widget _buildEmptyMyPosts(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 64,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'You haven\'t posted yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your fitness journey with the community',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedSegment = 0; // Switch to Post tab
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create your first post',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Post Card Grid (for 2-column layout)
  Widget _buildPostCardGrid(Map<String, dynamic> post, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToPostDetail(post);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: post['mediaUrl'] != null
                    ? Image.network(
                        post['mediaUrl'] as String,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                            child: Icon(
                              Icons.image,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                        child: Icon(
                          Icons.image,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
              ),
              // Caption preview
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  post['caption'] as String? ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Post Card
  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16), // Rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Profile Image
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _navigateToUserProfile(post['user_id'] as String, {
                      'id': post['user_id'],
                      'user_id': post['userName'],
                      'display_name': post['fullName'],
                      'avatar_path': post['avatar'],
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(post['avatar']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (post['isVerified'] && post['isTrainer'])
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Username and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post['userName'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        post['role'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Follow/Unfollow button (if not own post)
                Builder(
                  builder: (context) {
                    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                    final postUserId = post['user_id'] as String?;
                    final isOwnPost = postUserId == currentUserId;
                    
                    if (isOwnPost || postUserId == null) {
                      return const SizedBox.shrink();
                    }
                    
                    // Check following status
                    final isFollowing = _followingStatus[postUserId] ?? false;
                    
                    // Load following status if not cached
                    if (!_followingStatus.containsKey(postUserId)) {
                      CoCircleService.isFollowing(postUserId).then((following) {
                        if (mounted) {
                          setState(() {
                            _followingStatus[postUserId] = following;
                          });
                        }
                      });
                    }
                    
                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        try {
                          if (isFollowing) {
                            await CoCircleService.unfollowUser(postUserId);
                          } else {
                            await CoCircleService.followUser(postUserId);
                          }
                          setState(() {
                            _followingStatus[postUserId] = !isFollowing;
                          });
                          // Refresh follow counts
                          _fetchFollowCounts();
                          // Refresh posts if in Following feed
                          if (_selectedSegment == 1) {
                            _fetchPosts();
                          }
                        } catch (e) {
                          print('Error toggling follow: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
                              : const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isFollowing
                                ? (isDark ? Colors.white : const Color(0xFF1F2937))
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 8),
                
                // Three dot menu
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showPostMenu(post, isDark);
                  },
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          // Media Section
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _navigateToPostDetail(post);
            },
            onDoubleTap: () async {
              HapticFeedback.mediumImpact();
              final postId = post['id'] as String;
              final isLiked = post['isLiked'] as bool;
              
              // Toggle like
              if (isLiked) {
                await CoCircleService.unlikePost(postId);
              } else {
                await CoCircleService.likePost(postId);
              }
              
              // Refresh post data
              final likeCount = await CoCircleService.getPostLikeCount(postId);
              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
              final newIsLiked = currentUserId != null
                  ? await CoCircleService.isPostLikedByUser(postId, currentUserId)
                  : false;
              
              if (mounted) {
                setState(() {
                  post['isLiked'] = newIsLiked;
                  post['likes'] = likeCount;
                });
              }
            },
            child: AspectRatio(
              aspectRatio: post['mediaType'] == 'video' ? 16 / 9 : 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  post['mediaUrl'] != null
                      ? Image.network(
                          post['mediaUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                              child: const Icon(Icons.broken_image, size: 48),
                            );
                          },
                        )
                      : Container(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          child: const Icon(Icons.image, size: 48),
                        ),
                  
                  // Video Play Button
                  if (post['mediaType'] == 'video')
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Engagement Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Like
                _buildEngagementIcon(
                  icon: post['isLiked']
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  isActive: post['isLiked'],
                  count: post['likes'],
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final postId = post['id'] as String;
                    final isLiked = post['isLiked'] as bool;
                    
                    // Toggle like
                    if (isLiked) {
                      await CoCircleService.unlikePost(postId);
                    } else {
                      await CoCircleService.likePost(postId);
                    }
                    
                    // Refresh post data
                    final likeCount = await CoCircleService.getPostLikeCount(postId);
                    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                    final newIsLiked = currentUserId != null
                        ? await CoCircleService.isPostLikedByUser(postId, currentUserId)
                        : false;
                    
                    if (mounted) {
                      setState(() {
                        post['isLiked'] = newIsLiked;
                        post['likes'] = likeCount;
                      });
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                
                // Comment
                _buildEngagementIcon(
                  icon: Icons.chat_bubble_outline_rounded,
                  isActive: false,
                  count: post['comments'],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showCommentsSheet(post, isDark);
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                
                // Share
                _buildEngagementIcon(
                  icon: Icons.send_outlined,
                  isActive: false,
                  count: null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Share post
                  },
                  isDark: isDark,
                ),
                
                const Spacer(),
                
                // Save
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      post['isSaved'] = !post['isSaved'];
                    });
                  },
                  child: Icon(
                    post['isSaved']
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: post['isSaved']
                        ? const Color(0xFF14B8A6)
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Caption Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    children: [
                      TextSpan(
                        text: '${post['userName']} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: post['caption'],
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                // Hashtags
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: post['caption']
                      .toString()
                      .split(' ')
                      .where((word) => word.startsWith('#'))
                      .take(3) // Limit to 3 hashtags
                      .map((hashtag) => GestureDetector(
                            onTap: () {
                              // Search by hashtag
                            },
                            child: Text(
                              hashtag,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF6366F1), // Accent color
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),
                // View Comments
                if (post['comments'] > 0)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showCommentsSheet(post, isDark);
                    },
                    child: Text(
                      'View all ${post['comments']} comments',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEngagementIcon({
    required IconData icon,
    required bool isActive,
    int? count,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive
                ? const Color(0xFFEC4899) // Soft gradient on active
                : (isDark ? Colors.white : const Color(0xFF1F2937)),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
  
  void _showCommentsSheet(Map<String, dynamic> post, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsBottomSheet(
        post: post,
        isDark: isDark,
        onCommentAdded: () {
          // Refresh post comments count
          _fetchPosts();
        },
      ),
    );
  }
  
  void _showPostMenu(Map<String, dynamic> post, bool isDark) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnPost = post['user_id'] == currentUserId;
    
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
            if (isOwnPost)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final postId = post['id'] as String;
                  final deleted = await CoCircleService.deletePost(postId);
                  if (deleted && mounted) {
                    await _fetchPosts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted')),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy Link'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showUserListSheet(String title, List<Map<String, dynamic>> users, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
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
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        'No $title yet',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final firstName = user['first_name'] ?? '';
                        final lastName = user['last_name'] ?? '';
                        final displayName = user['display_name'] ?? '';
                        final fullName = displayName.isNotEmpty 
                            ? displayName 
                            : '$firstName $lastName'.trim();
                        final userIdField = user['user_id'] ?? 'user';
                        // Get avatar URL from storage path
                        final avatarPath = user['avatar_path'];
                        final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
                            ? Supabase.instance.client.storage.from('avatars').getPublicUrl(avatarPath)
                            : null;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            backgroundColor: avatarUrl == null
                                ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
                                : null,
                            child: avatarUrl == null
                                ? const Icon(Icons.person, size: 20, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            fullName.isNotEmpty ? fullName : userIdField,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          subtitle: Text(
                            '@$userIdField',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                          onTap: () {
                            // TODO: Navigate to user profile
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Comments Bottom Sheet Widget
class _CommentsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isDark;
  final VoidCallback onCommentAdded;

  const _CommentsBottomSheet({
    required this.post,
    required this.isDark,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final postId = widget.post['id'] as String;
      final comments = await CoCircleService.getPostComments(postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    try {
      final postId = widget.post['id'] as String;
      final newComment = await CoCircleService.createComment(
        postId: postId,
        commentText: text,
      );

      if (newComment != null && mounted) {
        _commentController.clear();
        await _loadComments();
        widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'now';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'now';
      }
    } catch (e) {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(_comments[index], widget.isDark);
                        },
                      ),
          ),
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(
                  color: widget.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: widget.isDark ? const Color(0xFF1F2937) : Colors.white,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    onPressed: _isPosting ? null : _postComment,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: comment['avatar'] != null
                  ? DecorationImage(
                      image: NetworkImage(comment['avatar']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: comment['avatar'] == null
                  ? const Color(0xFF14B8A6).withValues(alpha: 0.3)
                  : null,
            ),
            child: comment['avatar'] == null
                ? const Icon(Icons.person, size: 20, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    children: [
                      TextSpan(
                        text: '@${comment['username']} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: comment['comment_text'] ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(comment['created_at']),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CoCircle Post Composer Widget (from drop-in)
class CoCirclePostComposer extends StatefulWidget {
  final String currentUserId;
  final Future<void> Function({required String text, File? media}) onPost;
  
  const CoCirclePostComposer({
    super.key,
    required this.currentUserId,
    required this.onPost,
  });
  
  @override
  State<CoCirclePostComposer> createState() => _CoCirclePostComposerState();
}

class _CoCirclePostComposerState extends State<CoCirclePostComposer> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  File? _selected;
  bool _posting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<bool> _ensureGalleryPermission() async {
    if (Platform.isIOS) {
      final s = await Permission.photos.status;
      if (s.isGranted || s.isLimited) return true;
      final r = await Permission.photos.request();
      return r.isGranted || r.isLimited;
    } else {
      final s1 = await Permission.photos.status;
      if (s1.isGranted) return true;
      final s2 = await Permission.storage.status;
      if (s2.isGranted) return true;
      final r1 = await Permission.photos.request();
      if (r1.isGranted) return true;
      final r2 = await Permission.storage.request();
      return r2.isGranted;
    }
  }

  Future<void> _pickFromGallery() async {
    final ok = await _ensureGalleryPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allow Photos to add media')),
      );
      return;
    }
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    setState(() => _selected = File(x.path));
  }

  Future<void> _submit() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty && _selected == null) return;
    setState(() => _posting = true);
    try {
      await widget.onPost(text: t, media: _selected);
      _ctrl.clear();
      setState(() => _selected = null);
      _focus.unfocus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPost = _ctrl.text.trim().isNotEmpty || _selected != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 1000,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
          if (_selected != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(_selected!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _posting ? null : _pickFromGallery,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF7A00), Color(0xFFFFC400)],
                  ).createShader(bounds),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: canPost ? 1 : 0.45,
                duration: const Duration(milliseconds: 140),
                child: IgnorePointer(
                  ignoring: !canPost || _posting,
                  child: GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A00), Color(0xFFFFC400)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _posting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Post',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// CoCircle Feed Widget (from drop-in)
class CoCircleFeed extends StatelessWidget {
  final String currentUserId;
  final List<Map<String, dynamic>> allPosts;
  final bool myPostsOnly;
  final bool isDark;
  final Widget Function(Map<String, dynamic>) onPostCard;
  final Widget Function() onEmptyState;
  
  const CoCircleFeed({
    super.key,
    required this.currentUserId,
    required this.allPosts,
    required this.myPostsOnly,
    required this.isDark,
    required this.onPostCard,
    required this.onEmptyState,
  });

  @override
  Widget build(BuildContext context) {
    final posts = myPostsOnly
        ? allPosts.where((p) => p['userId'] == currentUserId).toList()
        : allPosts;
    
    if (posts.isEmpty) {
      return onEmptyState();
    }
    
    return Column(
      children: posts.map((post) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: onPostCard(post),
      )).toList(),
    );
  }
}

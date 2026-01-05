import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/verified_badge.dart';
import '../services/theme_provider.dart';

class CoCirclePage extends StatefulWidget {
  const CoCirclePage({super.key});

  @override
  State<CoCirclePage> createState() => _CoCirclePageState();
}

class _CoCirclePageState extends State<CoCirclePage>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _searchFadeController;

  // State
  bool _isSearchActive = false;
  String _selectedFilter = 'All'; // All, Photos, Videos, Trainers, Following
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 10;

  // Sample data - in real app, this would come from API
  final List<Map<String, dynamic>> _posts = List.generate(
    20,
    (index) => {
      'id': index,
      'userId': 'user$index',
      'userName': 'User ${index + 1}',
      'fullName': 'User Name ${index + 1}',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'timestamp': '${index + 1}h ago',
      'caption': 'Great workout today! 💪 #fitness #motivation #progress',
      'mediaUrls': [
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        if (index % 3 == 0) 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
      ],
      'mediaType': index % 4 == 0 ? 'video' : 'photo',
      'reactions': {
        '💪': 42 + (index * 5),
        '🔥': 18 + (index * 3),
        '🧠': 8 + index,
      },
      'totalReactions': 68 + (index * 9),
      'comments': 8 + index,
      'isLiked': index % 3 == 0,
      'isSaved': index % 4 == 0,
      'isFollowing': index % 2 == 0,
      'isTrainer': index % 2 == 0,
      'isVerified': index % 2 == 0,
      'role': index % 2 == 0 ? 'Trainer' : 'Client',
    },
  );

  @override
  void initState() {
    super.initState();
    _searchFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePosts();
    }
  }

  void _loadMorePosts() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _currentPage++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar - Search First
            _buildTopBar(isDark),
            
            // Filter Chips (when not searching)
            if (!_isSearchActive) _buildFilterChips(isDark),
            
            // Search Field (when active)
            if (_isSearchActive) _buildActiveSearchField(isDark),
            
            // Feed or Search Results
            Expanded(
              child: _isSearchActive && _searchController.text.isNotEmpty
                  ? _buildSearchResults(isDark)
                  : _buildInfiniteFeed(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Active Search Field
  Widget _buildActiveSearchField(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5),
            width: 0.5,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          hintText: 'Search by UserID or hashtag...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) {
          HapticFeedback.mediumImpact();
          // Perform search
        },
      ),
    );
  }

  // Top Bar - Search First Design
  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Bar (Always Visible)
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isSearchActive = !_isSearchActive;
                  if (!_isSearchActive) {
                    _searchController.clear();
                  }
                });
                if (_isSearchActive) {
                  _searchFadeController.forward();
                } else {
                  _searchFadeController.reverse();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search by UserID or hashtag...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Filter Icon
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFilterBottomSheet(isDark);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filter Chips
  Widget _buildFilterChips(bool isDark) {
    final filters = ['All', 'Photos', 'Videos', 'Trainers', 'Following'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
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
                    ? (isDark ? Colors.white : const Color(0xFF1F2937))
                    : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? const Color(0xFF1F2937) : Colors.white)
                        : (isDark ? const Color(0xFF6B6B6B) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Infinite Feed
  Widget _buildInfiniteFeed(bool isDark) {
    final filteredPosts = _getFilteredPosts();
    
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _currentPage = 0;
        });
      },
      color: const Color(0xFFEC4899),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: filteredPosts.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredPosts.length) {
            return _buildShimmerLoader(isDark);
          }
          return _buildPostCard(filteredPosts[index], isDark);
        },
      ),
    );
  }

  // Post Card - Instagram-like Design
  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: isDark ? const Color(0xFF000000) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(post, isDark),
          
          // Media (Hero)
          _buildPostMedia(post, isDark),
          
          // Post Actions
          _buildPostActions(post, isDark),
          
          // Caption & Meta
          _buildPostCaption(post, isDark),
          
          // View Comments
          _buildViewComments(post, isDark),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Post Header
  Widget _buildPostHeader(Map<String, dynamic> post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Navigate to profile
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                  width: 1,
                ),
                image: DecorationImage(
                  image: NetworkImage(post['avatar']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Username + Badge + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post['userName'],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post['isVerified'])
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: VerifiedBadge(size: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  post['role'],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          
          // Time + Menu
          Text(
            post['timestamp'],
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showPostMenu(post, isDark);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Post Media (Hero)
  Widget _buildPostMedia(Map<String, dynamic> post, bool isDark) {
    final mediaUrls = post['mediaUrls'] as List;
    final isVideo = post['mediaType'] == 'video';
    
    return GestureDetector(
      onDoubleTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          post['isLiked'] = !post['isLiked'];
        });
        // Show heart animation
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image/Video
            PageView.builder(
              itemCount: mediaUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(mediaUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            
            // Video Play Button
            if (isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            
            // Carousel Indicators
            if (mediaUrls.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    mediaUrls.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Post Actions
  Widget _buildPostActions(Map<String, dynamic> post, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // React (💪)
          _buildActionButton(
            icon: Icons.fitness_center_rounded,
            label: '💪',
            isActive: post['isLiked'],
            count: post['reactions']['💪'],
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                post['isLiked'] = !post['isLiked'];
              });
            },
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          
          // Comment
          _buildActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: null,
            isActive: false,
            count: post['comments'],
            onTap: () {
              HapticFeedback.lightImpact();
              _showCommentsBottomSheet(post, isDark);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          
          // Share
          _buildActionButton(
            icon: Icons.send_outlined,
            label: null,
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
            child: AnimatedScale(
              scale: post['isSaved'] ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                post['isSaved'] ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 24,
                color: post['isSaved']
                    ? const Color(0xFFEC4899)
                    : (isDark ? Colors.white : const Color(0xFF1F2937)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required bool isActive,
    int? count,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedScale(
            scale: isActive ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              icon,
              size: 24,
              color: isActive
                  ? const Color(0xFFEC4899)
                  : (isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 18),
            ),
          ],
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
            ),
          ],
        ],
      ),
    );
  }

  // Post Caption
  Widget _buildPostCaption(Map<String, dynamic> post, bool isDark) {
    final caption = post['caption'] as String;
    final hasMore = caption.length > 100;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  text: '${post['userName']} ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: hasMore ? caption.substring(0, 100) : caption,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasMore)
            GestureDetector(
              onTap: () {
                // Expand caption
              },
              child: Text(
                'more',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                ),
              ),
            ),
          const SizedBox(height: 4),
          // Hashtags
          Wrap(
            spacing: 4,
            children: caption
                .split(' ')
                .where((word) => word.startsWith('#'))
                .map((hashtag) => GestureDetector(
                      onTap: () {
                        // Search by hashtag
                      },
                      child: Text(
                        hashtag,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // View Comments
  Widget _buildViewComments(Map<String, dynamic> post, bool isDark) {
    if (post['comments'] == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showCommentsBottomSheet(post, isDark);
        },
        child: Text(
          'View all ${post['comments']} comments',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }

  // Comments Bottom Sheet
  void _showCommentsBottomSheet(Map<String, dynamic> post, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF000000) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Comments',
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
            // Comments List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: post['comments'],
                itemBuilder: (context, index) {
                  return _buildCommentItem(isDark);
                },
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Post',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
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

  Widget _buildCommentItem(bool isDark) {
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
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                ),
                fit: BoxFit.cover,
              ),
            ),
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
                      const TextSpan(
                        text: 'username ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: 'Great progress! Keep it up 💪'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2h ago',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Search Results
  Widget _buildSearchResults(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Search Results',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        // User results
        _buildUserSearchResult(isDark),
        const SizedBox(height: 24),
        // Post results
        _buildPostSearchResult(isDark),
      ],
    );
  }

  Widget _buildUserSearchResult(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Users',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return _buildUserCard(isDark);
          },
        ),
      ],
    );
  }

  Widget _buildUserCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'username',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Full Name',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Follow'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSearchResult(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posts',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Shimmer Loader
  Widget _buildShimmerLoader(bool isDark) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Helper Methods
  List<Map<String, dynamic>> _getFilteredPosts() {
    var posts = _posts;
    
    switch (_selectedFilter) {
      case 'Photos':
        posts = posts.where((p) => p['mediaType'] == 'photo').toList();
        break;
      case 'Videos':
        posts = posts.where((p) => p['mediaType'] == 'video').toList();
        break;
      case 'Trainers':
        posts = posts.where((p) => p['isTrainer'] == true).toList();
        break;
      case 'Following':
        posts = posts.where((p) => p['isFollowing'] == true).toList();
        break;
    }
    
    return posts;
  }

  void _showFilterBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Feed',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            // Filter options would go here
          ],
        ),
      ),
    );
  }

  void _showPostMenu(Map<String, dynamic> post, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CoCirclePage extends StatefulWidget {
  const CoCirclePage({super.key});

  @override
  State<CoCirclePage> createState() => _CoCirclePageState();
}

class _CoCirclePageState extends State<CoCirclePage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  int _selectedFilter = 0; // 0: All, 1: Nearby, 2: Friends, 3: Active

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('''
            *,
            profiles:user_id (
              user_id_handle,
              display_name,
              profile_photo_url,
              role
            ),
            likes:post_id(count),
            comments:post_id(count)
          ''')
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _posts.clear();
        for (var post in response) {
          _posts.add({
            'post_id': post['post_id'],
            'user_id': post['user_id'],
            'caption': post['caption'] ?? '',
            'media_urls': post['media_urls'] ?? [],
            'created_at': post['created_at'],
            'profile': post['profiles'],
            'likes_count': post['likes']?.length ?? 0,
            'comments_count': post['comments']?.length ?? 0,
            'is_liked': false, // Check if current user liked
          });
        }
      });
    } catch (e) {
      print('Error loading posts: $e');
      // Use demo data if database fails
      _loadDemoPosts();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadDemoPosts() {
    setState(() {
      _posts.addAll([
        {
          'post_id': '1',
          'user_id': 'user1',
          'caption': 'Just completed a 5K run! 🏃‍♂️ Feeling amazing!',
          'media_urls': [],
          'created_at': DateTime.now().subtract(const Duration(hours: 2)),
          'profile': {
            'user_id_handle': '@alex',
            'display_name': 'Alex Johnson',
            'profile_photo_url': null,
            'role': 'client',
          },
          'likes_count': 24,
          'comments_count': 5,
          'is_liked': false,
        },
        {
          'post_id': '2',
          'user_id': 'user2',
          'caption': 'New PR in deadlift today! 💪',
          'media_urls': [],
          'created_at': DateTime.now().subtract(const Duration(hours: 5)),
          'profile': {
            'user_id_handle': '@sarah',
            'display_name': 'Sarah Chen',
            'profile_photo_url': null,
            'role': 'trainer',
          },
          'likes_count': 42,
          'comments_count': 8,
          'is_liked': true,
        },
      ]);
    });
  }

  Future<void> _handleLike(String postId, bool isLiked) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      if (isLiked) {
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await Supabase.instance.client
            .from('likes')
            .insert({
          'post_id': postId,
          'user_id': userId,
        });
      }

      setState(() {
        final post = _posts.firstWhere((p) => p['post_id'] == postId);
        post['is_liked'] = !isLiked;
        post['likes_count'] = (post['likes_count'] as int) + (isLiked ? -1 : 1);
      });
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    ).then((_) => _loadPosts());
  }

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CoCircle',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    color: const Color(0xFFFF7A00),
                    onPressed: _openCreatePost,
                  ),
                ],
              ),
            ),

            // Filter Pills
            _buildFilterPills(isDark),

            // Feed
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPosts,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _posts.isEmpty
                        ? Center(
                            child: Text(
                              'No posts yet. Be the first to post!',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: isDark ? Colors.grey : Colors.black54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              return _buildPostCard(_posts[index], isDark);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills(bool isDark) {
    final filters = ['All', 'Nearby', 'Friends', 'Active'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF7A00)
                    : (isDark ? const Color(0xFF1F2937) : Colors.white),
                borderRadius: BorderRadius.circular(24),
                gradient: !isDark && !isSelected
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
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  filters[index],
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
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, bool isDark) {
    final profile = post['profile'] as Map<String, dynamic>? ?? {};
    final caption = post['caption'] as String? ?? '';
    final createdAt = post['created_at'] as DateTime? ?? DateTime.now();
    final likesCount = post['likes_count'] as int? ?? 0;
    final commentsCount = post['comments_count'] as int? ?? 0;
    final isLiked = post['is_liked'] as bool? ?? false;
    final mediaUrls = post['media_urls'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  child: profile['profile_photo_url'] != null
                      ? ClipOval(
                          child: Image.network(
                            profile['profile_photo_url'] as String,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile['display_name'] as String? ?? 'User',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profile['user_id_handle'] as String? ?? '@user',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (profile['role'] as String? ?? 'client').toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF7A00),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(createdAt),
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
              ],
            ),
          ),

          // Media
          if (mediaUrls.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: mediaUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onDoubleTap: () => _handleLike(post['post_id'] as String, isLiked),
                    child: Image.network(
                      mediaUrls[index] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

          // Caption
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                caption,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _handleLike(post['post_id'] as String, isLiked),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : (isDark ? Colors.white : Colors.black54),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        likesCount.toString(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    const Icon(Icons.comment_outlined, size: 24, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      commentsCount.toString(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 24),
                  color: Colors.grey,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _createPost() async {
    if (_captionController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption or image')),
      );
      return;
    }

    if (_captionController.text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption must be 1000 characters or less')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload images to Supabase Storage
      List<String> mediaUrls = [];
      for (var image in _selectedImages) {
        final file = File(image.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        await Supabase.instance.client.storage
            .from('post-media')
            .upload(fileName, file);

        final url = Supabase.instance.client.storage
            .from('post-media')
            .getPublicUrl(fileName);
        mediaUrls.add(url);
      }

      // Create post
      await Supabase.instance.client.from('posts').insert({
        'user_id': userId,
        'caption': _captionController.text.trim(),
        'media_urls': mediaUrls,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _createPost,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF7A00),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImages.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: isDark ? Colors.grey : Colors.black54,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photos',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: isDark ? Colors.grey : Colors.black54,
                            ),
                          ),
                        ],
                      )
                    : PageView.builder(
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Caption Input
            TextField(
              controller: _captionController,
              maxLength: 1000,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '${_captionController.text.length}/1000',
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }
}

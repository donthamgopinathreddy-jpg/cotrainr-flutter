import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cocircle_service.dart';
import 'user_profile_page.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailPage({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _likes = [];
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  bool _isLoading = true;
  bool _isPostingComment = false;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post['isLiked'] as bool? ?? false;
    _likeCount = widget.post['likes'] as int? ?? 0;
    _isSaved = widget.post['isSaved'] as bool? ?? false;
    _loadPostDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    setState(() => _isLoading = true);
    try {
      final postId = widget.post['id'] as String;
      
      // Load comments and likes in parallel
      final comments = await CoCircleService.getPostComments(postId);
      final likes = await CoCircleService.getPostLikes(postId);
      final likeCount = await CoCircleService.getPostLikeCount(postId);
      
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final isLiked = currentUserId != null
          ? await CoCircleService.isPostLikedByUser(postId, currentUserId)
          : false;
      
      if (mounted) {
        setState(() {
          _comments = comments;
          _likes = likes;
          _likeCount = likeCount;
          _isLiked = isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading post details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    HapticFeedback.mediumImpact();
    try {
      final postId = widget.post['id'] as String;
      if (_isLiked) {
        await CoCircleService.unlikePost(postId);
        setState(() {
          _isLiked = false;
          _likeCount = (_likeCount - 1).clamp(0, double.infinity).toInt();
        });
      } else {
        await CoCircleService.likePost(postId);
        setState(() {
          _isLiked = true;
          _likeCount = _likeCount + 1;
        });
      }
      // Refresh likes list
      final likes = await CoCircleService.getPostLikes(postId);
      if (mounted) {
        setState(() => _likes = likes);
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);
    HapticFeedback.mediumImpact();

    try {
      final postId = widget.post['id'] as String;
      await CoCircleService.createComment(
        postId: postId,
        commentText: text,
      );
      
      _commentController.clear();
      await _loadPostDetails(); // Refresh comments
    } catch (e) {
      print('Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.white : Colors.black),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isSaved = !_isSaved);
                    },
                  ),
                ],
              ),
            ),
            
            // Media view with likes and comments below
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Image/Media view
                    _buildMediaView(isDark),
                    
                    // Post caption and likes
                    _buildPostInfo(isDark),
                    
                    // Comments dropdown/popup
                    if (_showComments) _buildCommentsDropdown(isDark),
                  ],
                ),
              ),
            ),
            
            // Bottom actions and comment input
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaView(bool isDark) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.5,
      color: Colors.black,
      child: widget.post['mediaUrl'] != null
          ? Image.network(
              widget.post['mediaUrl'] as String,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image, color: Colors.white, size: 64),
                );
              },
            )
          : Container(
              color: Colors.grey[900],
              child: const Icon(Icons.image, color: Colors.white, size: 64),
            ),
    );
  }
  
  Widget _buildPostInfo(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF111827) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with user info
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _navigateToUserProfile(widget.post['user_id'] as String);
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post['avatar'] != null
                      ? NetworkImage(widget.post['avatar'] as String)
                      : null,
                  child: widget.post['avatar'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['userName'] as String? ?? 'user',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Caption
          Text(
            widget.post['caption'] as String? ?? '',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Likes as continuous text
          if (_likes.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                // Show full likes list if needed
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 16,
                    color: Color(0xFFEC4899),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatLikesText(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
  
  String _formatLikesText() {
    if (_likes.isEmpty) return '';
    
    final names = _likes.take(10).map((like) {
      return like['display_name'] as String? ?? '@${like['user_id'] ?? 'user'}';
    }).toList();
    
    if (_likes.length <= 10) {
      return names.join(', ');
    } else {
      return '${names.join(', ')} and ${_likes.length - 10} others';
    }
  }
  
  Widget _buildCommentsDropdown(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${_comments.length})',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() => _showComments = false);
                  },
                  color: isDark ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'No comments yet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: comment['avatar'] != null
                                      ? NetworkImage(comment['avatar'] as String)
                                      : null,
                                  child: comment['avatar'] == null
                                      ? const Icon(Icons.person, size: 18)
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
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '@${comment['username'] ?? 'user'} ',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                              text: comment['comment_text'] as String? ?? '',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(comment['created_at'] as String?),
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
                        },
                      ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked
                        ? const Color(0xFFEC4899)
                        : (isDark ? Colors.white : Colors.black),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showComments = !_showComments);
                  },
                  child: Icon(
                    Icons.comment_outlined,
                    color: isDark ? Colors.white : Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_comments.length}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isPostingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  onPressed: _isPostingComment ? null : _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: userId),
      ),
    );
  }
}



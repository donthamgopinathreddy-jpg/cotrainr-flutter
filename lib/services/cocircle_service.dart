import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class CoCircleService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // POSTS
  // ============================================

  /// Fetch all posts with user info, likes, and comments
  static Future<List<Map<String, dynamic>>> getPosts({
    String? userId, // If provided, only get posts from this user
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('posts')
          .select('''
            *,
            profiles!posts_user_id_fkey (
              id,
              user_id,
              first_name,
              last_name,
              display_name,
              avatar_path,
              role
            )
          ''');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      final currentUserId = _supabase.auth.currentUser?.id;

      // Get likes and comments for each post
      final postsWithEngagement = await Future.wait(
        (response as List).map((post) async {
          final postId = post['id'] as String;
          
          // Get like count and check if current user liked
          final likeCount = await getPostLikeCount(postId);
          final isLiked = currentUserId != null
              ? await isPostLikedByUser(postId, currentUserId)
              : false;

          // Get comment count
          final commentCount = await getPostCommentCount(postId);

          // Get user info
          final profile = post['profiles'] as Map<String, dynamic>?;
          final firstName = profile?['first_name'] ?? '';
          final lastName = profile?['last_name'] ?? '';
          final displayName = profile?['display_name'] ?? '';
          final fullName = displayName.isNotEmpty 
              ? displayName 
              : '$firstName $lastName'.trim();
          final userIdField = profile?['user_id'] ?? 'user';
          final role = profile?['role'] ?? 'client';
          // Get avatar URL from storage path
          final avatarPath = profile?['avatar_path'];
          final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
              ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
              : null;

      // Check if user is verified trainer
      final isTrainer = role == 'trainer';
      bool isVerified = false;
      if (isTrainer) {
        final postUserId = post['user_id'] as String;
        final trainerResponse = await _supabase
            .from('trainer_profiles')
            .select('verified')
            .eq('user_id', postUserId)
            .maybeSingle();
        isVerified = trainerResponse?['verified'] == true;
      }

          return {
            'id': postId,
            'user_id': post['user_id'],
            'userName': userIdField,
            'fullName': fullName.isNotEmpty ? fullName : userIdField,
            'avatar': avatarUrl,
            'role': role == 'trainer' ? 'Trainer' : 'Client',
            'isVerified': isVerified,
            'isTrainer': isTrainer,
            'timestamp': post['created_at'],
            'caption': post['caption'] ?? '',
            'mediaUrl': post['media_path'] != null && (post['media_path'] as String).isNotEmpty
                ? _supabase.storage.from('posts').getPublicUrl(post['media_path'])
                : null,
            'mediaType': post['media_type'] ?? 'image',
            'likes': likeCount,
            'comments': commentCount,
            'isLiked': isLiked,
            'isSaved': false, // TODO: Implement saved posts
          };
        }),
      );

      return postsWithEngagement;
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  /// Create a new post
  static Future<Map<String, dynamic>?> createPost({
    required String caption,
    File? mediaFile,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      String? mediaPath;
      String mediaType = 'photo';

      // Upload media if provided
      if (mediaFile != null) {
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${mediaFile.path.split('/').last}';
          final filePath = '$userId/$fileName';

          // Upload with error handling
          await _supabase.storage
              .from('posts')
              .upload(
                filePath,
                mediaFile,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );

          // Store the path, not the full URL
          mediaPath = filePath;

          // TODO: Detect video type if needed
          mediaType = 'image';
          print('✅ [COCIRCLE] Media uploaded successfully: $filePath');
        } catch (uploadError) {
          print('❌ [COCIRCLE] Error uploading media: $uploadError');
          throw Exception('Failed to upload image: $uploadError');
        }
      }

      // Create post (use media_path, store path not full URL)
      final response = await _supabase
          .from('posts')
          .insert({
            'user_id': userId,
            'caption': caption,
            'media_path': mediaPath, // Store path, not full URL
            'media_type': mediaType,
          })
          .select('''
            *,
            profiles!posts_user_id_fkey (
              id,
              user_id,
              first_name,
              last_name,
              display_name,
              avatar_path,
              role
            )
          ''')
          .single();

      // Get user info
      final profile = response['profiles'] as Map<String, dynamic>?;
      final firstName = profile?['first_name'] ?? '';
      final lastName = profile?['last_name'] ?? '';
      final displayName = profile?['display_name'] ?? '';
      final fullName = displayName.isNotEmpty 
          ? displayName 
          : '$firstName $lastName'.trim();
      final userIdField = profile?['user_id'] ?? 'user';
      final role = profile?['role'] ?? 'client';
      // Get avatar URL from storage path
      final avatarPath = profile?['avatar_path'];
      final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
          ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
          : null;

      return {
        'id': response['id'],
        'user_id': userId,
        'userName': userIdField,
        'fullName': fullName.isNotEmpty ? fullName : userIdField,
        'avatar': avatarUrl,
        'role': role == 'trainer' ? 'Trainer' : 'Client',
        'isVerified': false,
        'isTrainer': role == 'trainer',
        'timestamp': response['created_at'],
        'caption': caption,
        'mediaUrl': mediaPath != null 
            ? _supabase.storage.from('posts').getPublicUrl(mediaPath)
            : null,
        'mediaType': mediaType,
        'likes': 0,
        'comments': 0,
        'isLiked': false,
        'isSaved': false,
      };
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Delete a post
  static Future<bool> deletePost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // ============================================
  // LIKES
  // ============================================

  /// Get like count for a post
  static Future<int> getPostLikeCount(String postId) async {
    try {
      final response = await _supabase
          .rpc('get_post_like_count', params: {'post_id_param': postId});
      return response as int? ?? 0;
    } catch (e) {
      // Fallback to direct query
      final response = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId);
      return (response as List).length;
    }
  }

  /// Get list of users who liked a post
  static Future<List<Map<String, dynamic>>> getPostLikes(String postId) async {
    try {
      final response = await _supabase
          .from('post_likes')
          .select('''
            *,
            profiles!post_likes_user_id_fkey (
              id,
              user_id,
              display_name,
              first_name,
              last_name,
              avatar_path
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return (response as List).map((like) {
        final profile = like['profiles'] as Map<String, dynamic>?;
        final avatarPath = profile?['avatar_path'];
        final avatarUrl = avatarPath != null && (avatarPath as String).isNotEmpty
            ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
            : null;
        
        return {
          'id': profile?['id'],
          'user_id': profile?['user_id'],
          'display_name': profile?['display_name'] ?? '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim(),
          'avatar_url': avatarUrl,
        };
      }).toList();
    } catch (e) {
      print('Error fetching post likes: $e');
      return [];
    }
  }

  /// Check if user liked a post
  static Future<bool> isPostLikedByUser(String postId, String userId) async {
    try {
      final response = await _supabase
          .rpc('is_post_liked_by_user', params: {
            'post_id_param': postId,
            'user_id_param': userId,
          });
      return response as bool? ?? false;
    } catch (e) {
      // Fallback to direct query
      final response = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    }
  }

  /// Like a post
  static Future<bool> likePost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('post_likes')
          .insert({
            'post_id': postId,
            'user_id': userId,
          });

      return true;
    } catch (e) {
      // Might be duplicate (already liked), which is fine
      print('Error liking post: $e');
      return false;
    }
  }

  /// Unlike a post
  static Future<bool> unlikePost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }

  // ============================================
  // COMMENTS
  // ============================================

  /// Get comment count for a post
  static Future<int> getPostCommentCount(String postId) async {
    try {
      final response = await _supabase
          .rpc('get_post_comment_count', params: {'post_id_param': postId});
      return response as int? ?? 0;
    } catch (e) {
      // Fallback to direct query
      final response = await _supabase
          .from('post_comments')
          .select()
          .eq('post_id', postId);
      return (response as List).length;
    }
  }

  /// Get comments for a post
  static Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('''
            *,
            profiles!post_comments_user_id_fkey (
              id,
              user_id,
              first_name,
              last_name,
              display_name,
              avatar_path
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List).map((comment) {
        final profile = comment['profiles'] as Map<String, dynamic>?;
        final userIdField = profile?['user_id'] ?? 'user';
        // Get avatar URL from storage path
        final avatarPath = profile?['avatar_path'];
        final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
            ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
            : null;

        return {
          'id': comment['id'],
          'user_id': comment['user_id'],
          'username': userIdField, // Keep for backward compatibility
          'avatar': avatarUrl,
          'comment_text': comment['body'] ?? comment['comment_text'] ?? '', // Use 'body' from new schema
          'created_at': comment['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  /// Create a comment
  static Future<Map<String, dynamic>?> createComment({
    required String postId,
    required String commentText,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('post_comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'body': commentText, // Use 'body' field from new schema
          })
          .select('''
            *,
            profiles!post_comments_user_id_fkey (
              id,
              user_id,
              first_name,
              last_name,
              display_name,
              avatar_path
            )
          ''')
          .single();

      final profile = response['profiles'] as Map<String, dynamic>?;
      final userIdField = profile?['user_id'] ?? 'user';
      // Get avatar URL from storage path
      final avatarPath = profile?['avatar_path'];
      final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
          ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
          : null;

      return {
        'id': response['id'],
        'user_id': userId,
        'username': userIdField, // Keep for backward compatibility
        'avatar': avatarUrl,
        'comment_text': commentText,
        'created_at': response['created_at'],
      };
    } catch (e) {
      print('Error creating comment: $e');
      return null;
    }
  }

  /// Delete a comment
  static Future<bool> deleteComment(String commentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('post_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // ============================================
  // FOLLOWS
  // ============================================

  /// Get follower count for a user
  static Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_follower_count', params: {'user_id_param': userId});
      return response as int? ?? 0;
    } catch (e) {
      // Fallback to direct query
      final response = await _supabase
          .from('follows')
          .select()
          .eq('following_id', userId);
      return (response as List).length;
    }
  }

  /// Get following count for a user
  static Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_following_count', params: {'user_id_param': userId});
      return response as int? ?? 0;
    } catch (e) {
      // Fallback to direct query
      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', userId);
      return (response as List).length;
    }
  }

  /// Check if current user follows another user
  static Future<bool> isFollowing(String followingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .rpc('is_following', params: {
            'follower_id_param': userId,
            'following_id_param': followingId,
          });
      return response as bool? ?? false;
    } catch (e) {
      // Fallback to direct query
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      final response = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .eq('following_id', followingId)
          .maybeSingle();
      return response != null;
    }
  }

  /// Follow a user
  static Future<bool> followUser(String followingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      if (userId == followingId) return false; // Can't follow yourself

      await _supabase
          .from('follows')
          .insert({
            'follower_id': userId,
            'following_id': followingId,
          });

      return true;
    } catch (e) {
      // Might be duplicate (already following), which is fine
      print('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  static Future<bool> unfollowUser(String followingId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', userId)
          .eq('following_id', followingId);

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  /// Get followers list
  static Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('''
            follower_id,
            profiles!follows_follower_id_fkey (
              id,
              username,
              first_name,
              last_name,
              profile_photo_url
            )
          ''')
          .eq('following_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((follow) {
        final profile = follow['profiles'] as Map<String, dynamic>?;
        return {
          'id': profile?['id'],
          'username': profile?['username'] ?? 'user',
          'first_name': profile?['first_name'],
          'last_name': profile?['last_name'],
          'profile_photo_url': profile?['profile_photo_url'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching followers: $e');
      return [];
    }
  }

  /// Get following list
  static Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('''
            following_id,
            profiles!follows_following_id_fkey (
              id,
              username,
              first_name,
              last_name,
              profile_photo_url
            )
          ''')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((follow) {
        final profile = follow['profiles'] as Map<String, dynamic>?;
        return {
          'id': profile?['id'],
          'username': profile?['username'] ?? 'user',
          'first_name': profile?['first_name'],
          'last_name': profile?['last_name'],
          'profile_photo_url': profile?['profile_photo_url'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching following: $e');
      return [];
    }
  }
}


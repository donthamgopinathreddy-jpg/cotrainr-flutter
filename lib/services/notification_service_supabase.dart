import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationServiceSupabase {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch notifications from Supabase
  /// Combines notifications from various sources:
  /// - Follows (from follows table)
  /// - Likes (from post_likes table)
  /// - Comments (from post_comments table)
  /// - Messages (from messages table)
  /// - Quest completions (from user_quest_progress table)
  static Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final List<NotificationModel> notifications = [];

      // 1. Fetch recent follows (last 7 days)
      try {
        final follows = await _supabase
            .from('follows')
            .select('''
              follower_id,
              created_at,
              profiles!follows_follower_id_fkey (
                user_id,
                first_name,
                last_name,
                display_name,
                avatar_path
              )
            ''')
            .eq('following_id', userId)
            .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
            .order('created_at', ascending: false)
            .limit(10);

        for (final follow in follows) {
          final profile = follow['profiles'] as Map<String, dynamic>?;
          if (profile != null) {
            final followerId = follow['follower_id'] as String;
            final createdAt = DateTime.parse(follow['created_at'] as String);
            final displayName = profile['display_name'] ?? 
                '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
            final avatarPath = profile['avatar_path'] as String?;
            final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
                ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
                : null;

            notifications.add(NotificationModel(
              id: 'follow_$followerId',
              type: NotificationType.follow,
              title: 'New Follower',
              message: '$displayName started following you',
              userId: followerId,
              userName: displayName,
              userAvatar: avatarUrl,
              timestamp: createdAt,
              isRead: false,
            ));
          }
        }
      } catch (e) {
        print('Error fetching follows: $e');
      }

      // 2. Fetch recent likes on user's posts (last 7 days)
      try {
        final likes = await _supabase
            .from('post_likes')
            .select('''
              user_id,
              post_id,
              created_at,
              profiles!post_likes_user_id_fkey (
                user_id,
                first_name,
                last_name,
                display_name,
                avatar_path
              ),
              posts!post_likes_post_id_fkey (
                user_id
              )
            ''')
            .eq('posts.user_id', userId)
            .neq('post_likes.user_id', userId) // Don't notify for own likes
            .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
            .order('created_at', ascending: false)
            .limit(10);

        for (final like in likes) {
          final profile = like['profiles'] as Map<String, dynamic>?;
          if (profile != null) {
            final likerId = like['user_id'] as String;
            final createdAt = DateTime.parse(like['created_at'] as String);
            final displayName = profile['display_name'] ?? 
                '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
            final avatarPath = profile['avatar_path'] as String?;
            final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
                ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
                : null;

            notifications.add(NotificationModel(
              id: 'like_${like['post_id']}_$likerId',
              type: NotificationType.like,
              title: 'New Like',
              message: '$displayName liked your post',
              userId: likerId,
              userName: displayName,
              userAvatar: avatarUrl,
              timestamp: createdAt,
              isRead: false,
              data: {'postId': like['post_id']},
            ));
          }
        }
      } catch (e) {
        print('Error fetching likes: $e');
      }

      // 3. Fetch recent comments on user's posts (last 7 days)
      try {
        final comments = await _supabase
            .from('post_comments')
            .select('''
              id,
              user_id,
              post_id,
              body,
              created_at,
              profiles!post_comments_user_id_fkey (
                user_id,
                first_name,
                last_name,
                display_name,
                avatar_path
              ),
              posts!post_comments_post_id_fkey (
                user_id
              )
            ''')
            .eq('posts.user_id', userId)
            .neq('post_comments.user_id', userId) // Don't notify for own comments
            .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
            .order('created_at', ascending: false)
            .limit(10);

        for (final comment in comments) {
          final profile = comment['profiles'] as Map<String, dynamic>?;
          if (profile != null) {
            final commenterId = comment['user_id'] as String;
            final createdAt = DateTime.parse(comment['created_at'] as String);
            final displayName = profile['display_name'] ?? 
                '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
            final avatarPath = profile['avatar_path'] as String?;
            final avatarUrl = avatarPath != null && avatarPath.isNotEmpty
                ? _supabase.storage.from('avatars').getPublicUrl(avatarPath)
                : null;
            final body = comment['body'] as String? ?? '';

            notifications.add(NotificationModel(
              id: 'comment_${comment['id']}',
              type: NotificationType.comment,
              title: 'New Comment',
              message: '$displayName commented: ${body.length > 50 ? body.substring(0, 50) + "..." : body}',
              userId: commenterId,
              userName: displayName,
              userAvatar: avatarUrl,
              timestamp: createdAt,
              isRead: false,
              data: {'postId': comment['post_id'], 'commentId': comment['id']},
            ));
          }
        }
      } catch (e) {
        print('Error fetching comments: $e');
      }

      // 4. Fetch completed quests (last 7 days)
      try {
        final quests = await _supabase
            .from('user_quest_progress')
            .select('''
              quest_id,
              completed_at,
              quests (
                title,
                coins_reward
              )
            ''')
            .eq('user_id', userId)
            .not('completed_at', 'is', null)
            .gte('completed_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
            .order('completed_at', ascending: false)
            .limit(10);

        for (final quest in quests) {
          final questData = quest['quests'] as Map<String, dynamic>?;
          if (questData != null && quest['completed_at'] != null) {
            final completedAt = DateTime.parse(quest['completed_at'] as String);
            final title = questData['title'] as String? ?? 'Quest';
            final coins = questData['coins_reward'] as int? ?? 0;

            notifications.add(NotificationModel(
              id: 'quest_${quest['quest_id']}',
              type: NotificationType.questFinished,
              title: 'Quest Completed!',
              message: 'You completed "$title" and earned $coins coins!',
              timestamp: completedAt,
              isRead: false,
              data: {'questId': quest['quest_id'], 'coins': coins},
            ));
          }
        }
      } catch (e) {
        print('Error fetching quests: $e');
      }

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read (store in local state or Supabase if you add a read_status table)
  static Future<void> markAsRead(String notificationId) async {
    // For now, this is handled client-side
    // If you add a notifications table with read_status, update it here
    print('Marking notification as read: $notificationId');
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    // For now, this is handled client-side
    print('Marking all notifications as read');
  }
}












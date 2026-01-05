import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement_model.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class AchievementService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all available achievements
  static Future<List<AchievementModel>> getAchievements() async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('is_active', true)
          .order('created_at');

      return (response as List)
          .map((e) => AchievementModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [ACHIEVEMENTS] Error fetching achievements: $e');
      return [];
    }
  }

  /// Get user's unlocked achievements
  static Future<List<UserAchievementModel>> getUserAchievements() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((e) => UserAchievementModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [ACHIEVEMENTS] Error fetching user achievements: $e');
      return [];
    }
  }

  /// Check and unlock achievements based on user stats
  static Future<List<AchievementModel>> checkAndUnlockAchievements({
    int? steps,
    int? water,
    int? calories,
    int? streak,
    int? level,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final unlocked = <AchievementModel>[];

      // Get all active achievements
      final achievements = await getAchievements();

      // Get already unlocked achievements
      final userAchievements = await getUserAchievements();
      final unlockedIds = userAchievements.map((a) => a.achievementId).toSet();

      for (final achievement in achievements) {
        // Skip if already unlocked
        if (unlockedIds.contains(achievement.id)) continue;

        bool shouldUnlock = false;

        switch (achievement.type) {
          case AchievementType.steps:
            if (steps != null && steps >= achievement.targetValue) {
              shouldUnlock = true;
            }
            break;
          case AchievementType.water:
            if (water != null && water >= achievement.targetValue) {
              shouldUnlock = true;
            }
            break;
          case AchievementType.calories:
            if (calories != null && calories >= achievement.targetValue) {
              shouldUnlock = true;
            }
            break;
          case AchievementType.streak:
            if (streak != null && streak >= achievement.targetValue) {
              shouldUnlock = true;
            }
            break;
          case AchievementType.level:
            if (level != null && level >= achievement.targetValue) {
              shouldUnlock = true;
            }
            break;
          default:
            break;
        }

        if (shouldUnlock) {
          await unlockAchievement(achievement.id);
          unlocked.add(achievement);

          // Send notification
          final shouldNotify = await NotificationService.shouldSendNotificationType('achievement');
          if (shouldNotify) {
            await NotificationService().addNotification(
              NotificationModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: NotificationType.achievement,
                title: 'Achievement Unlocked! 🏆',
                message: achievement.title,
                timestamp: DateTime.now(),
                data: {'achievement_id': achievement.id},
              ),
            );
          }
        }
      }

      return unlocked;
    } catch (e) {
      print('❌ [ACHIEVEMENTS] Error checking achievements: $e');
      return [];
    }
  }

  /// Unlock an achievement for the current user
  static Future<bool> unlockAchievement(String achievementId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already unlocked
      final existing = await _supabase
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      if (existing != null) return true; // Already unlocked

      // Get achievement details for rewards
      final achievement = await _supabase
          .from('achievements')
          .select()
          .eq('id', achievementId)
          .maybeSingle();

      if (achievement == null) return false;

      // Unlock achievement
      await _supabase.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      });

      // Award XP and coins
      final xpReward = achievement['xp_reward'] as int? ?? 0;
      final coinsReward = achievement['coins_reward'] as int? ?? 0;

      if (xpReward > 0 || coinsReward > 0) {
        await _awardRewards(xpReward, coinsReward);
      }

      print('✅ [ACHIEVEMENTS] Unlocked achievement: $achievementId');
      return true;
    } catch (e) {
      print('❌ [ACHIEVEMENTS] Error unlocking achievement: $e');
      return false;
    }
  }

  /// Award XP and coins to user
  static Future<void> _awardRewards(int xp, int coins) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get or create user stats
      final stats = await _supabase
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (stats != null) {
        await _supabase
            .from('user_stats')
            .update({
              'total_xp': (stats['total_xp'] as int? ?? 0) + xp,
              'coins': (stats['coins'] as int? ?? 0) + coins,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        await _supabase.from('user_stats').insert({
          'user_id': userId,
          'total_xp': xp,
          'coins': coins,
          'level': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ [ACHIEVEMENTS] Error awarding rewards: $e');
    }
  }

  /// Get achievement progress for a specific achievement
  static Future<Map<String, dynamic>> getAchievementProgress(String achievementId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {'progress': 0, 'unlocked': false};

      final achievement = await _supabase
          .from('achievements')
          .select()
          .eq('id', achievementId)
          .maybeSingle();

      if (achievement == null) return {'progress': 0, 'unlocked': false};

      final isUnlocked = await _supabase
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle() != null;

      if (isUnlocked) {
        return {'progress': 100, 'unlocked': true};
      }

      // Calculate current progress based on achievement type
      int currentValue = 0;
      final targetValue = achievement['target_value'] as int? ?? 0;

      switch (achievement['type'] as String) {
        case 'steps':
          final stats = await _supabase
              .from('daily_stats')
              .select('steps')
              .eq('user_id', userId)
              .eq('stat_date', DateTime.now().toIso8601String().split('T')[0])
              .maybeSingle();
          currentValue = stats?['steps'] as int? ?? 0;
          break;
        case 'water':
          final stats = await _supabase
              .from('daily_stats')
              .select('water_ml')
              .eq('user_id', userId)
              .eq('stat_date', DateTime.now().toIso8601String().split('T')[0])
              .maybeSingle();
          currentValue = stats?['water_ml'] as int? ?? 0;
          break;
        // Add more cases as needed
      }

      final progress = targetValue > 0 ? ((currentValue / targetValue) * 100).clamp(0, 100).round() : 0;

      return {
        'progress': progress,
        'current': currentValue,
        'target': targetValue,
        'unlocked': false,
      };
    } catch (e) {
      print('❌ [ACHIEVEMENTS] Error getting progress: $e');
      return {'progress': 0, 'unlocked': false};
    }
  }
}









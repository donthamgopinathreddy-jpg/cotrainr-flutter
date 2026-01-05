import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

/// Service to handle quest operations with Supabase
class QuestService {
  static SupabaseClient get supabase => Supabase.instance.client;

  /// Get all available daily quests
  static Future<List<Map<String, dynamic>>> getDailyQuests() async {
    try {
      var query = supabase
          .from('quests')
          .select()
          .eq('is_active', true);

      // Filter by quest_type if column exists
      try {
        query = query.eq('quest_type', 'daily');
      } catch (e) {
        // Column might not exist yet, return all active quests
        print('⚠️ [QUESTS] quest_type column may not exist: $e');
      }

      final response = await query.order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [QUESTS] Error fetching daily quests: $e');
      return [];
    }
  }

  /// Get all available weekly quests
  static Future<List<Map<String, dynamic>>> getWeeklyQuests() async {
    try {
      var query = supabase
          .from('quests')
          .select()
          .eq('is_active', true);

      // Filter by quest_type if column exists
      try {
        query = query.eq('quest_type', 'weekly');
      } catch (e) {
        // Column might not exist yet, return all active quests
        print('⚠️ [QUESTS] quest_type column may not exist: $e');
      }

      final response = await query.order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [QUESTS] Error fetching weekly quests: $e');
      return [];
    }
  }

  /// Get user's quest progress for a specific quest
  static Future<Map<String, dynamic>?> getQuestProgress(String questId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('user_quest_progress')
          .select()
          .eq('user_id', userId)
          .eq('quest_id', questId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching quest progress: $e');
      return null;
    }
  }

  /// Get all quest progress for current user
  static Future<List<Map<String, dynamic>>> getUserQuestProgress() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await supabase
          .from('user_quest_progress')
          .select('*, quests(*)')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user quest progress: $e');
      return [];
    }
  }

  /// Update quest progress
  static Future<bool> updateQuestProgress({
    required String questId,
    required double progress,
    required double currentValue,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get quest details
      final quest = await supabase
          .from('quests')
          .select()
          .eq('id', questId)
          .maybeSingle();

      if (quest == null) return false;

      final targetValue = quest['target'] as int? ?? quest['target_value'] as int? ?? 0;
      final isCompleted = progress >= 1.0 || currentValue >= targetValue;
      final progressInt = (progress * 100).round().clamp(0, 100);

      // Check if progress exists
      final existing = await supabase
          .from('user_quest_progress')
          .select()
          .eq('user_id', userId)
          .eq('quest_id', questId)
          .maybeSingle();

      final wasCompleted = existing?['is_completed'] as bool? ?? false;

      final updateData = <String, dynamic>{
        'progress': progressInt,
        'current_value': currentValue.round(),
        'is_completed': isCompleted,
        if (isCompleted && !wasCompleted) 'completed_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // Update existing progress
        await supabase
            .from('user_quest_progress')
            .update(updateData)
            .eq('user_id', userId)
            .eq('quest_id', questId);
      } else {
        // Create new progress
        updateData['user_id'] = userId;
        updateData['quest_id'] = questId;
        await supabase.from('user_quest_progress').insert(updateData);
      }

      // Send notification if just completed
      if (isCompleted && !wasCompleted) {
        final shouldNotify = await NotificationService.shouldSendNotificationType('questfinished');
        if (shouldNotify) {
          await NotificationService().addNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: NotificationType.questFinished,
              title: 'Quest Completed! ✅',
              message: quest['title'] as String? ?? 'You completed a quest!',
              timestamp: DateTime.now(),
              data: {'quest_id': questId},
            ),
          );
        }
      }

      return true;
    } catch (e) {
      print('❌ [QUESTS] Error updating quest progress: $e');
      return false;
    }
  }

  /// Claim quest reward
  static Future<bool> claimQuestReward(String questId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get quest details
      final quest = await supabase
          .from('quests')
          .select()
          .eq('id', questId)
          .maybeSingle();

      if (quest == null) return false;

      // Get quest progress
      final progress = await getQuestProgress(questId);
      final isCompleted = progress?['is_completed'] as bool? ?? 
          ((progress?['progress'] as int? ?? 0) >= 100);
      final isClaimed = progress?['is_claimed'] as bool? ?? false;

      if (progress == null || !isCompleted) {
        return false; // Quest not completed
      }

      if (isClaimed) {
        return true; // Already claimed
      }

      // Mark as claimed
      await supabase
          .from('user_quest_progress')
          .update({'is_claimed': true})
          .eq('user_id', userId)
          .eq('quest_id', questId);

      // Award XP and coins to user
      final xpReward = quest['xp_reward'] as int? ?? 0;
      final coinsReward = quest['coins_reward'] as int? ?? 0;

      if (xpReward > 0 || coinsReward > 0) {
        // Get current user stats
        final userStats = await supabase
            .from('user_stats')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (userStats != null) {
          // Update existing stats
          await supabase
              .from('user_stats')
              .update({
                'total_xp': (userStats['total_xp'] as int? ?? 0) + xpReward,
                'coins': (userStats['coins'] as int? ?? 0) + coinsReward,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId);
        } else {
          // Create new stats
          await supabase.from('user_stats').insert({
            'user_id': userId,
            'total_xp': xpReward,
            'coins': coinsReward,
            'level': 1,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      return true;
    } catch (e) {
      print('Error claiming quest reward: $e');
      return false;
    }
  }

  /// Get user stats (XP, coins, level)
  static Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching user stats: $e');
      return null;
    }
  }

  /// Get leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await supabase
          .from('user_stats')
          .select('*, profiles(id, username, first_name, last_name, profile_photo_url)')
          .order('total_xp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Get competitions
  static Future<List<Map<String, dynamic>>> getCompetitions() async {
    try {
      final response = await supabase
          .from('competitions')
          .select()
          .eq('is_active', true)
          .eq('status', 'active')
          .order('end_date');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [QUESTS] Error fetching competitions: $e');
      return [];
    }
  }

  /// Sync quest progress with daily stats
  static Future<void> syncQuestProgressWithStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get today's stats
      final today = DateTime.now();
      final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final stats = await supabase
          .from('daily_stats')
          .select()
          .eq('user_id', userId)
          .eq('stat_date', todayDate)
          .maybeSingle();

      final steps = stats?['steps'] as int? ?? 0;
      final water = stats?['water_ml'] as int? ?? 0;
      final calories = stats?['calories_burned'] as int? ?? 0;

      // Get active quests
      final dailyQuests = await getDailyQuests();
      final weeklyQuests = await getWeeklyQuests();
      final allQuests = [...dailyQuests, ...weeklyQuests];

      // Update progress for each quest
      for (final quest in allQuests) {
        final questId = quest['id'] as String;
        final metric = quest['metric'] as String? ?? quest['type'] as String? ?? 'steps';
        final target = quest['target'] as int? ?? quest['target_value'] as int? ?? 0;

        int currentValue = 0;
        switch (metric) {
          case 'steps':
            currentValue = steps;
            break;
          case 'water':
            currentValue = water;
            break;
          case 'calories':
          case 'calories_burned':
            currentValue = calories;
            break;
          default:
            continue;
        }

        final progress = target > 0 ? (currentValue / target).clamp(0.0, 1.0) : 0.0;

        await updateQuestProgress(
          questId: questId,
          progress: progress,
          currentValue: currentValue.toDouble(),
        );
      }

      print('✅ [QUESTS] Synced quest progress with daily stats');
    } catch (e) {
      print('❌ [QUESTS] Error syncing quest progress: $e');
    }
  }

  /// Get user's competition participation
  static Future<Map<String, dynamic>?> getCompetitionParticipation(String competitionId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('competition_participants')
          .select()
          .eq('user_id', userId)
          .eq('competition_id', competitionId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching competition participation: $e');
      return null;
    }
  }
}


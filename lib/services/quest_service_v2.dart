import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

/// Quest Service V2 - Template-based rotation system
class QuestServiceV2 {
  static SupabaseClient get supabase => Supabase.instance.client;

  /// Ensure today's rotation exists (lazy generation)
  static Future<String?> ensureTodayRotation() async {
    try {
      final response = await supabase.rpc('create_today_rotation');
      return response as String?;
    } catch (e) {
      print('❌ [QUESTS_V2] Error creating today rotation: $e');
      return null;
    }
  }

  /// Ensure weekly rotation exists
  static Future<String?> ensureWeeklyRotation() async {
    try {
      final response = await supabase.rpc('create_weekly_rotation');
      return response as String?;
    } catch (e) {
      print('❌ [QUESTS_V2] Error creating weekly rotation: $e');
      return null;
    }
  }

  /// Get today's daily quests with user progress
  static Future<List<Map<String, dynamic>>> getTodayQuests() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Ensure rotation exists
      await ensureTodayRotation();

      final today = DateTime.now();
      final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get today's rotation
      final rotationResponse = await supabase
          .from('quest_rotations')
          .select()
          .eq('rotation_type', 'daily')
          .eq('starts_on', todayDate)
          .maybeSingle();

      if (rotationResponse == null) return [];

      final rotationId = rotationResponse['id'] as String;
      final questIds = List<String>.from(rotationResponse['quest_ids'] as List);

      // Get quest templates
      final templatesResponse = await supabase
          .from('quest_templates')
          .select()
          .in_('id', questIds);

      // Get user progress
      final progressResponse = await supabase
          .from('user_quest_progress')
          .select()
          .eq('user_id', userId)
          .eq('rotation_id', rotationId);

      // Create progress map
      final progressMap = <String, Map<String, dynamic>>{};
      for (var progress in progressResponse) {
        final templateId = progress['template_id'] as String;
        progressMap[templateId] = progress;
      }

      // Merge templates with progress
      final quests = <Map<String, dynamic>>[];
      for (var template in templatesResponse) {
        final templateId = template['id'] as String;
        final progress = progressMap[templateId];
        final targetValue = template['target_value'] as int;
        final progressValue = progress?['progress_value'] as int? ?? 0;
        final isCompleted = progress?['is_completed'] as bool? ?? false;
        final rewardClaimed = progress?['reward_claimed'] as bool? ?? false;

        quests.add({
          'id': templateId,
          'rotation_id': rotationId,
          'title': template['title'] as String? ?? '',
          'description': template['description'] as String? ?? '',
          'metric': template['metric'] as String? ?? '',
          'target_value': targetValue,
          'difficulty': template['difficulty'] as String? ?? '',
          'reward_coins': template['reward_coins'] as int? ?? 0,
          'reward_xp': template['reward_xp'] as int? ?? 0,
          'progress_value': progressValue,
          'progress': (progressValue / targetValue).clamp(0.0, 1.0),
          'is_completed': isCompleted,
          'reward_claimed': rewardClaimed,
          'completed_at': progress?['completed_at'],
        });
      }

      return quests;
    } catch (e) {
      print('❌ [QUESTS_V2] Error fetching today quests: $e');
      return [];
    }
  }

  /// Get weekly quests with user progress
  static Future<List<Map<String, dynamic>>> getWeeklyQuests() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Ensure rotation exists
      await ensureWeeklyRotation();

      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekStartDate = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      // Get this week's rotation
      final rotationResponse = await supabase
          .from('quest_rotations')
          .select()
          .eq('rotation_type', 'weekly')
          .eq('starts_on', weekStartDate)
          .maybeSingle();

      if (rotationResponse == null) return [];

      final rotationId = rotationResponse['id'] as String;
      final questIds = List<String>.from(rotationResponse['quest_ids'] as List);

      // Get quest templates
      final templatesResponse = await supabase
          .from('quest_templates')
          .select()
          .in_('id', questIds);

      // Get user progress
      final progressResponse = await supabase
          .from('user_quest_progress')
          .select()
          .eq('user_id', userId)
          .eq('rotation_id', rotationId);

      // Create progress map
      final progressMap = <String, Map<String, dynamic>>{};
      for (var progress in progressResponse) {
        final templateId = progress['template_id'] as String;
        progressMap[templateId] = progress;
      }

      // Merge templates with progress
      final quests = <Map<String, dynamic>>[];
      for (var template in templatesResponse) {
        final templateId = template['id'] as String;
        final progress = progressMap[templateId];
        final targetValue = template['target_value'] as int;
        final progressValue = progress?['progress_value'] as int? ?? 0;
        final isCompleted = progress?['is_completed'] as bool? ?? false;
        final rewardClaimed = progress?['reward_claimed'] as bool? ?? false;

        quests.add({
          'id': templateId,
          'rotation_id': rotationId,
          'title': template['title'] as String? ?? '',
          'description': template['description'] as String? ?? '',
          'metric': template['metric'] as String? ?? '',
          'target_value': targetValue,
          'difficulty': template['difficulty'] as String? ?? '',
          'reward_coins': template['reward_coins'] as int? ?? 0,
          'reward_xp': template['reward_xp'] as int? ?? 0,
          'progress_value': progressValue,
          'progress': (progressValue / targetValue).clamp(0.0, 1.0),
          'is_completed': isCompleted,
          'reward_claimed': rewardClaimed,
          'completed_at': progress?['completed_at'],
        });
      }

      return quests;
    } catch (e) {
      print('❌ [QUESTS_V2] Error fetching weekly quests: $e');
      return [];
    }
  }

  /// Claim quest reward
  static Future<bool> claimQuestReward(String templateId, String rotationId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get quest progress
      final progressResponse = await supabase
          .from('user_quest_progress')
          .select()
          .eq('user_id', userId)
          .eq('rotation_id', rotationId)
          .eq('template_id', templateId)
          .maybeSingle();

      if (progressResponse == null) return false;

      final isCompleted = progressResponse['is_completed'] as bool? ?? false;
      final rewardClaimed = progressResponse['reward_claimed'] as bool? ?? false;

      if (!isCompleted || rewardClaimed) {
        return false; // Not completed or already claimed
      }

      // Get template for rewards
      final templateResponse = await supabase
          .from('quest_templates')
          .select()
          .eq('id', templateId)
          .maybeSingle();

      if (templateResponse == null) return false;

      final coinsReward = templateResponse['reward_coins'] as int? ?? 0;
      final xpReward = templateResponse['reward_xp'] as int? ?? 0;

      // Mark as claimed
      await supabase
          .from('user_quest_progress')
          .update({'reward_claimed': true})
          .eq('user_id', userId)
          .eq('rotation_id', rotationId)
          .eq('template_id', templateId);

      // Create rewards event
      await supabase.from('rewards_events').insert({
        'user_id': userId,
        'source': 'quest',
        'template_id': templateId,
        'rotation_id': rotationId,
        'coins': coinsReward,
        'xp': xpReward,
      });

      // Update user stats
      final userStatsResponse = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (userStatsResponse != null) {
        final currentCoins = userStatsResponse['coins'] as int? ?? 0;
        final currentXP = userStatsResponse['total_xp'] as int? ?? 0;

        await supabase
            .from('user_stats')
            .update({
              'coins': currentCoins + coinsReward,
              'total_xp': currentXP + xpReward,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);

        // Check for level up
        await _checkLevelUp(userId, currentXP + xpReward);
      } else {
        // Create new stats
        await supabase.from('user_stats').insert({
          'user_id': userId,
          'coins': coinsReward,
          'total_xp': xpReward,
          'level': 1,
        });
      }

      return true;
    } catch (e) {
      print('❌ [QUESTS_V2] Error claiming quest reward: $e');
      return false;
    }
  }

  /// Check and update user level based on XP
  static Future<void> _checkLevelUp(String userId, int totalXP) async {
    try {
      // Calculate level from XP (formula: 250 + (N × 90) per level)
      int level = 1;
      int cumulativeXP = 0;

      while (level < 50) {
        final xpForNextLevel = 250 + (level * 90);
        if (cumulativeXP + xpForNextLevel > totalXP) {
          break;
        }
        cumulativeXP += xpForNextLevel;
        level++;
      }

      // Update level if changed
      final currentStats = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (currentStats != null) {
        final currentLevel = currentStats['level'] as int? ?? 1;
        if (level > currentLevel) {
          await supabase
              .from('user_stats')
              .update({'level': level})
              .eq('user_id', userId);

          // Send level up notification
          final shouldNotify = await NotificationService.shouldSendNotificationType('levelup');
          if (shouldNotify) {
            await NotificationService().addNotification(
              NotificationModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: NotificationType.levelUp,
                title: 'Level Up! 🎉',
                message: 'You reached level $level!',
                timestamp: DateTime.now(),
                data: {'level': level},
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ [QUESTS_V2] Error checking level up: $e');
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
      print('❌ [QUESTS_V2] Error fetching user stats: $e');
      return null;
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
      print('❌ [QUESTS_V2] Error fetching competitions: $e');
      return [];
    }
  }

  /// Get competition leaderboard
  static Future<List<Map<String, dynamic>>> getCompetitionLeaderboard(String competitionId) async {
    try {
      final response = await supabase
          .from('competition_scores')
          .select('*, profiles(id, username, first_name, last_name, profile_photo_url)')
          .eq('competition_id', competitionId)
          .order('rank', ascending: true)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [QUESTS_V2] Error fetching competition leaderboard: $e');
      return [];
    }
  }

  /// Get user's competition participation
  static Future<Map<String, dynamic>?> getCompetitionParticipation(String competitionId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('competition_scores')
          .select()
          .eq('user_id', userId)
          .eq('competition_id', competitionId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ [QUESTS_V2] Error fetching competition participation: $e');
      return null;
    }
  }

  /// Join a competition
  static Future<bool> joinCompetition(String competitionId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already joined
      final existing = await getCompetitionParticipation(competitionId);
      if (existing != null) return true;

      // Get competition
      final competition = await supabase
          .from('competitions')
          .select()
          .eq('id', competitionId)
          .maybeSingle();

      if (competition == null) return false;

      // Initialize score based on metric
      int initialScore = 0;
      final metric = competition['metric'] as String? ?? 'steps';

      // Get current value based on metric
      final today = DateTime.now();
      final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (metric == 'steps' || metric == 'water_ml' || metric == 'calories_burned') {
        final stats = await supabase
            .from('daily_stats')
            .select()
            .eq('user_id', userId)
            .eq('stat_date', todayDate)
            .maybeSingle();

        if (stats != null) {
          initialScore = stats[metric] as int? ?? 0;
        }
      }

      // Insert competition score
      await supabase.from('competition_scores').insert({
        'competition_id': competitionId,
        'user_id': userId,
        'score': initialScore,
        'rank': 0,
        'percentile': 0.0,
      });

      // Update competition participant count
      final currentParticipants = competition['current_participants'] as int? ?? 0;
      await supabase
          .from('competitions')
          .update({'current_participants': currentParticipants + 1})
          .eq('id', competitionId);

      return true;
    } catch (e) {
      print('❌ [QUESTS_V2] Error joining competition: $e');
      return false;
    }
  }
}




import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal_model.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';
import 'daily_stats_service.dart';

class GoalService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new goal
  static Future<GoalModel?> createGoal({
    required GoalType type,
    required GoalPeriod period,
    required int targetValue,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (period) {
        case GoalPeriod.daily:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = startDate.add(const Duration(days: 1));
          break;
        case GoalPeriod.weekly:
          final weekday = now.weekday;
          startDate = now.subtract(Duration(days: weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = startDate.add(const Duration(days: 7));
          break;
        case GoalPeriod.monthly:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
      }

      final response = await _supabase
          .from('goals')
          .insert({
            'user_id': userId,
            'type': type.toString().split('.').last,
            'period': period.toString().split('.').last,
            'target_value': targetValue,
            'current_value': 0,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'is_active': true,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      return GoalModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('❌ [GOALS] Error creating goal: $e');
      return null;
    }
  }

  /// Get user's active goals
  static Future<List<GoalModel>> getUserGoals({bool activeOnly = true}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from('goals')
          .select()
          .eq('user_id', userId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((e) => GoalModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('❌ [GOALS] Error fetching goals: $e');
      return [];
    }
  }

  /// Update goal progress
  static Future<bool> updateGoalProgress(String goalId, int newValue) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final goal = await _supabase
          .from('goals')
          .select()
          .eq('id', goalId)
          .eq('user_id', userId)
          .maybeSingle();

      if (goal == null) return false;

      final targetValue = goal['target_value'] as int;
      final isCompleted = newValue >= targetValue;
      final wasCompleted = goal['completed_at'] != null;

      await _supabase
          .from('goals')
          .update({
            'current_value': newValue,
            'completed_at': isCompleted && !wasCompleted
                ? DateTime.now().toIso8601String()
                : goal['completed_at'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', goalId);

      // Send notification if just completed
      if (isCompleted && !wasCompleted) {
        final shouldNotify = await NotificationService.shouldSendNotificationType('goalachieved');
        if (shouldNotify) {
          await NotificationService().addNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: NotificationType.goalAchieved,
              title: 'Goal Achieved! 🎯',
              message: 'You completed your ${goal['type']} goal!',
              timestamp: DateTime.now(),
              data: {'goal_id': goalId},
            ),
          );
        }
      }

      return true;
    } catch (e) {
      print('❌ [GOALS] Error updating goal progress: $e');
      return false;
    }
  }

  /// Sync goals with daily stats
  static Future<void> syncGoalsWithStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final goals = await getUserGoals(activeOnly: true);
      final todayStats = await DailyStatsService.getTodayStats();

      for (final goal in goals) {
        int newValue = goal.currentValue;

        switch (goal.type) {
          case GoalType.steps:
            newValue = todayStats['steps'] as int? ?? 0;
            break;
          case GoalType.water:
            newValue = todayStats['water_ml'] as int? ?? 0;
            break;
          case GoalType.calories:
            newValue = todayStats['calories_burned'] as int? ?? 0;
            break;
          default:
            continue;
        }

        if (newValue != goal.currentValue) {
          await updateGoalProgress(goal.id, newValue);
        }
      }
    } catch (e) {
      print('❌ [GOALS] Error syncing goals: $e');
    }
  }

  /// Delete a goal
  static Future<bool> deleteGoal(String goalId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('goals')
          .update({'is_active': false})
          .eq('id', goalId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('❌ [GOALS] Error deleting goal: $e');
      return false;
    }
  }

  /// Get goal statistics
  static Future<Map<String, dynamic>> getGoalStats() async {
    try {
      final goals = await getUserGoals(activeOnly: false);
      final activeGoals = goals.where((g) => g.isActive).length;
      final completedGoals = goals.where((g) => g.isCompleted).length;
      final totalGoals = goals.length;

      return {
        'total': totalGoals,
        'active': activeGoals,
        'completed': completedGoals,
        'completion_rate': totalGoals > 0 ? (completedGoals / totalGoals) : 0.0,
      };
    } catch (e) {
      print('❌ [GOALS] Error getting stats: $e');
      return {'total': 0, 'active': 0, 'completed': 0, 'completion_rate': 0.0};
    }
  }
}


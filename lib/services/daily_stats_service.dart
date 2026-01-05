import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStatsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get today's stats for the current user
  static Future<Map<String, dynamic>> getTodayStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'steps': 0,
          'calories_burned': 0,
          'water_ml': 0,
        };
      }

      final today = DateTime.now();
      final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_stats')
          .select()
          .eq('user_id', userId)
          .eq('stat_date', todayDate)
          .maybeSingle();

      if (response != null) {
        return {
          'steps': response['steps'] as int? ?? 0,
          'calories_burned': response['calories_burned'] as int? ?? 0,
          'water_ml': response['water_ml'] as int? ?? 0,
        };
      }

      return {
        'steps': 0,
        'calories_burned': 0,
        'water_ml': 0,
      };
    } catch (e) {
      print('❌ [DAILY_STATS] Error fetching today stats: $e');
      return {
        'steps': 0,
        'calories_burned': 0,
        'water_ml': 0,
      };
    }
  }

  /// Get weekly stats for the current user (last 7 days)
  static Future<List<Map<String, dynamic>>> getWeeklyStats(String type) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: 6));
      
      // Generate list of dates for the last 7 days
      final dates = <String>[];
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        dates.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
      }

      // Fetch stats for each date individually (Supabase doesn't have in_ for arrays)
      final List<Map<String, dynamic>> allStats = [];
      for (final date in dates) {
        try {
          final response = await _supabase
              .from('daily_stats')
              .select()
              .eq('user_id', userId)
              .eq('stat_date', date)
              .maybeSingle();
          
          if (response != null) {
            allStats.add(Map<String, dynamic>.from(response));
          }
        } catch (e) {
          print('Error fetching stats for date $date: $e');
        }
      }

      // Create a map of date -> stats
      final statsMap = <String, Map<String, dynamic>>{};
      for (final row in allStats) {
        final date = row['stat_date'] as String;
        statsMap[date] = row;
      }

      // Build list with all 7 days, filling missing days with 0
      final weeklyData = <Map<String, dynamic>>[];
      for (final date in dates) {
        if (statsMap.containsKey(date)) {
          final stat = statsMap[date]!;
          weeklyData.add({
            'date': date,
            'steps': stat['steps'] as int? ?? 0,
            'calories_burned': stat['calories_burned'] as int? ?? 0,
            'water_ml': stat['water_ml'] as int? ?? 0,
          });
        } else {
          weeklyData.add({
            'date': date,
            'steps': 0,
            'calories_burned': 0,
            'water_ml': 0,
          });
        }
      }

      return weeklyData;
    } catch (e) {
      print('❌ [DAILY_STATS] Error fetching weekly stats: $e');
      return [];
    }
  }

  /// Update today's stats (upsert)
  static Future<void> updateTodayStats({
    int? steps,
    int? caloriesBurned,
    int? waterMl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get current stats first
      final current = await getTodayStats();

      final updateData = <String, dynamic>{
        'user_id': userId,
        'stat_date': todayDate,
        'steps': steps ?? current['steps'],
        'calories_burned': caloriesBurned ?? current['calories_burned'],
        'water_ml': waterMl ?? current['water_ml'],
      };

      await _supabase
          .from('daily_stats')
          .upsert(updateData, onConflict: 'user_id,stat_date')
          .select();

      print('✅ [DAILY_STATS] Updated today stats: $updateData');
    } catch (e) {
      print('❌ [DAILY_STATS] Error updating today stats: $e');
      rethrow;
    }
  }

  /// Add water (increment)
  static Future<void> addWater(int ml) async {
    try {
      final current = await getTodayStats();
      final newWater = (current['water_ml'] as int) + ml;

      await updateTodayStats(waterMl: newWater);
    } catch (e) {
      print('❌ [DAILY_STATS] Error adding water: $e');
      rethrow;
    }
  }

  /// Calculate calories burned from steps
  /// Formula: approximately 0.04-0.05 calories per step
  /// Average: ~100 calories per 2000 steps
  static int calculateCaloriesFromSteps(int steps) {
    // Using 0.045 calories per step (middle of 0.04-0.05 range)
    return (steps * 0.045).round();
  }

  /// Calculate recommended daily water intake based on body weight
  /// Formula: 30-35ml per kg of body weight
  /// Using 33ml per kg as average
  static int calculateRecommendedWater(double weightKg) {
    if (weightKg <= 0) return 2000; // Default 2L if weight not available
    return (weightKg * 33).round();
  }

  /// Update steps and auto-calculate calories
  static Future<void> updateSteps(int steps) async {
    try {
      final calories = calculateCaloriesFromSteps(steps);
      await updateTodayStats(steps: steps, caloriesBurned: calories);
      print('✅ [DAILY_STATS] Updated steps: $steps, calculated calories: $calories');
    } catch (e) {
      print('❌ [DAILY_STATS] Error updating steps: $e');
      rethrow;
    }
  }
}


import 'package:supabase_flutter/supabase_flutter.dart';

class StreakService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Record a daily login for the current user
  /// This should be called when user logs in or opens the app
  /// Uses daily_stats table to track logins (if a record exists for today, user logged in)
  static Future<void> recordLogin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Check if today's record exists
      final existing = await _supabase
          .from('daily_stats')
          .select()
          .eq('user_id', userId)
          .eq('stat_date', todayDate)
          .maybeSingle();

      // If no record exists, create one (this marks the login)
      if (existing == null) {
        await _supabase
            .from('daily_stats')
            .insert({
              'user_id': userId,
              'stat_date': todayDate,
              'steps': 0,
              'calories_burned': 0,
              'water_ml': 0,
            });
        print('✅ [STREAK] Recorded login for today');
      }
    } catch (e) {
      print('❌ [STREAK] Error recording login: $e');
    }
  }

  /// Get current streak (consecutive days ending today)
  /// Calculates based on daily_stats records
  static Future<int> getCurrentStreak() async {
    try {
      return await _calculateStreakManually();
    } catch (e) {
      print('❌ [STREAK] Error getting current streak: $e');
      return 0;
    }
  }

  /// Get total number of days user has logged in
  static Future<int> getTotalLoginDays() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('daily_stats')
          .select('stat_date')
          .eq('user_id', userId);

      final dates = (response as List).map((r) => r['stat_date'] as String).toSet();
      return dates.length;
    } catch (e) {
      print('❌ [STREAK] Error getting total login count: $e');
      return 0;
    }
  }

  /// Get longest streak ever achieved
  static Future<int> getLongestStreak() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('daily_stats')
          .select('stat_date')
          .eq('user_id', userId)
          .order('stat_date', ascending: true);

      if ((response as List).isEmpty) return 0;

      final dates = (response as List)
          .map((r) => DateTime.parse(r['stat_date'] as String))
          .toList()
        ..sort();

      int longestStreak = 0;
      int currentStreak = 1;

      for (int i = 1; i < dates.length; i++) {
        final prevDate = dates[i - 1];
        final currDate = dates[i];
        final diff = currDate.difference(prevDate).inDays;

        if (diff == 1) {
          currentStreak++;
        } else {
          longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
          currentStreak = 1;
        }
      }

      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      return longestStreak;
    } catch (e) {
      print('❌ [STREAK] Error getting longest streak: $e');
      return 0;
    }
  }

  /// Manual streak calculation using daily_stats
  static Future<int> _calculateStreakManually() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get last 30 days of stats to calculate streak
      final today = DateTime.now();
      final thirtyDaysAgo = today.subtract(const Duration(days: 30));
      final startDate = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('daily_stats')
          .select('stat_date')
          .eq('user_id', userId)
          .gte('stat_date', startDate)
          .order('stat_date', ascending: false);

      if ((response as List).isEmpty) return 0;

      final dates = (response as List)
          .map((r) => DateTime.parse(r['stat_date'] as String))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending

      // Check if today is in the list
      final todayDate = DateTime(today.year, today.month, today.day);
      
      if (!dates.any((d) => 
          d.year == todayDate.year && 
          d.month == todayDate.month && 
          d.day == todayDate.day)) {
        return 0; // No login today
      }

      // Count consecutive days backwards from today
      int streak = 0;
      DateTime checkDate = todayDate;
      
      while (true) {
        final hasLogin = dates.any((d) => 
            d.year == checkDate.year && 
            d.month == checkDate.month && 
            d.day == checkDate.day);
        
        if (hasLogin) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('❌ [STREAK] Error in manual streak calculation: $e');
      return 0;
    }
  }

  /// Get login dates for the last N days (for visualization)
  static Future<List<DateTime>> getRecentLoginDates({int days = 7}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('daily_stats')
          .select('stat_date')
          .eq('user_id', userId)
          .order('stat_date', ascending: false)
          .limit(days);

      return (response as List)
          .map((r) => DateTime.parse(r['stat_date'] as String))
          .toList();
    } catch (e) {
      print('❌ [STREAK] Error getting recent login dates: $e');
      return [];
    }
  }
}








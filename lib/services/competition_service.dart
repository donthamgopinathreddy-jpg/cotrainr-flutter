import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/competition_model.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';

class CompetitionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all active competitions
  static Future<List<CompetitionModel>> getActiveCompetitions() async {
    try {
      final response = await _supabase
          .from('competitions')
          .select()
          .eq('is_active', true)
          .eq('status', 'active')
          .order('end_date');

      return (response as List)
          .map((e) => CompetitionModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('❌ [COMPETITIONS] Error fetching competitions: $e');
      return [];
    }
  }

  /// Get competition details
  static Future<CompetitionModel?> getCompetition(String competitionId) async {
    try {
      final response = await _supabase
          .from('competitions')
          .select()
          .eq('id', competitionId)
          .maybeSingle();

      if (response == null) return null;

      return CompetitionModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      print('❌ [COMPETITIONS] Error fetching competition: $e');
      return null;
    }
  }

  /// Join a competition
  static Future<bool> joinCompetition(String competitionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final competition = await getCompetition(competitionId);
      if (competition == null || !competition.canJoin) return false;

      // Check if already joined
      final existing = await _supabase
          .from('competition_participants')
          .select()
          .eq('user_id', userId)
          .eq('competition_id', competitionId)
          .maybeSingle();

      if (existing != null) return true; // Already joined

      // Join competition
      await _supabase.from('competition_participants').insert({
        'competition_id': competitionId,
        'user_id': userId,
        'score': 0,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Update participant count
      await _supabase
          .from('competitions')
          .update({
            'current_participants': competition.currentParticipants + 1,
          })
          .eq('id', competitionId);

      // Send notification
      final shouldNotify = await NotificationService.shouldSendNotificationType('socialchallenge');
      if (shouldNotify) {
        await NotificationService().addNotification(
          NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: NotificationType.socialChallenge,
            title: 'Competition Joined! 🏆',
            message: 'You joined ${competition.title}',
            timestamp: DateTime.now(),
            data: {'competition_id': competitionId},
          ),
        );
      }

      print('✅ [COMPETITIONS] Joined competition: $competitionId');
      return true;
    } catch (e) {
      print('❌ [COMPETITIONS] Error joining competition: $e');
      return false;
    }
  }

  /// Get user's competition participation
  static Future<CompetitionParticipantModel?> getParticipation(String competitionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('competition_participants')
          .select()
          .eq('user_id', userId)
          .eq('competition_id', competitionId)
          .maybeSingle();

      if (response == null) return null;

      return CompetitionParticipantModel.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ [COMPETITIONS] Error fetching participation: $e');
      return null;
    }
  }

  /// Update competition score
  static Future<bool> updateScore(String competitionId, int score) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('competition_participants')
          .update({
            'score': score,
            'last_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('competition_id', competitionId);

      // Update rankings
      await _updateRankings(competitionId);

      return true;
    } catch (e) {
      print('❌ [COMPETITIONS] Error updating score: $e');
      return false;
    }
  }

  /// Update participant rankings
  static Future<void> _updateRankings(String competitionId) async {
    try {
      // Get all participants ordered by score
      final participants = await _supabase
          .from('competition_participants')
          .select()
          .eq('competition_id', competitionId)
          .order('score', ascending: false);

      // Update ranks
      for (int i = 0; i < (participants as List).length; i++) {
        final participant = participants[i] as Map<String, dynamic>;
        await _supabase
            .from('competition_participants')
            .update({'rank': i + 1})
            .eq('id', participant['id']);
      }
    } catch (e) {
      print('❌ [COMPETITIONS] Error updating rankings: $e');
    }
  }

  /// Get competition leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard(String competitionId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('competition_participants')
          .select('*, profiles(id, username, first_name, last_name, display_name, avatar_path)')
          .eq('competition_id', competitionId)
          .order('rank')
          .limit(limit);

      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ [COMPETITIONS] Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Sync competition scores with daily stats
  static Future<void> syncCompetitionScores() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get user's active competitions
      final competitions = await _supabase
          .from('competition_participants')
          .select('competitions(*)')
          .eq('user_id', userId);

      for (final participation in competitions as List) {
        final competition = CompetitionModel.fromMap(
          Map<String, dynamic>.from(participation['competitions']),
        );

        if (competition.status != CompetitionStatus.active) continue;

        // Get today's stats
        final todayStats = await _supabase
            .from('daily_stats')
            .select()
            .eq('user_id', userId)
            .eq('stat_date', DateTime.now().toIso8601String().split('T')[0])
            .maybeSingle();

        int score = 0;

        switch (competition.type) {
          case CompetitionType.steps:
            score = todayStats?['steps'] as int? ?? 0;
            break;
          case CompetitionType.water:
            score = todayStats?['water_ml'] as int? ?? 0;
            break;
          case CompetitionType.calories:
            score = todayStats?['calories_burned'] as int? ?? 0;
            break;
          case CompetitionType.overall:
            // Calculate overall score
            final steps = todayStats?['steps'] as int? ?? 0;
            final water = todayStats?['water_ml'] as int? ?? 0;
            final calories = todayStats?['calories_burned'] as int? ?? 0;
            score = (steps ~/ 100) + (water ~/ 100) + calories;
            break;
          default:
            break;
        }

        await updateScore(competition.id, score);
      }
    } catch (e) {
      print('❌ [COMPETITIONS] Error syncing scores: $e');
    }
  }
}


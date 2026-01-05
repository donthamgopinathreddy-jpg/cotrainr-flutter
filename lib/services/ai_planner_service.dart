import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle AI Planner requests through Supabase Edge Functions
/// This ensures API keys are secure and all AI calls go through the backend
class AiPlannerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate a meal plan via Supabase Edge Function
  /// 
  /// The Edge Function will:
  /// 1. Check user subscription and rate limits
  /// 2. Fetch user profile data (age, gender, height, weight, BMI)
  /// 3. Call OpenAI API with structured prompt
  /// 4. Save the generated plan to Supabase
  /// 5. Return the plan data
  /// 
  /// Parameters:
  /// - goal: 'fat_loss', 'muscle_gain', 'endurance', 'boxing', 'general'
  /// - daysPerWeek: 3-6
  /// - timePerSession: 20-90 minutes
  /// - dietPreference: 'Veg', 'Non-Veg', 'Eggetarian'
  /// - allergens: List of allergens to avoid
  /// - mealsPerDay: 2-6
  Future<Map<String, dynamic>> generateMealPlan({
    required String goal,
    required int daysPerWeek,
    required int timePerSession,
    required String dietPreference,
    List<String> allergens = const [],
    required int mealsPerDay,
  }) async {
    try {
      // Call Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'generate-meal-plan',
        body: {
          'goal': goal,
          'days_per_week': daysPerWeek,
          'time_per_session': timePerSession,
          'diet_preference': dietPreference,
          'allergens': allergens,
          'meals_per_day': mealsPerDay,
        },
      );

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          response.data?['error'] ?? 'Failed to generate meal plan',
        );
      }
    } catch (e) {
      // Handle errors (network, rate limit, subscription, etc.)
      rethrow;
    }
  }

  /// Generate a workout plan via Supabase Edge Function
  /// 
  /// The Edge Function will:
  /// 1. Check user subscription (must be PREMIUM)
  /// 2. Check rate limits
  /// 3. Fetch user profile data
  /// 4. Call OpenAI API with structured prompt
  /// 5. Save the generated plan to Supabase
  /// 6. Return the plan data
  /// 
  /// Parameters:
  /// - goal: 'fat_loss', 'muscle_gain', 'endurance', 'boxing', 'general'
  /// - daysPerWeek: 3-6
  /// - timePerSession: 20-90 minutes
  /// - equipment: List of available equipment ('Gym', 'Home', 'Bodyweight')
  Future<Map<String, dynamic>> generateWorkoutPlan({
    required String goal,
    required int daysPerWeek,
    required int timePerSession,
    required List<String> equipment,
  }) async {
    try {
      // Call Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'generate-workout-plan',
        body: {
          'goal': goal,
          'days_per_week': daysPerWeek,
          'time_per_session': timePerSession,
          'equipment': equipment,
        },
      );

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          response.data?['error'] ?? 'Failed to generate workout plan',
        );
      }
    } catch (e) {
      // Handle errors (network, rate limit, subscription, etc.)
      rethrow;
    }
  }

  /// Share a plan with a trainer
  /// 
  /// This will:
  /// 1. Create a message in the chat with the plan link
  /// 2. Log shared_with_trainer_id in the plan record
  /// 3. Notify the trainer
  Future<void> sharePlanWithTrainer({
    required String planId,
    required String trainerId,
  }) async {
    try {
      // Create message with plan link
      await _supabase.from('messages').insert({
        'sender_id': _supabase.auth.currentUser?.id,
        'receiver_id': trainerId,
        'message': 'I\'d like to share my AI-generated plan with you: $planId',
        'plan_id': planId,
        'type': 'plan_share',
      });

      // Update plan record with shared_with_trainer_id
      await _supabase.from('ai_plans').update({
        'shared_with_trainer_id': trainerId,
        'shared_at': DateTime.now().toIso8601String(),
      }).eq('id', planId);

      // TODO: Send notification to trainer
    } catch (e) {
      rethrow;
    }
  }

  /// Get plan history for the current user
  Future<List<Map<String, dynamic>>> getPlanHistory({
    String? planType, // 'meal' or 'workout'
  }) async {
    try {
      var query = _supabase
          .from('ai_plans')
          .select()
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');

      if (planType != null) {
        query = query.eq('plan_type', planType);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}


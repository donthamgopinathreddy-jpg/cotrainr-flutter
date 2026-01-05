import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user subscription plan
/// TODO: Integrate with Supabase to sync subscription status
class SubscriptionService {
  static const String _planKey = 'user_subscription_plan';

  /// Get current user subscription plan
  /// Returns: 'FREE', 'BASIC', or 'PREMIUM'
  static Future<String> getUserPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_planKey) ?? 'FREE';
    } catch (e) {
      return 'FREE'; // Default to FREE on error
    }
  }

  /// Set user subscription plan
  /// TODO: Sync with Supabase after setting locally
  static Future<void> setUserPlan(String plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_planKey, plan);
    } catch (e) {
      // Handle error silently or log
    }
  }

  /// Check if user has access to AI Meal Planner
  static Future<bool> hasMealPlannerAccess() async {
    final plan = await getUserPlan();
    return plan == 'BASIC' || plan == 'PREMIUM';
  }

  /// Check if user has access to AI Workout Planner
  static Future<bool> hasWorkoutPlannerAccess() async {
    final plan = await getUserPlan();
    return plan == 'PREMIUM';
  }

  /// Check if feature is available for current plan
  static Future<bool> hasFeatureAccess(String feature) async {
    final plan = await getUserPlan();
    switch (feature) {
      case 'meal_planner':
        return plan == 'BASIC' || plan == 'PREMIUM';
      case 'workout_planner':
        return plan == 'PREMIUM';
      default:
        return false;
    }
  }
}


















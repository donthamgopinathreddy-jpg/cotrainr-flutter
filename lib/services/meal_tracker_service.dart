import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Meal Tracker Service - Handles all meal tracking operations
class MealTrackerService {
  static SupabaseClient get supabase => Supabase.instance.client;

  /// Get today's meal day data
  static Future<Map<String, dynamic>?> getTodayMealDay() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from('meal_days')
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching today meal day: $e');
      return null;
    }
  }

  /// Get meal day for a specific date
  static Future<Map<String, dynamic>?> getMealDay(DateTime date) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from('meal_days')
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching meal day: $e');
      return null;
    }
  }

  /// Get meal items for a specific date and meal type
  static Future<List<Map<String, dynamic>>> getMealItems({
    required DateTime date,
    String? mealType,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final queryBuilder = supabase
          .from('meal_items')
          .select('*, foods_catalog(*)')
          .eq('user_id', userId)
          .eq('date', dateStr);

      if (mealType != null) {
        queryBuilder.eq('meal_type', mealType);
      }

      final response = await queryBuilder.order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching meal items: $e');
      return [];
    }
  }

  /// Add meal item
  static Future<bool> addMealItem({
    required DateTime date,
    required String mealType,
    required String foodId,
    required double quantity,
    required String unit,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get food details
      final food = await supabase
          .from('foods_catalog')
          .select()
          .eq('id', foodId)
          .maybeSingle();

      if (food == null) return false;

      // Calculate nutrition values
      final perUnitGrams = food['per_unit_grams'] as double;
      final totalGrams = quantity * perUnitGrams;
      final multiplier = totalGrams / 100.0;

      final kcal = (food['kcal_per_100g'] as num) * multiplier;
      final protein = (food['protein_per_100g'] as num) * multiplier;
      final carbs = (food['carbs_per_100g'] as num) * multiplier;
      final fat = (food['fat_per_100g'] as num) * multiplier;
      final fiber = ((food['fiber_per_100g'] as num?) ?? 0) * multiplier;
      final sugar = ((food['sugar_per_100g'] as num?) ?? 0) * multiplier;
      final sodium = ((food['sodium_per_100g'] as num?) ?? 0) * multiplier;
      final iron = ((food['iron_per_100g'] as num?) ?? 0) * multiplier;
      final calcium = ((food['calcium_per_100g'] as num?) ?? 0) * multiplier;
      final potassium = ((food['potassium_per_100g'] as num?) ?? 0) * multiplier;

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Insert meal item (trigger will update meal_days totals)
      await supabase.from('meal_items').insert({
        'user_id': userId,
        'date': dateStr,
        'meal_type': mealType,
        'food_id': foodId,
        'quantity': quantity,
        'unit': unit,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'iron': iron,
        'calcium': calcium,
        'potassium': potassium,
      });

      print('✅ [MEAL_TRACKER] Added meal item: ${food['name']}');
      return true;
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error adding meal item: $e');
      return false;
    }
  }

  /// Delete meal item
  static Future<bool> deleteMealItem(String itemId) async {
    try {
      await supabase
          .from('meal_items')
          .delete()
          .eq('id', itemId);

      print('✅ [MEAL_TRACKER] Deleted meal item');
      return true;
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error deleting meal item: $e');
      return false;
    }
  }

  /// Search foods (only with micronutrients)
  static Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    try {
      if (query.isEmpty) {
        return await getFoodsByTags([]);
      }

      // Simple search - only foods with micronutrients
      final response = await supabase
          .from('foods_catalog')
          .select()
          .eq('is_verified', true)
          .not('micros_json', 'is', null) // Only foods with micronutrients
          .ilike('name', '%$query%')
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error searching foods: $e');
      return [];
    }
  }

  /// Get foods by tags (only with micronutrients)
  static Future<List<Map<String, dynamic>>> getFoodsByTags(List<String> tags) async {
    try {
      final queryBuilder = supabase
          .from('foods_catalog')
          .select()
          .eq('is_verified', true)
          .not('micros_json', 'is', null); // Only foods with micronutrients

      if (tags.isNotEmpty) {
        queryBuilder.contains('tags', tags);
      }

      final response = await queryBuilder.limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching foods by tags: $e');
      return [];
    }
  }

  /// Get recent foods (last 10 unique foods logged)
  static Future<List<Map<String, dynamic>>> getRecentFoods() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await supabase
          .from('meal_items')
          .select('food_id, foods_catalog(*), created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      // Get unique food_ids
      final seenFoods = <String>{};
      final recentFoods = <Map<String, dynamic>>[];

      for (var item in response) {
        final food = item['foods_catalog'] as Map<String, dynamic>?;
        if (food != null) {
          final foodId = food['id'] as String;
          if (!seenFoods.contains(foodId)) {
            seenFoods.add(foodId);
            recentFoods.add(food);
            if (recentFoods.length >= 10) break;
          }
        }
      }

      return recentFoods;
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching recent foods: $e');
      return [];
    }
  }

  /// Get favorite foods
  static Future<List<Map<String, dynamic>>> getFavoriteFoods() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await supabase
          .from('favorites_foods')
          .select('foods_catalog(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map((item) => item['foods_catalog'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching favorite foods: $e');
      return [];
    }
  }

  /// Toggle favorite food
  static Future<bool> toggleFavoriteFood(String foodId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already favorite
      final existing = await supabase
          .from('favorites_foods')
          .select()
          .eq('user_id', userId)
          .eq('food_id', foodId)
          .maybeSingle();

      if (existing != null) {
        // Remove from favorites
        await supabase
            .from('favorites_foods')
            .delete()
            .eq('user_id', userId)
            .eq('food_id', foodId);
        return false;
      } else {
        // Add to favorites
        await supabase.from('favorites_foods').insert({
          'user_id': userId,
          'food_id': foodId,
        });
        return true;
      }
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error toggling favorite: $e');
      return false;
    }
  }

  /// Get weekly meal data (last 7 days)
  static Future<List<Map<String, dynamic>>> getWeeklyMealData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final today = DateTime.now();
      final weekStart = today.subtract(const Duration(days: 6));

      final response = await supabase
          .from('meal_days')
          .select()
          .eq('user_id', userId)
          .gte('date', '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}')
          .lte('date', '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}')
          .order('date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching weekly data: $e');
      return [];
    }
  }

  /// Upload meal photo
  static Future<String?> uploadMealPhoto({
    required DateTime date,
    required String mealType,
    required String filePath,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final fileName = '${userId}_${dateStr}_${mealType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'meal_photos/$fileName';

      // Upload to Supabase Storage
      final imageFile = File(filePath);
      await supabase.storage.from('meal_photos').upload(
        storagePath,
        imageFile,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
        ),
      );

      // Save photo record
      await supabase.from('meal_photos').insert({
        'user_id': userId,
        'date': dateStr,
        'meal_type': mealType,
        'storage_path': storagePath,
      });

      return storagePath;
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error uploading photo: $e');
      return null;
    }
  }

  /// Get meal photos
  static Future<List<Map<String, dynamic>>> getMealPhotos({
    required DateTime date,
    String? mealType,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final queryBuilder = supabase
          .from('meal_photos')
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr);

      if (mealType != null) {
        queryBuilder.eq('meal_type', mealType);
      }

      final response = await queryBuilder.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error fetching photos: $e');
      return [];
    }
  }

  /// Set or update meal day targets
  static Future<bool> setMealDayTargets({
    required DateTime date,
    int? calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Get current targets if they exist
      final current = await getMealDay(date);
      final updateData = <String, dynamic>{
        'user_id': userId,
        'date': dateStr,
        'calorie_target': calorieTarget ?? current?['calorie_target'] ?? 2000,
        'protein_target': proteinTarget ?? current?['protein_target'] ?? 120,
        'carbs_target': carbsTarget ?? current?['carbs_target'] ?? 250,
        'fat_target': fatTarget ?? current?['fat_target'] ?? 65,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('meal_days')
          .upsert(updateData, onConflict: 'user_id,date')
          .select();

      return true;
    } catch (e) {
      print('❌ [MEAL_TRACKER] Error setting targets: $e');
      return false;
    }
  }
}


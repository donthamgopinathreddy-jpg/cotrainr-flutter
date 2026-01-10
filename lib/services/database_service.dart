import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SupabaseClient? _client;
  bool _initialized = false;

  SupabaseClient? get client => _client;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    // Check if Supabase is already initialized
    try {
      _client = Supabase.instance.client;
      _initialized = true;
      print('✅ Database service connected to Supabase');
    } catch (e) {
      // Supabase not initialized yet, will be initialized in main.dart
      print('⚠️ Supabase not initialized yet. Will connect after initialization.');
      _initialized = false;
    }
  }

  // User data methods
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (!_initialized || _client == null) return null;
    
    try {
      final response = await _client!
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Steps data methods
  Future<List<Map<String, dynamic>>> getWeeklySteps(String userId) async {
    if (!_initialized || _client == null) return [];
    
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      final response = await _client!
          .from('steps')
          .select()
          .eq('user_id', userId)
          .gte('date', weekStart.toIso8601String())
          .order('date');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching steps data: $e');
      return [];
    }
  }

  // Water intake methods
  Future<List<Map<String, dynamic>>> getWeeklyWater(String userId) async {
    if (!_initialized || _client == null) return [];
    
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      final response = await _client!
          .from('water_intake')
          .select()
          .eq('user_id', userId)
          .gte('date', weekStart.toIso8601String())
          .order('date');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching water data: $e');
      return [];
    }
  }

  // Calories methods
  Future<List<Map<String, dynamic>>> getWeeklyCalories(String userId) async {
    if (!_initialized || _client == null) return [];
    
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      final response = await _client!
          .from('calories')
          .select()
          .eq('user_id', userId)
          .gte('date', weekStart.toIso8601String())
          .order('date');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching calories data: $e');
      return [];
    }
  }

  // CoCircle methods
  Future<List<Map<String, dynamic>>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    if (!_initialized || _client == null) return [];
    
    try {
      // This is a simplified version - you'd need PostGIS for proper distance calculation
      final response = await _client!
          .from('users')
          .select()
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching nearby users: $e');
      return [];
    }
  }

  Future<int> getActiveUsersCount() async {
    if (!_initialized || _client == null) return 0;
    
    try {
      final response = await _client!
          .from('users')
          .select('id')
          .eq('is_active', true)
          .count();
      
      return response.count;
    } catch (e) {
      print('Error fetching active users count: $e');
      return 0;
    }
  }
}


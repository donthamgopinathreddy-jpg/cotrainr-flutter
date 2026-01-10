import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  Map<String, dynamic>? _cachedProfile;
  DateTime? _lastFetch;

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      // Return cached profile if less than 5 minutes old
      if (_cachedProfile != null && 
          _lastFetch != null && 
          DateTime.now().difference(_lastFetch!).inMinutes < 5) {
        return _cachedProfile;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        _cachedProfile = response;
        _lastFetch = DateTime.now();
      }

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    _cachedProfile = null;
    _lastFetch = null;
  }

  String? getRole() {
    return _cachedProfile?['role'] as String?;
  }

  String? getDisplayName() {
    return _cachedProfile?['display_name'] as String?;
  }

  String? getFirstName() {
    return _cachedProfile?['first_name'] as String?;
  }

  String? getProfilePhotoUrl() {
    return _cachedProfile?['profile_photo_url'] as String?;
  }

  String? getCoverPhotoUrl() {
    return _cachedProfile?['cover_photo_url'] as String?;
  }

  double? getBMI() {
    return _cachedProfile?['bmi'] as double?;
  }

  String? getBMIStatus() {
    return _cachedProfile?['bmi_status'] as String?;
  }
}


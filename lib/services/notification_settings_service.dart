import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const String _keyPushNotifications = 'notification_push_enabled';
  static const String _keyQuestReminders = 'notification_quest_reminders';
  static const String _keyAchievementAlerts = 'notification_achievement_alerts';
  static const String _keySocialUpdates = 'notification_social_updates';

  /// Get push notifications enabled status
  static Future<bool> isPushNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPushNotifications) ?? true; // Default to true
    } catch (e) {
      print('Error getting push notifications setting: $e');
      return true; // Default to enabled
    }
  }

  /// Set push notifications enabled status
  static Future<void> setPushNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPushNotifications, enabled);
      
      // If push notifications are disabled, disable all other notifications
      if (!enabled) {
        await setQuestRemindersEnabled(false);
        await setAchievementAlertsEnabled(false);
        await setSocialUpdatesEnabled(false);
      }
    } catch (e) {
      print('Error setting push notifications: $e');
    }
  }

  /// Get quest reminders enabled status
  static Future<bool> isQuestRemindersEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyQuestReminders) ?? true; // Default to true
    } catch (e) {
      print('Error getting quest reminders setting: $e');
      return true;
    }
  }

  /// Set quest reminders enabled status
  static Future<void> setQuestRemindersEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyQuestReminders, enabled);
    } catch (e) {
      print('Error setting quest reminders: $e');
    }
  }

  /// Get achievement alerts enabled status
  static Future<bool> isAchievementAlertsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyAchievementAlerts) ?? true; // Default to true
    } catch (e) {
      print('Error getting achievement alerts setting: $e');
      return true;
    }
  }

  /// Set achievement alerts enabled status
  static Future<void> setAchievementAlertsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAchievementAlerts, enabled);
    } catch (e) {
      print('Error setting achievement alerts: $e');
    }
  }

  /// Get social updates enabled status
  static Future<bool> isSocialUpdatesEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySocialUpdates) ?? true; // Default to true
    } catch (e) {
      print('Error getting social updates setting: $e');
      return true;
    }
  }

  /// Set social updates enabled status
  static Future<void> setSocialUpdatesEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySocialUpdates, enabled);
    } catch (e) {
      print('Error setting social updates: $e');
    }
  }

  /// Check if a notification type should be sent
  /// Returns true only if push notifications are enabled AND the specific notification type is enabled
  /// If push notifications are disabled, NO notifications will be sent regardless of individual settings
  static Future<bool> shouldSendNotification(String notificationType) async {
    // CRITICAL: Push notifications must be enabled for ANY notification to work
    // If push notifications are disabled, no notifications are sent (quests, achievements, social, etc.)
    final pushEnabled = await isPushNotificationsEnabled();
    if (!pushEnabled) {
      print('🔕 [NOTIFICATIONS] Push notifications disabled - blocking all notifications');
      return false;
    }

    // Normalize notification type to lowercase
    final normalizedType = notificationType.toLowerCase();

    // Then check the specific notification type
    switch (normalizedType) {
      case 'quest':
      case 'quest_reminder':
      case 'questfinished':
      case 'quest_finished':
        return await isQuestRemindersEnabled();
      case 'achievement':
      case 'achievement_alert':
      case 'goalachieved':
      case 'goal_achieved':
      case 'streakmilestone':
      case 'streak_milestone':
        return await isAchievementAlertsEnabled();
      case 'social':
      case 'like':
      case 'comment':
      case 'follow':
      case 'social_update':
      case 'socialchallenge':
      case 'social_challenge':
        return await isSocialUpdatesEnabled();
      default:
        // For unknown types, only check push notifications
        return pushEnabled;
    }
  }

  /// Get all notification settings
  static Future<Map<String, bool>> getAllSettings() async {
    return {
      'pushNotifications': await isPushNotificationsEnabled(),
      'questReminders': await isQuestRemindersEnabled(),
      'achievementAlerts': await isAchievementAlertsEnabled(),
      'socialUpdates': await isSocialUpdatesEnabled(),
    };
  }
}


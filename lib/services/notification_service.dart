import '../models/notification_model.dart';
import 'notification_service_supabase.dart';
import 'notification_settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // Initialize with real data from Supabase
  Future<void> initialize() async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      final fetchedNotifications = await NotificationServiceSupabase.fetchNotifications();
      _notifications.clear();
      _notifications.addAll(fetchedNotifications);
      _updateUnreadCount();
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error initializing: $e');
      // Fallback to empty list
      _notifications.clear();
    } finally {
      _isLoading = false;
    }
  }

  // Refresh notifications from Supabase
  Future<void> refresh() async {
    await initialize();
  }

  // Legacy method for backward compatibility (now async)
  void initializeSync() {
    // Keep for backward compatibility but make it async
    initialize();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        type: _notifications[index].type,
        title: _notifications[index].title,
        message: _notifications[index].message,
        userId: _notifications[index].userId,
        userName: _notifications[index].userName,
        userAvatar: _notifications[index].userAvatar,
        timestamp: _notifications[index].timestamp,
        isRead: true,
        data: _notifications[index].data,
      );
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          type: _notifications[i].type,
          title: _notifications[i].title,
          message: _notifications[i].message,
          userId: _notifications[i].userId,
          userName: _notifications[i].userName,
          userAvatar: _notifications[i].userAvatar,
          timestamp: _notifications[i].timestamp,
          isRead: true,
          data: _notifications[i].data,
        );
      }
    }
    _updateUnreadCount();
  }

  /// Add notification (checks settings before adding)
  Future<void> addNotification(NotificationModel notification) async {
    // Check if this notification type should be sent
    final notificationTypeString = notification.type.toString().split('.').last.toLowerCase();
    final shouldSend = await NotificationSettingsService.shouldSendNotification(
      notificationTypeString,
    );
    
    if (!shouldSend) {
      print('🔕 [NOTIFICATIONS] Notification blocked by settings: $notificationTypeString');
      return;
    }
    
    _notifications.insert(0, notification);
    _updateUnreadCount();
  }
  
  /// Check if a notification type should be sent (for use before creating notifications)
  static Future<bool> shouldSendNotificationType(String notificationType) async {
    return await NotificationSettingsService.shouldSendNotification(notificationType);
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
  }
}


































import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // Initialize with sample notifications
  void initialize() {
    _notifications.addAll([
      NotificationModel(
        id: '1',
        type: NotificationType.follow,
        title: 'New Follower',
        message: 'Alex Johnson started following you',
        userId: 'user1',
        userName: 'Alex Johnson',
        userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        type: NotificationType.goalAchieved,
        title: 'Goal Achieved! 🎉',
        message: 'You reached your daily step goal of 10,000 steps!',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        data: {'goalType': 'steps'},
      ),
      NotificationModel(
        id: '3',
        type: NotificationType.questFinished,
        title: 'Quest Completed!',
        message: 'You completed "Walk 10,000 steps today" and earned 50 coins!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        data: {'coins': 50, 'questId': 'quest1'},
      ),
      NotificationModel(
        id: '4',
        type: NotificationType.socialChallenge,
        title: 'New Social Challenge',
        message: 'Join the "7-Day Fitness Challenge" with 245 participants!',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
        data: {'challengeId': 'challenge1'},
      ),
      NotificationModel(
        id: '5',
        type: NotificationType.videoSessionReminder,
        title: 'Session Reminder',
        message: 'Your video session with Trainer Mike starts in 30 minutes',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: false,
        data: {'sessionId': 'session1'},
      ),
      NotificationModel(
        id: '6',
        type: NotificationType.videoSessionStarting,
        title: 'Session Starting Now!',
        message: 'Your video session is starting. Join now!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: false,
        data: {'sessionId': 'session2'},
      ),
      NotificationModel(
        id: '7',
        type: NotificationType.newMessage,
        title: 'New Message',
        message: 'Trainer Sarah sent you a message',
        userId: 'trainer1',
        userName: 'Trainer Sarah',
        userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
        data: {'chatId': 'chat1'},
      ),
      NotificationModel(
        id: '8',
        type: NotificationType.like,
        title: 'New Like',
        message: 'Priya Sharma liked your post',
        userId: 'user2',
        userName: 'Priya Sharma',
        userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: false,
        data: {'postId': 'post1'},
      ),
      NotificationModel(
        id: '9',
        type: NotificationType.streakMilestone,
        title: 'Streak Milestone! 🔥',
        message: 'Congratulations! You\'ve reached a 7-day streak!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        data: {'streakDays': 7},
      ),
      NotificationModel(
        id: '10',
        type: NotificationType.achievement,
        title: 'Achievement Unlocked!',
        message: 'You unlocked the "Early Bird" badge!',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        data: {'badgeId': 'badge1'},
      ),
    ]);

    _updateUnreadCount();
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

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _updateUnreadCount();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
  }
}





















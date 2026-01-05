import 'package:flutter/material.dart';

enum NotificationType {
  follow,
  goalAchieved,
  questFinished,
  socialChallenge,
  videoSessionReminder,
  videoSessionStarting,
  newMessage,
  like,
  comment,
  achievement,
  streakMilestone,
  trainerMessage,
  clientProgress,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data for navigation

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.userId,
    this.userName,
    this.userAvatar,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.goalAchieved:
        return Icons.emoji_events;
      case NotificationType.questFinished:
        return Icons.check_circle;
      case NotificationType.socialChallenge:
        return Icons.group;
      case NotificationType.videoSessionReminder:
        return Icons.notifications;
      case NotificationType.videoSessionStarting:
        return Icons.video_call;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.achievement:
        return Icons.stars;
      case NotificationType.streakMilestone:
        return Icons.local_fire_department;
      case NotificationType.trainerMessage:
        return Icons.chat_bubble;
      case NotificationType.clientProgress:
        return Icons.trending_up;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.follow:
        return Colors.blue;
      case NotificationType.goalAchieved:
        return Colors.amber;
      case NotificationType.questFinished:
        return Colors.green;
      case NotificationType.socialChallenge:
        return Colors.purple;
      case NotificationType.videoSessionReminder:
        return Colors.orange;
      case NotificationType.videoSessionStarting:
        return Colors.red;
      case NotificationType.newMessage:
        return Colors.blue;
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.streakMilestone:
        return Colors.orange;
      case NotificationType.trainerMessage:
        return Colors.teal;
      case NotificationType.clientProgress:
        return Colors.green;
    }
  }
}


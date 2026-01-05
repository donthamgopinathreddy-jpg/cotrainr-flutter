import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  String _filter = 'All'; // All, Unread, Follows, Quests, Sessions
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController.forward();
  }

  Future<void> _loadNotifications() async {
    await _notificationService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  List<NotificationModel> get _filteredNotifications {
    final notifications = _notificationService.notifications;
    switch (_filter) {
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'Follows':
        return notifications
            .where((n) => n.type == NotificationType.follow)
            .toList();
      case 'Quests':
        return notifications
            .where((n) =>
                n.type == NotificationType.questFinished ||
                n.type == NotificationType.socialChallenge ||
                n.type == NotificationType.goalAchieved)
            .toList();
      case 'Sessions':
        return notifications
            .where((n) =>
                n.type == NotificationType.videoSessionReminder ||
                n.type == NotificationType.videoSessionStarting)
            .toList();
      default:
        return notifications;
    }
  }

  Color _getNotificationTint(NotificationType type) {
    switch (type) {
      case NotificationType.follow:
        return const Color(0xFF3B82F6); // Blue tint
      case NotificationType.goalAchieved:
        return const Color(0xFF10B981); // Green tint
      case NotificationType.questFinished:
      case NotificationType.socialChallenge:
        return const Color(0xFFF59E0B); // Orange tint
      case NotificationType.videoSessionReminder:
      case NotificationType.videoSessionStarting:
        return const Color(0xFF8B5CF6); // Purple tint
      default:
        return const Color(0xFF6366F1); // Default indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: Title Left + MarkAllRead TextButton Right
            _buildTopAppBar(isDark),
            
            // Filter Chips Row
            _buildFilterChips(isDark),
            
            // Notifications List
            Expanded(
              child: _filteredNotifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.mediumImpact();
                        await _notificationService.refresh();
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      color: const Color(0xFF14B8A6),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          return FadeTransition(
                            opacity: _fadeController,
                            child: _buildNotificationCard(_filteredNotifications[index], isDark),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          if (_notificationService.unreadCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _notificationService.markAllAsRead();
                });
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF14B8A6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['All', 'Unread', 'Follows', 'Quests', 'Sessions'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filter == filter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _filter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {});
      },
      color: const Color(0xFF14B8A6),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re all caught up!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isDark) {
    final tintColor = _getNotificationTint(notification.type);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeBackground(
        Alignment.centerLeft,
        Icons.check_circle_outline,
        const Color(0xFF10B981),
        'Mark Read',
      ),
      secondaryBackground: _buildSwipeBackground(
        Alignment.centerRight,
        Icons.delete_outline,
        const Color(0xFFEF4444),
        'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right: Delete
          HapticFeedback.lightImpact();
          setState(() {
            _notificationService.deleteNotification(notification.id);
          });
          return true;
        } else {
          // Swipe left: Mark as read
          if (!notification.isRead) {
            HapticFeedback.lightImpact();
            setState(() {
              _notificationService.markAsRead(notification.id);
            });
          }
          return false; // Don't dismiss, just mark as read
        }
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (!notification.isRead) {
            setState(() {
              _notificationService.markAsRead(notification.id);
            });
          }
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle with Light Tint
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tintColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: tintColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content (Title + Subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tintColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (notification.userAvatar != null)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(notification.userAvatar!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (notification.userAvatar != null)
                          const SizedBox(width: 6),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(Alignment alignment, IconData icon, Color color, String label) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Navigate with fade through transition
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // Placeholder for detail page - implement based on notification type
          return Scaffold(
            appBar: AppBar(title: Text(notification.title)),
            body: Center(child: Text(notification.message)),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.follow:
        // Navigate to user profile
        break;
      case NotificationType.goalAchieved:
        // Navigate to goals/analytics
        break;
      case NotificationType.questFinished:
        // Navigate to quests page
        break;
      case NotificationType.socialChallenge:
        // Navigate to quests page with challenge tab
        break;
      case NotificationType.videoSessionReminder:
      case NotificationType.videoSessionStarting:
        // Navigate to video sessions or join directly
        break;
      case NotificationType.newMessage:
      case NotificationType.trainerMessage:
        // Navigate to messages
        break;
      case NotificationType.like:
      case NotificationType.comment:
        // Navigate to post detail
        break;
      case NotificationType.achievement:
      case NotificationType.streakMilestone:
        // Navigate to profile achievements
        break;
      case NotificationType.clientProgress:
        // Navigate to client stats
        break;
    }
  }
}
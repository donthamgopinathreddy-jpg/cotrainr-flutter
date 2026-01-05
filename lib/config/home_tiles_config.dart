import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/quick_access_widget.dart';
import '../pages/meal_tracker_page_v2.dart';
import '../pages/video_sessions_page.dart';
import '../pages/messages_page.dart' show ConversationsListPage;
import '../pages/ai_planner_page.dart';
import '../pages/clients_page.dart';
import '../pages/quests_page.dart';

enum UserRole { client, trainer, nutritionist }

class HomeTilesConfig {
  final UserRole role;
  
  HomeTilesConfig(this.role);
  
  List<QuickAccessTile> getQuickAccessTiles(BuildContext context) {
    switch (role) {
      case UserRole.trainer:
        return _getTrainerTiles(context);
      case UserRole.nutritionist:
        return _getNutritionistTiles(context);
      case UserRole.client:
        return _getClientTiles(context);
    }
  }
  
  List<QuickAccessTile> _getClientTiles(BuildContext context) {
    return [
      QuickAccessTile(
        icon: Icons.restaurant_menu_rounded,
        label: 'Meal Tracker',
        color: const Color(0xFF10B981),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MealTrackerPageV2()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.videocam_rounded,
        label: 'Video Sessions',
        color: const Color(0xFF8B5CF6),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VideoSessionsPage()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.message_rounded,
        label: 'Messages',
        color: const Color(0xFF3B82F6),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConversationsListPage()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.auto_awesome_rounded,
        label: 'AI Planner',
        color: const Color(0xFFF59E0B),
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiPlannerPage()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.school_rounded,
        label: 'Become a Trainer',
        color: const Color(0xFFEC4899),
        onTap: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Become a trainer feature coming soon')),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.local_dining_rounded,
        label: 'Become a Nutritionist',
        color: const Color(0xFF10B981),
        onTap: () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Become a nutritionist feature coming soon')),
          );
        },
      ),
    ];
  }
  
  List<QuickAccessTile> _getTrainerTiles(BuildContext context) {
    return [
      QuickAccessTile(
        icon: Icons.restaurant_menu_rounded,
        label: 'Meal Tracker',
        color: const Color(0xFF10B981),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MealTrackerPageV2()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.videocam_rounded,
        label: 'Video Sessions',
        color: const Color(0xFF8B5CF6),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VideoSessionsPage()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.message_rounded,
        label: 'Messages',
        color: const Color(0xFF3B82F6),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConversationsListPage()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.people_rounded,
        label: 'Client Stats',
        color: const Color(0xFF6366F1),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClientsPage(role: 'trainer')),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.track_changes_rounded,
        label: 'Assign Quest',
        color: const Color(0xFFF59E0B),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuestsPage()),
          );
        },
      ),
      QuickAccessTile(
        icon: Icons.restaurant_menu_outlined,
        label: 'Meal Logs Review',
        color: const Color(0xFF10B981),
        onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meal logs review coming soon')),
          );
        },
      ),
    ];
  }
  
  List<QuickAccessTile> _getNutritionistTiles(BuildContext context) {
    // Similar to trainer but nutritionist-specific
    return _getTrainerTiles(context);
  }
}


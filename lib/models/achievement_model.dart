import 'package:flutter/material.dart';

enum AchievementType {
  steps,
  water,
  calories,
  streak,
  quest,
  level,
  social,
  workout,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;
  final String iconName;
  final int targetValue;
  final int xpReward;
  final int coinsReward;
  final bool isActive;
  final DateTime? createdAt;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.rarity,
    required this.iconName,
    required this.targetValue,
    this.xpReward = 0,
    this.coinsReward = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      type: AchievementType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] as String? ?? 'steps'),
        orElse: () => AchievementType.steps,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.toString().split('.').last == (map['rarity'] as String? ?? 'common'),
        orElse: () => AchievementRarity.common,
      ),
      iconName: map['icon_name'] as String? ?? 'emoji_events',
      targetValue: map['target_value'] as int? ?? 0,
      xpReward: map['xp_reward'] as int? ?? 0,
      coinsReward: map['coins_reward'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'icon_name': iconName,
      'target_value': targetValue,
      'xp_reward': xpReward,
      'coins_reward': coinsReward,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  IconData get icon {
    switch (iconName) {
      case 'directions_run':
        return Icons.directions_run;
      case 'water_drop':
        return Icons.water_drop;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'star':
        return Icons.star;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'military_tech':
        return Icons.military_tech;
      default:
        return Icons.emoji_events;
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return const Color(0xFFFFC300);
    }
  }

  String get rarityName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}

class UserAchievementModel {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final AchievementModel? achievement;

  UserAchievementModel({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.achievement,
  });

  factory UserAchievementModel.fromMap(Map<String, dynamic> map) {
    return UserAchievementModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      achievementId: map['achievement_id'] as String,
      unlockedAt: DateTime.parse(map['unlocked_at'] as String),
      achievement: map['achievements'] != null
          ? AchievementModel.fromMap(map['achievements'] as Map<String, dynamic>)
          : null,
    );
  }
}









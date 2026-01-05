import 'package:flutter/material.dart';

enum CompetitionType {
  steps,
  water,
  calories,
  workouts,
  overall,
}

enum CompetitionStatus {
  upcoming,
  active,
  ended,
}

class CompetitionModel {
  final String id;
  final String title;
  final String description;
  final CompetitionType type;
  final CompetitionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int prizeCoins;
  final int prizeXP;
  final int maxParticipants;
  final int currentParticipants;
  final bool isActive;
  final DateTime createdAt;

  CompetitionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.prizeCoins = 0,
    this.prizeXP = 0,
    this.maxParticipants = 100,
    this.currentParticipants = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory CompetitionModel.fromMap(Map<String, dynamic> map) {
    return CompetitionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      type: CompetitionType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] as String? ?? 'steps'),
        orElse: () => CompetitionType.steps,
      ),
      status: CompetitionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (map['status'] as String? ?? 'active'),
        orElse: () => CompetitionStatus.active,
      ),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      prizeCoins: map['prize_coins'] as int? ?? 0,
      prizeXP: map['prize_xp'] as int? ?? 0,
      maxParticipants: map['max_participants'] as int? ?? 100,
      currentParticipants: map['current_participants'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'prize_coins': prizeCoins,
      'prize_xp': prizeXP,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isFull => currentParticipants >= maxParticipants;
  bool get canJoin => isActive && !isFull && status == CompetitionStatus.active;
  
  Duration get remainingDuration => endDate.difference(DateTime.now());
  String get timeRemaining {
    final duration = remainingDuration;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  IconData get icon {
    switch (type) {
      case CompetitionType.steps:
        return Icons.directions_walk;
      case CompetitionType.water:
        return Icons.water_drop;
      case CompetitionType.calories:
        return Icons.local_fire_department;
      case CompetitionType.workouts:
        return Icons.fitness_center;
      case CompetitionType.overall:
        return Icons.emoji_events;
    }
  }

  Color get iconColor {
    switch (type) {
      case CompetitionType.steps:
        return Colors.blue;
      case CompetitionType.water:
        return Colors.cyan;
      case CompetitionType.calories:
        return Colors.orange;
      case CompetitionType.workouts:
        return Colors.purple;
      case CompetitionType.overall:
        return const Color(0xFFFFC300);
    }
  }

  String get typeName {
    switch (type) {
      case CompetitionType.steps:
        return 'Steps Challenge';
      case CompetitionType.water:
        return 'Water Challenge';
      case CompetitionType.calories:
        return 'Calories Challenge';
      case CompetitionType.workouts:
        return 'Workouts Challenge';
      case CompetitionType.overall:
        return 'Overall Fitness';
    }
  }
}

class CompetitionParticipantModel {
  final String id;
  final String competitionId;
  final String userId;
  final int score;
  final int rank;
  final DateTime joinedAt;
  final DateTime? lastUpdatedAt;

  CompetitionParticipantModel({
    required this.id,
    required this.competitionId,
    required this.userId,
    this.score = 0,
    this.rank = 0,
    required this.joinedAt,
    this.lastUpdatedAt,
  });

  factory CompetitionParticipantModel.fromMap(Map<String, dynamic> map) {
    return CompetitionParticipantModel(
      id: map['id'] as String,
      competitionId: map['competition_id'] as String,
      userId: map['user_id'] as String,
      score: map['score'] as int? ?? 0,
      rank: map['rank'] as int? ?? 0,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      lastUpdatedAt: map['last_updated_at'] != null
          ? DateTime.parse(map['last_updated_at'] as String)
          : null,
    );
  }
}









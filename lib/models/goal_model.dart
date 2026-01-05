import 'package:flutter/material.dart';

enum GoalType {
  steps,
  water,
  calories,
  workouts,
  weight,
}

enum GoalPeriod {
  daily,
  weekly,
  monthly,
}

class GoalModel {
  final String id;
  final String userId;
  final GoalType type;
  final GoalPeriod period;
  final int targetValue;
  final int currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.period,
    required this.targetValue,
    this.currentValue = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: GoalType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] as String? ?? 'steps'),
        orElse: () => GoalType.steps,
      ),
      period: GoalPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == (map['period'] as String? ?? 'daily'),
        orElse: () => GoalPeriod.daily,
      ),
      targetValue: map['target_value'] as int? ?? 0,
      currentValue: map['current_value'] as int? ?? 0,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      isActive: map['is_active'] as bool? ?? true,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'period': period.toString().split('.').last,
      'target_value': targetValue,
      'current_value': currentValue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
  bool get isCompleted => currentValue >= targetValue;
  int get remainingValue => (targetValue - currentValue).clamp(0, targetValue);

  IconData get icon {
    switch (type) {
      case GoalType.steps:
        return Icons.directions_walk;
      case GoalType.water:
        return Icons.water_drop;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.workouts:
        return Icons.fitness_center;
      case GoalType.weight:
        return Icons.monitor_weight;
    }
  }

  Color get iconColor {
    switch (type) {
      case GoalType.steps:
        return Colors.blue;
      case GoalType.water:
        return Colors.cyan;
      case GoalType.calories:
        return Colors.orange;
      case GoalType.workouts:
        return Colors.purple;
      case GoalType.weight:
        return Colors.green;
    }
  }

  String get typeName {
    switch (type) {
      case GoalType.steps:
        return 'Steps';
      case GoalType.water:
        return 'Water';
      case GoalType.calories:
        return 'Calories';
      case GoalType.workouts:
        return 'Workouts';
      case GoalType.weight:
        return 'Weight';
    }
  }

  String get periodName {
    switch (period) {
      case GoalPeriod.daily:
        return 'Daily';
      case GoalPeriod.weekly:
        return 'Weekly';
      case GoalPeriod.monthly:
        return 'Monthly';
    }
  }

  String get unit {
    switch (type) {
      case GoalType.steps:
        return 'steps';
      case GoalType.water:
        return 'ml';
      case GoalType.calories:
        return 'cal';
      case GoalType.workouts:
        return 'sessions';
      case GoalType.weight:
        return 'kg';
    }
  }
}









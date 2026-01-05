# CoTrainr Quest System - Complete Implementation

## Overview
A comprehensive quest, achievement, goal, and competition system with notification integration for the CoTrainr fitness app.

## What's Included

### 1. **Models** (`lib/models/`)
- `achievement_model.dart` - Achievement types, rarities, and user achievements
- `goal_model.dart` - Daily/weekly/monthly goals with progress tracking
- `competition_model.dart` - Competitions with leaderboards and participation

### 2. **Services** (`lib/services/`)
- `achievement_service.dart` - Achievement unlocking, progress tracking, rewards
- `goal_service.dart` - Goal creation, progress updates, stats syncing
- `competition_service.dart` - Competition joining, score tracking, leaderboards
- `quest_service.dart` - Enhanced with daily/weekly quest filtering and notifications

### 3. **Database Schema** (`supabase_quest_system_schema.sql`)
- `user_stats` - XP, coins, level tracking
- `achievements` - Achievement definitions
- `user_achievements` - User's unlocked achievements
- `goals` - User goals (daily/weekly/monthly)
- `competitions` - Competition definitions
- `competition_participants` - Participation and rankings
- Enhanced `quests` table with quest_type, xp_reward, icons
- Enhanced `user_quest_progress` with current_value, is_completed, is_claimed

## Setup Instructions

### 1. Run Database Migration
Execute `supabase_quest_system_schema.sql` in your Supabase SQL Editor. This will:
- Create all necessary tables
- Set up RLS policies
- Add sample achievements and quests

### 2. Integration Points

#### Daily Stats Sync
The quest system automatically syncs with daily stats. Add this to your daily stats update flow:

```dart
// After updating daily stats
await QuestService.syncQuestProgressWithStats();
await GoalService.syncGoalsWithStats();
await CompetitionService.syncCompetitionScores();
await AchievementService.checkAndUnlockAchievements(
  steps: todayStats['steps'],
  water: todayStats['water_ml'],
  calories: todayStats['calories_burned'],
  streak: currentStreak,
  level: currentLevel,
);
```

#### Notification Integration
Notifications are automatically sent when:
- ✅ Quest completed
- ✅ Achievement unlocked
- ✅ Goal achieved
- ✅ Competition joined

All notifications respect user notification settings.

## Usage Examples

### Creating a Goal
```dart
final goal = await GoalService.createGoal(
  type: GoalType.steps,
  period: GoalPeriod.daily,
  targetValue: 10000,
);
```

### Joining a Competition
```dart
final success = await CompetitionService.joinCompetition(competitionId);
```

### Checking Achievements
```dart
final achievements = await AchievementService.getAchievements();
final userAchievements = await AchievementService.getUserAchievements();
```

### Getting Daily/Weekly Quests
```dart
final dailyQuests = await QuestService.getDailyQuests();
final weeklyQuests = await QuestService.getWeeklyQuests();
```

## Notification Types
The system uses these notification types (already defined in `notification_model.dart`):
- `questFinished` - When a quest is completed
- `achievement` - When an achievement is unlocked
- `goalAchieved` - When a goal is reached
- `socialChallenge` - When joining/updating competitions

## Features

### ✅ Daily Quests
- Automatically sync with daily stats
- Progress tracking
- Reward claiming
- Notifications on completion

### ✅ Weekly Quests
- Higher targets for weekly challenges
- Better rewards
- Progress tracking across the week

### ✅ Achievements
- Multiple rarity levels (Common, Rare, Epic, Legendary)
- Automatic unlocking based on stats
- XP and coin rewards
- Progress tracking

### ✅ Goals
- Daily, weekly, monthly periods
- Multiple goal types (steps, water, calories, workouts, weight)
- Automatic progress syncing
- Completion notifications

### ✅ Competitions
- Multiple competition types
- Leaderboards with rankings
- Score tracking
- Prize system (XP and coins)
- Participant limits

## Next Steps

1. **UI Pages**: Create pages for:
   - Achievements gallery
   - Goals management
   - Competition details
   - Enhanced quests page (already exists, may need updates)

2. **Real-time Updates**: Consider adding Supabase real-time subscriptions for:
   - Competition leaderboard updates
   - Achievement unlocks
   - Quest progress

3. **Analytics**: Track:
   - Quest completion rates
   - Achievement unlock rates
   - Competition participation
   - Goal success rates

## Notes

- All services check for user authentication
- RLS policies ensure users can only access their own data
- Notifications respect user notification settings
- Progress is automatically synced with daily stats
- All rewards (XP, coins) are tracked in `user_stats` table









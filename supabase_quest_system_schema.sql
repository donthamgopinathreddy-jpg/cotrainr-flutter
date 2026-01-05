-- ============================================
-- CoTrainr Quest System Schema Extension
-- ============================================
-- This extends the existing schema with:
-- ✅ Achievements system
-- ✅ Goals system (daily/weekly/monthly)
-- ✅ Enhanced competitions
-- ✅ User stats (XP, coins, level)
-- ============================================

BEGIN;

-- ============================================
-- USER STATS TABLE (XP, Coins, Level)
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_stats (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_xp INT NOT NULL DEFAULT 0,
  coins INT NOT NULL DEFAULT 0,
  level INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS user_stats_xp_idx ON public.user_stats(total_xp DESC);

-- ============================================
-- ACHIEVEMENTS SYSTEM
-- ============================================
CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('steps','water','calories','streak','quest','level','social','workout')),
  rarity TEXT NOT NULL DEFAULT 'common' CHECK (rarity IN ('common','rare','epic','legendary')),
  icon_name TEXT NOT NULL DEFAULT 'emoji_events',
  target_value INT NOT NULL,
  xp_reward INT NOT NULL DEFAULT 0,
  coins_reward INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS user_achievements_user_idx ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS user_achievements_achievement_idx ON public.user_achievements(achievement_id);

-- ============================================
-- GOALS SYSTEM
-- ============================================
CREATE TABLE IF NOT EXISTS public.goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('steps','water','calories','workouts','weight')),
  period TEXT NOT NULL CHECK (period IN ('daily','weekly','monthly')),
  target_value INT NOT NULL,
  current_value INT NOT NULL DEFAULT 0,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS goals_user_active_idx ON public.goals(user_id, is_active);
CREATE INDEX IF NOT EXISTS goals_user_period_idx ON public.goals(user_id, period);

-- ============================================
-- ENHANCED COMPETITIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.competitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('steps','water','calories','workouts','overall')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('upcoming','active','ended')),
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  prize_coins INT NOT NULL DEFAULT 0,
  prize_xp INT NOT NULL DEFAULT 0,
  max_participants INT NOT NULL DEFAULT 100,
  current_participants INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.competition_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id UUID NOT NULL REFERENCES public.competitions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INT NOT NULL DEFAULT 0,
  rank INT NOT NULL DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_updated_at TIMESTAMPTZ,
  UNIQUE (competition_id, user_id)
);

CREATE INDEX IF NOT EXISTS competition_participants_competition_idx ON public.competition_participants(competition_id);
CREATE INDEX IF NOT EXISTS competition_participants_user_idx ON public.competition_participants(user_id);
CREATE INDEX IF NOT EXISTS competition_participants_rank_idx ON public.competition_participants(competition_id, rank);

-- ============================================
-- ENHANCE QUESTS TABLE (add quest_type, xp_reward)
-- ============================================
-- Add quest_type column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quests' AND column_name = 'quest_type'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN quest_type TEXT CHECK (quest_type IN ('daily','weekly','special'));
  END IF;
END $$;

-- Add xp_reward column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quests' AND column_name = 'xp_reward'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN xp_reward INT NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Add icon_name and icon_color if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quests' AND column_name = 'icon_name'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN icon_name TEXT DEFAULT 'fitness_center';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quests' AND column_name = 'icon_color'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN icon_color TEXT DEFAULT '#FF7A00';
  END IF;
END $$;

-- Add category column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quests' AND column_name = 'category'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN category TEXT;
  END IF;
END $$;

-- Add unit column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quests' AND column_name = 'unit'
  ) THEN
    ALTER TABLE public.quests ADD COLUMN unit TEXT DEFAULT '';
  END IF;
END $$;

-- ============================================
-- ENHANCE USER_QUEST_PROGRESS (add current_value, is_completed, is_claimed)
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_quest_progress' AND column_name = 'current_value'
  ) THEN
    ALTER TABLE public.user_quest_progress ADD COLUMN current_value INT DEFAULT 0;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_quest_progress' AND column_name = 'is_completed'
  ) THEN
    ALTER TABLE public.user_quest_progress ADD COLUMN is_completed BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_quest_progress' AND column_name = 'is_claimed'
  ) THEN
    ALTER TABLE public.user_quest_progress ADD COLUMN is_claimed BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- ============================================
-- RLS POLICIES (with DROP IF EXISTS to handle existing policies)
-- ============================================

-- User Stats
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own stats" ON public.user_stats;
CREATE POLICY "Users can view their own stats"
  ON public.user_stats FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own stats" ON public.user_stats;
CREATE POLICY "Users can update their own stats"
  ON public.user_stats FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own stats" ON public.user_stats;
CREATE POLICY "Users can insert their own stats"
  ON public.user_stats FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Achievements
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active achievements" ON public.achievements;
CREATE POLICY "Anyone can view active achievements"
  ON public.achievements FOR SELECT
  USING (is_active = TRUE);

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own achievements" ON public.user_achievements;
CREATE POLICY "Users can view their own achievements"
  ON public.user_achievements FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own achievements" ON public.user_achievements;
CREATE POLICY "Users can insert their own achievements"
  ON public.user_achievements FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Goals
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own goals" ON public.goals;
CREATE POLICY "Users can manage their own goals"
  ON public.goals FOR ALL
  USING (auth.uid() = user_id);

-- Competitions
ALTER TABLE public.competitions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active competitions" ON public.competitions;
CREATE POLICY "Anyone can view active competitions"
  ON public.competitions FOR SELECT
  USING (is_active = TRUE);

ALTER TABLE public.competition_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view competition participants" ON public.competition_participants;
CREATE POLICY "Users can view competition participants"
  ON public.competition_participants FOR SELECT
  USING (TRUE);

DROP POLICY IF EXISTS "Users can join competitions" ON public.competition_participants;
CREATE POLICY "Users can join competitions"
  ON public.competition_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own participation" ON public.competition_participants;
CREATE POLICY "Users can update their own participation"
  ON public.competition_participants FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Sample Achievements
INSERT INTO public.achievements (title, description, type, rarity, icon_name, target_value, xp_reward, coins_reward) VALUES
  ('First Steps', 'Walk 1,000 steps in a day', 'steps', 'common', 'directions_walk', 1000, 50, 10),
  ('Step Master', 'Walk 10,000 steps in a day', 'steps', 'rare', 'directions_run', 10000, 200, 50),
  ('Hydration Hero', 'Drink 2L of water in a day', 'water', 'common', 'water_drop', 2000, 50, 10),
  ('Fire Starter', 'Maintain a 7-day streak', 'streak', 'rare', 'local_fire_department', 7, 300, 100),
  ('Level Up', 'Reach level 10', 'level', 'epic', 'workspace_premium', 10, 500, 200)
ON CONFLICT DO NOTHING;

-- Sample Daily Quests
INSERT INTO public.quests (title, description, metric, target, quest_type, xp_reward, coins_reward, icon_name, icon_color, category, unit) VALUES
  ('Daily Steps', 'Walk 5,000 steps today', 'steps', 5000, 'daily', 100, 20, 'directions_walk', '#2196F3', 'Fitness', 'steps'),
  ('Stay Hydrated', 'Drink 1.5L of water today', 'water', 1500, 'daily', 100, 20, 'water_drop', '#00BCD4', 'Health', 'ml'),
  ('Burn Calories', 'Burn 300 calories today', 'calories', 300, 'daily', 150, 30, 'local_fire_department', '#FF9800', 'Fitness', 'cal')
ON CONFLICT DO NOTHING;

-- Sample Weekly Quests
INSERT INTO public.quests (title, description, metric, target, quest_type, xp_reward, coins_reward, icon_name, icon_color, category, unit) VALUES
  ('Weekly Warrior', 'Walk 50,000 steps this week', 'steps', 50000, 'weekly', 500, 100, 'directions_run', '#4CAF50', 'Fitness', 'steps'),
  ('Hydration Champion', 'Drink 10L of water this week', 'water', 10000, 'weekly', 500, 100, 'water_drop', '#00BCD4', 'Health', 'ml')
ON CONFLICT DO NOTHING;

COMMIT;








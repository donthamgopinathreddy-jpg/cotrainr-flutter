-- Quest System Schema for Supabase
-- This extends the existing schema with quest-related tables

-- Quests table: Defines available quests
CREATE TABLE IF NOT EXISTS public.quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  quest_type TEXT NOT NULL CHECK (quest_type IN ('daily', 'weekly', 'special')),
  category TEXT,
  icon_name TEXT, -- Icon identifier (e.g., 'directions_run', 'water_drop')
  icon_color TEXT, -- Hex color code
  target_value NUMERIC(10, 2) NOT NULL,
  unit TEXT, -- e.g., 'km', 'L', 'sets', 'workouts'
  xp_reward INTEGER DEFAULT 0,
  coins_reward INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Quest Progress: Tracks user progress on quests
CREATE TABLE IF NOT EXISTS public.quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  progress NUMERIC(3, 2) DEFAULT 0.0 CHECK (progress >= 0.0 AND progress <= 1.0),
  current_value NUMERIC(10, 2) DEFAULT 0.0,
  is_completed BOOLEAN DEFAULT false,
  is_claimed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  claimed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, quest_id)
);

-- User Stats: Tracks XP, coins, level, etc.
CREATE TABLE IF NOT EXISTS public.user_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  total_xp INTEGER DEFAULT 0,
  coins INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Competitions table
CREATE TABLE IF NOT EXISTS public.competitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  competition_type TEXT NOT NULL CHECK (competition_type IN ('global', 'team', 'friends')),
  metric_type TEXT NOT NULL, -- e.g., 'steps', 'workouts', 'distance'
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  prize_coins INTEGER DEFAULT 0,
  prize_description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Competition Participants
CREATE TABLE IF NOT EXISTS public.competition_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id UUID NOT NULL REFERENCES public.competitions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  progress_value NUMERIC(10, 2) DEFAULT 0.0,
  rank INTEGER,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(competition_id, user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_quest_progress_user_id ON public.quest_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_quest_progress_quest_id ON public.quest_progress(quest_id);
CREATE INDEX IF NOT EXISTS idx_quest_progress_completed ON public.quest_progress(is_completed, is_claimed);
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON public.user_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_user_stats_xp ON public.user_stats(total_xp DESC);
CREATE INDEX IF NOT EXISTS idx_competitions_active ON public.competitions(is_active, end_date);
CREATE INDEX IF NOT EXISTS idx_competition_participants_comp_id ON public.competition_participants(competition_id);
CREATE INDEX IF NOT EXISTS idx_competition_participants_user_id ON public.competition_participants(user_id);

-- RLS Policies for Quests
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active quests" ON public.quests
  FOR SELECT
  USING (is_active = true);

-- RLS Policies for Quest Progress
ALTER TABLE public.quest_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own quest progress" ON public.quest_progress
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can insert their own quest progress" ON public.quest_progress
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own quest progress" ON public.quest_progress
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- RLS Policies for User Stats
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own stats" ON public.user_stats
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Public can view leaderboard stats" ON public.user_stats
  FOR SELECT
  USING (true); -- Allow public read for leaderboard

CREATE POLICY "Users can insert their own stats" ON public.user_stats
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own stats" ON public.user_stats
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- RLS Policies for Competitions
ALTER TABLE public.competitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active competitions" ON public.competitions
  FOR SELECT
  USING (is_active = true);

-- RLS Policies for Competition Participants
ALTER TABLE public.competition_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view competition participants" ON public.competition_participants
  FOR SELECT
  USING (true); -- Public read for leaderboards

CREATE POLICY "Users can insert their own participation" ON public.competition_participants
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update their own participation" ON public.competition_participants
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_quests_updated_at
  BEFORE UPDATE ON public.quests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quest_progress_updated_at
  BEFORE UPDATE ON public.quest_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_stats_updated_at
  BEFORE UPDATE ON public.user_stats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_competitions_updated_at
  BEFORE UPDATE ON public.competitions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_competition_participants_updated_at
  BEFORE UPDATE ON public.competition_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert sample daily quests
INSERT INTO public.quests (title, description, quest_type, category, icon_name, icon_color, target_value, unit, xp_reward, coins_reward, is_active) VALUES
  ('Morning Run', 'Complete a morning run', 'daily', 'Cardio', 'directions_run', '#FF7A00', 5.0, 'km', 50, 0, true),
  ('Hydration', 'Drink enough water', 'daily', 'Health', 'water_drop', '#3B82F6', 3.0, 'L', 30, 0, true),
  ('Strength Training', 'Complete strength exercises', 'daily', 'Fitness', 'fitness_center', '#FF7A00', 5.0, 'sets', 75, 0, true)
ON CONFLICT DO NOTHING;

-- Insert sample weekly quest
INSERT INTO public.quests (title, description, quest_type, category, icon_name, icon_color, target_value, unit, xp_reward, coins_reward, is_active) VALUES
  ('Complete 5 Workouts', 'Finish 5 workouts this week', 'weekly', 'Activity', 'sports_gymnastics', '#FF7A00', 5.0, 'workouts', 200, 0, true)
ON CONFLICT DO NOTHING;
















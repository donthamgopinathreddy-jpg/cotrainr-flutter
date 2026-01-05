-- ============================================
-- CoTrainr Quest System V2 - Complete Implementation
-- ============================================
-- Based on template-based rotation system
-- ============================================

BEGIN;

-- ============================================
-- 1. QUEST TEMPLATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.quest_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('daily', 'weekly', 'competition')),
  metric TEXT NOT NULL CHECK (metric IN (
    'steps', 'water_ml', 'calories_burned', 'meals_logged', 
    'sessions_attended', 'streak_days', 'weight_entries', 
    'posts_created', 'comments_made'
  )),
  target_value INT NOT NULL,
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  reward_coins INT NOT NULL DEFAULT 0,
  reward_xp INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS quest_templates_type_idx ON public.quest_templates(type, is_active);
CREATE INDEX IF NOT EXISTS quest_templates_difficulty_idx ON public.quest_templates(difficulty) WHERE difficulty IS NOT NULL;

-- ============================================
-- 2. QUEST ROTATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.quest_rotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rotation_type TEXT NOT NULL CHECK (rotation_type IN ('daily', 'weekly')),
  starts_on DATE NOT NULL,
  ends_on DATE NOT NULL,
  quest_ids UUID[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (rotation_type, starts_on)
);

CREATE INDEX IF NOT EXISTS quest_rotations_type_date_idx ON public.quest_rotations(rotation_type, starts_on DESC);

-- ============================================
-- 3. USER QUEST PROGRESS TABLE (Updated)
-- ============================================
-- Drop old table if exists and recreate with new structure
DROP TABLE IF EXISTS public.user_quest_progress CASCADE;

CREATE TABLE public.user_quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rotation_id UUID NOT NULL REFERENCES public.quest_rotations(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES public.quest_templates(id) ON DELETE CASCADE,
  progress_value INT NOT NULL DEFAULT 0,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  reward_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, rotation_id, template_id)
);

CREATE INDEX IF NOT EXISTS user_quest_progress_user_idx ON public.user_quest_progress(user_id);
CREATE INDEX IF NOT EXISTS user_quest_progress_rotation_idx ON public.user_quest_progress(rotation_id);
CREATE INDEX IF NOT EXISTS user_quest_progress_template_idx ON public.user_quest_progress(template_id);
CREATE INDEX IF NOT EXISTS user_quest_progress_completed_idx ON public.user_quest_progress(user_id, is_completed, reward_claimed);

-- ============================================
-- 4. REWARDS EVENTS TABLE (Ledger for coins/XP)
-- ============================================
CREATE TABLE IF NOT EXISTS public.rewards_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  source TEXT NOT NULL CHECK (source IN ('quest', 'achievement', 'competition', 'referral', 'other')),
  template_id UUID REFERENCES public.quest_templates(id) ON DELETE SET NULL,
  rotation_id UUID REFERENCES public.quest_rotations(id) ON DELETE SET NULL,
  competition_id UUID REFERENCES public.competitions(id) ON DELETE SET NULL,
  coins INT NOT NULL DEFAULT 0,
  xp INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS rewards_events_user_idx ON public.rewards_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS rewards_events_source_idx ON public.rewards_events(source);

-- ============================================
-- 5. COMPETITIONS TABLE (Updated)
-- ============================================
-- Update existing competitions table if needed
DO $$
BEGIN
  -- Add reward_rules column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'competitions' AND column_name = 'reward_rules'
  ) THEN
    ALTER TABLE public.competitions ADD COLUMN reward_rules JSONB;
  END IF;
  
  -- Ensure metric column exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'competitions' AND column_name = 'metric'
  ) THEN
    ALTER TABLE public.competitions ADD COLUMN metric TEXT CHECK (metric IN (
      'steps', 'water_ml', 'calories_burned', 'meals_logged', 
      'sessions_attended', 'streak_days', 'overall'
    ));
  END IF;
END $$;

-- ============================================
-- 6. COMPETITION SCORES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.competition_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id UUID NOT NULL REFERENCES public.competitions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INT NOT NULL DEFAULT 0,
  rank INT NOT NULL DEFAULT 0,
  percentile DECIMAL(5,2),
  reward_claimed BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (competition_id, user_id)
);

CREATE INDEX IF NOT EXISTS competition_scores_competition_idx ON public.competition_scores(competition_id, score DESC);
CREATE INDEX IF NOT EXISTS competition_scores_user_idx ON public.competition_scores(user_id);
CREATE INDEX IF NOT EXISTS competition_scores_rank_idx ON public.competition_scores(competition_id, rank);

-- ============================================
-- 7. RLS POLICIES
-- ============================================

-- Quest Templates
ALTER TABLE public.quest_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active quest templates" ON public.quest_templates;
CREATE POLICY "Anyone can view active quest templates"
  ON public.quest_templates FOR SELECT
  USING (is_active = TRUE);

-- Quest Rotations
ALTER TABLE public.quest_rotations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view quest rotations" ON public.quest_rotations;
CREATE POLICY "Anyone can view quest rotations"
  ON public.quest_rotations FOR SELECT
  USING (TRUE);

-- User Quest Progress
ALTER TABLE public.user_quest_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own quest progress" ON public.user_quest_progress;
CREATE POLICY "Users can view their own quest progress"
  ON public.user_quest_progress FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own quest progress" ON public.user_quest_progress;
CREATE POLICY "Users can update their own quest progress"
  ON public.user_quest_progress FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert quest progress" ON public.user_quest_progress;
CREATE POLICY "System can insert quest progress"
  ON public.user_quest_progress FOR INSERT
  WITH CHECK (TRUE); -- Triggers will handle this

-- Rewards Events
ALTER TABLE public.rewards_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own rewards" ON public.rewards_events;
CREATE POLICY "Users can view their own rewards"
  ON public.rewards_events FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert rewards" ON public.rewards_events;
CREATE POLICY "System can insert rewards"
  ON public.rewards_events FOR INSERT
  WITH CHECK (TRUE); -- Triggers will handle this

-- Competition Scores
ALTER TABLE public.competition_scores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view competition scores" ON public.competition_scores;
CREATE POLICY "Anyone can view competition scores"
  ON public.competition_scores FOR SELECT
  USING (TRUE);

DROP POLICY IF EXISTS "Users can update their own scores" ON public.competition_scores;
CREATE POLICY "Users can update their own scores"
  ON public.competition_scores FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own scores" ON public.competition_scores;
CREATE POLICY "Users can insert their own scores"
  ON public.competition_scores FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 8. RPC FUNCTIONS
-- ============================================

-- Function to create today's daily rotation
CREATE OR REPLACE FUNCTION public.create_today_rotation()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rotation_id UUID;
  today_date DATE;
  quest_ids UUID[];
  easy_quests UUID[];
  medium_quests UUID[];
  hard_quests UUID[];
  water_quests UUID[];
  steps_quests UUID[];
  selected_quests UUID[];
  recent_quest_ids UUID[];
BEGIN
  today_date := CURRENT_DATE;
  
  -- Check if rotation already exists
  SELECT id INTO rotation_id
  FROM public.quest_rotations
  WHERE rotation_type = 'daily' AND starts_on = today_date;
  
  IF rotation_id IS NOT NULL THEN
    RETURN rotation_id;
  END IF;
  
  -- Get quests used in last 3 days (excluding today)
  SELECT ARRAY_AGG(DISTINCT template_id) INTO recent_quest_ids
  FROM public.quest_rotations r
  JOIN public.user_quest_progress p ON p.rotation_id = r.id
  WHERE r.rotation_type = 'daily'
    AND r.starts_on >= today_date - INTERVAL '3 days'
    AND r.starts_on < today_date;
  
  -- Get quest templates by difficulty
  SELECT ARRAY_AGG(id) INTO easy_quests
  FROM public.quest_templates
  WHERE type = 'daily' AND difficulty = 'easy' AND is_active = TRUE
    AND (recent_quest_ids IS NULL OR id != ALL(recent_quest_ids));
  
  SELECT ARRAY_AGG(id) INTO medium_quests
  FROM public.quest_templates
  WHERE type = 'daily' AND difficulty = 'medium' AND is_active = TRUE
    AND (recent_quest_ids IS NULL OR id != ALL(recent_quest_ids));
  
  SELECT ARRAY_AGG(id) INTO hard_quests
  FROM public.quest_templates
  WHERE type = 'daily' AND difficulty = 'hard' AND is_active = TRUE
    AND (recent_quest_ids IS NULL OR id != ALL(recent_quest_ids));
  
  -- Get water and steps quests
  SELECT ARRAY_AGG(id) INTO water_quests
  FROM public.quest_templates
  WHERE type = 'daily' AND metric = 'water_ml' AND is_active = TRUE
    AND (recent_quest_ids IS NULL OR id != ALL(recent_quest_ids));
  
  SELECT ARRAY_AGG(id) INTO steps_quests
  FROM public.quest_templates
  WHERE type = 'daily' AND metric = 'steps' AND is_active = TRUE
    AND (recent_quest_ids IS NULL OR id != ALL(recent_quest_ids));
  
  -- Select quests: 1 easy, 2 medium, 2 hard
  -- Always include at least 1 water and 1 steps quest
  selected_quests := ARRAY[]::UUID[];
  
  -- Add 1 easy quest (prefer water or steps)
  IF array_length(water_quests, 1) > 0 AND (SELECT id FROM unnest(water_quests) WHERE id = ANY(easy_quests) LIMIT 1) IS NOT NULL THEN
    selected_quests := array_append(selected_quests, (SELECT id FROM unnest(water_quests) WHERE id = ANY(easy_quests) LIMIT 1));
  ELSIF array_length(steps_quests, 1) > 0 AND (SELECT id FROM unnest(steps_quests) WHERE id = ANY(easy_quests) LIMIT 1) IS NOT NULL THEN
    selected_quests := array_append(selected_quests, (SELECT id FROM unnest(steps_quests) WHERE id = ANY(easy_quests) LIMIT 1));
  ELSIF array_length(easy_quests, 1) > 0 THEN
    selected_quests := array_append(selected_quests, easy_quests[1 + floor(random() * array_length(easy_quests, 1))::int]);
  END IF;
  
  -- Add 2 medium quests
  FOR i IN 1..2 LOOP
    IF array_length(medium_quests, 1) > 0 THEN
      selected_quests := array_append(selected_quests, medium_quests[1 + floor(random() * array_length(medium_quests, 1))::int]);
    END IF;
  END LOOP;
  
  -- Add 2 hard quests
  FOR i IN 1..2 LOOP
    IF array_length(hard_quests, 1) > 0 THEN
      selected_quests := array_append(selected_quests, hard_quests[1 + floor(random() * array_length(hard_quests, 1))::int]);
    END IF;
  END LOOP;
  
  -- Ensure we have at least 1 water and 1 steps quest
  IF NOT (EXISTS (SELECT 1 FROM public.quest_templates WHERE id = ANY(selected_quests) AND metric = 'water_ml')) THEN
    IF array_length(water_quests, 1) > 0 THEN
      selected_quests[1] := water_quests[1 + floor(random() * array_length(water_quests, 1))::int];
    END IF;
  END IF;
  
  IF NOT (EXISTS (SELECT 1 FROM public.quest_templates WHERE id = ANY(selected_quests) AND metric = 'steps')) THEN
    IF array_length(steps_quests, 1) > 0 THEN
      selected_quests[2] := steps_quests[1 + floor(random() * array_length(steps_quests, 1))::int];
    END IF;
  END IF;
  
  -- Create rotation
  INSERT INTO public.quest_rotations (rotation_type, starts_on, ends_on, quest_ids)
  VALUES ('daily', today_date, today_date, selected_quests)
  RETURNING id INTO rotation_id;
  
  RETURN rotation_id;
END;
$$;

-- Function to create weekly rotation
CREATE OR REPLACE FUNCTION public.create_weekly_rotation()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rotation_id UUID;
  week_start DATE;
  week_end DATE;
  selected_quests UUID[];
  available_quests UUID[];
BEGIN
  -- Calculate week start (Monday)
  week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE;
  week_end := week_start + INTERVAL '6 days';
  
  -- Check if rotation already exists
  SELECT id INTO rotation_id
  FROM public.quest_rotations
  WHERE rotation_type = 'weekly' AND starts_on = week_start;
  
  IF rotation_id IS NOT NULL THEN
    RETURN rotation_id;
  END IF;
  
  -- Get 3 weekly quest templates
  SELECT ARRAY_AGG(id) INTO available_quests
  FROM public.quest_templates
  WHERE type = 'weekly' AND is_active = TRUE
  ORDER BY RANDOM()
  LIMIT 3;
  
  selected_quests := available_quests;
  
  -- Create rotation
  INSERT INTO public.quest_rotations (rotation_type, starts_on, ends_on, quest_ids)
  VALUES ('weekly', week_start, week_end, selected_quests)
  RETURNING id INTO rotation_id;
  
  RETURN rotation_id;
END;
$$;

-- Function to update quest progress automatically
CREATE OR REPLACE FUNCTION public.update_quest_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id_val UUID;
  today_date DATE;
  rotation_record RECORD;
  template_record RECORD;
  progress_record RECORD;
  new_progress INT;
  target_value INT;
  is_complete BOOLEAN;
BEGIN
  -- Get user_id from the trigger context
  user_id_val := COALESCE(NEW.user_id, (SELECT user_id FROM daily_stats WHERE id = NEW.id));
  today_date := CURRENT_DATE;
  
  -- Find active daily rotation for today
  SELECT * INTO rotation_record
  FROM public.quest_rotations
  WHERE rotation_type = 'daily'
    AND starts_on <= today_date
    AND ends_on >= today_date
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF rotation_record IS NULL THEN
    -- Create rotation if it doesn't exist
    PERFORM public.create_today_rotation();
    SELECT * INTO rotation_record
    FROM public.quest_rotations
    WHERE rotation_type = 'daily' AND starts_on = today_date
    LIMIT 1;
  END IF;
  
  IF rotation_record IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Loop through quest templates in rotation
  FOR template_record IN
    SELECT * FROM public.quest_templates
    WHERE id = ANY(rotation_record.quest_ids)
      AND metric IN ('steps', 'water_ml', 'calories_burned')
  LOOP
    -- Get current value based on metric
    CASE template_record.metric
      WHEN 'steps' THEN
        new_progress := COALESCE((SELECT steps FROM daily_stats WHERE user_id = user_id_val AND stat_date = today_date::TEXT), 0);
      WHEN 'water_ml' THEN
        new_progress := COALESCE((SELECT water_ml FROM daily_stats WHERE user_id = user_id_val AND stat_date = today_date::TEXT), 0);
      WHEN 'calories_burned' THEN
        new_progress := COALESCE((SELECT calories_burned FROM daily_stats WHERE user_id = user_id_val AND stat_date = today_date::TEXT), 0);
      ELSE
        new_progress := 0;
    END CASE;
    
    target_value := template_record.target_value;
    is_complete := new_progress >= target_value;
    
    -- Check if progress record exists
    SELECT * INTO progress_record
    FROM public.user_quest_progress
    WHERE user_id = user_id_val
      AND rotation_id = rotation_record.id
      AND template_id = template_record.id;
    
    IF progress_record IS NULL THEN
      -- Create new progress record
      INSERT INTO public.user_quest_progress (
        user_id, rotation_id, template_id, progress_value, is_completed, completed_at
      )
      VALUES (
        user_id_val, rotation_record.id, template_record.id, new_progress, is_complete,
        CASE WHEN is_complete THEN NOW() ELSE NULL END
      );
    ELSE
      -- Update existing progress
      UPDATE public.user_quest_progress
      SET progress_value = new_progress,
          is_completed = is_complete,
          completed_at = CASE WHEN is_complete AND progress_record.completed_at IS NULL THEN NOW() ELSE progress_record.completed_at END,
          updated_at = NOW()
      WHERE id = progress_record.id;
      
      -- Create notification if just completed
      IF is_complete AND NOT progress_record.is_completed THEN
        -- Notification will be handled by app-side service
        NULL;
      END IF;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$;

-- ============================================
-- 9. TRIGGERS
-- ============================================

-- Trigger on daily_stats updates
DROP TRIGGER IF EXISTS daily_stats_quest_progress_trigger ON public.daily_stats;
CREATE TRIGGER daily_stats_quest_progress_trigger
  AFTER INSERT OR UPDATE ON public.daily_stats
  FOR EACH ROW
  EXECUTE FUNCTION public.update_quest_progress();

-- Function to update quest progress for meals
CREATE OR REPLACE FUNCTION public.update_quest_progress_meals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id_val UUID;
  today_date DATE;
  rotation_record RECORD;
  template_record RECORD;
  progress_record RECORD;
  meals_count INT;
  target_value INT;
  is_complete BOOLEAN;
BEGIN
  user_id_val := NEW.user_id;
  today_date := CURRENT_DATE;
  
  -- Count meals logged today
  SELECT COUNT(*) INTO meals_count
  FROM public.meals_logs
  WHERE user_id = user_id_val
    AND DATE(created_at) = today_date;
  
  -- Find active daily rotation
  SELECT * INTO rotation_record
  FROM public.quest_rotations
  WHERE rotation_type = 'daily'
    AND starts_on <= today_date
    AND ends_on >= today_date
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF rotation_record IS NULL THEN
    PERFORM public.create_today_rotation();
    SELECT * INTO rotation_record
    FROM public.quest_rotations
    WHERE rotation_type = 'daily' AND starts_on = today_date
    LIMIT 1;
  END IF;
  
  IF rotation_record IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Update meals_logged quests
  FOR template_record IN
    SELECT * FROM public.quest_templates
    WHERE id = ANY(rotation_record.quest_ids)
      AND metric = 'meals_logged'
  LOOP
    target_value := template_record.target_value;
    is_complete := meals_count >= target_value;
    
    SELECT * INTO progress_record
    FROM public.user_quest_progress
    WHERE user_id = user_id_val
      AND rotation_id = rotation_record.id
      AND template_id = template_record.id;
    
    IF progress_record IS NULL THEN
      INSERT INTO public.user_quest_progress (
        user_id, rotation_id, template_id, progress_value, is_completed, completed_at
      )
      VALUES (
        user_id_val, rotation_record.id, template_record.id, meals_count, is_complete,
        CASE WHEN is_complete THEN NOW() ELSE NULL END
      );
    ELSE
      UPDATE public.user_quest_progress
      SET progress_value = meals_count,
          is_completed = is_complete,
          completed_at = CASE WHEN is_complete AND progress_record.completed_at IS NULL THEN NOW() ELSE progress_record.completed_at END,
          updated_at = NOW()
      WHERE id = progress_record.id;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$;

-- Trigger on meals_logs
DROP TRIGGER IF EXISTS meals_logs_quest_progress_trigger ON public.meals_logs;
CREATE TRIGGER meals_logs_quest_progress_trigger
  AFTER INSERT ON public.meals_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_quest_progress_meals();

-- Function to update quest progress for sessions
CREATE OR REPLACE FUNCTION public.update_quest_progress_sessions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id_val UUID;
  week_start DATE;
  rotation_record RECORD;
  template_record RECORD;
  progress_record RECORD;
  sessions_count INT;
  target_value INT;
  is_complete BOOLEAN;
BEGIN
  user_id_val := NEW.user_id;
  week_start := DATE_TRUNC('week', CURRENT_DATE)::DATE;
  
  -- Count sessions this week
  SELECT COUNT(*) INTO sessions_count
  FROM public.meetings
  WHERE trainer_id = user_id_val OR client_id = user_id_val
    AND DATE(start_time) >= week_start
    AND status = 'completed';
  
  -- Find active weekly rotation
  SELECT * INTO rotation_record
  FROM public.quest_rotations
  WHERE rotation_type = 'weekly'
    AND starts_on <= week_start
    AND ends_on >= week_start + INTERVAL '6 days'
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF rotation_record IS NULL THEN
    PERFORM public.create_weekly_rotation();
    SELECT * INTO rotation_record
    FROM public.quest_rotations
    WHERE rotation_type = 'weekly' AND starts_on = week_start
    LIMIT 1;
  END IF;
  
  IF rotation_record IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Update sessions_attended quests
  FOR template_record IN
    SELECT * FROM public.quest_templates
    WHERE id = ANY(rotation_record.quest_ids)
      AND metric = 'sessions_attended'
  LOOP
    target_value := template_record.target_value;
    is_complete := sessions_count >= target_value;
    
    SELECT * INTO progress_record
    FROM public.user_quest_progress
    WHERE user_id = user_id_val
      AND rotation_id = rotation_record.id
      AND template_id = template_record.id;
    
    IF progress_record IS NULL THEN
      INSERT INTO public.user_quest_progress (
        user_id, rotation_id, template_id, progress_value, is_completed, completed_at
      )
      VALUES (
        user_id_val, rotation_record.id, template_record.id, sessions_count, is_complete,
        CASE WHEN is_complete THEN NOW() ELSE NULL END
      );
    ELSE
      UPDATE public.user_quest_progress
      SET progress_value = sessions_count,
          is_completed = is_complete,
          completed_at = CASE WHEN is_complete AND progress_record.completed_at IS NULL THEN NOW() ELSE progress_record.completed_at END,
          updated_at = NOW()
      WHERE id = progress_record.id;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$;

-- Trigger on meetings (when status changes to completed)
DROP TRIGGER IF EXISTS meetings_quest_progress_trigger ON public.meetings;
CREATE TRIGGER meetings_quest_progress_trigger
  AFTER UPDATE OF status ON public.meetings
  FOR EACH ROW
  WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
  EXECUTE FUNCTION public.update_quest_progress_sessions();

-- ============================================
-- 10. SAMPLE QUEST TEMPLATES
-- ============================================

-- Daily Easy Quests
INSERT INTO public.quest_templates (title, description, type, metric, target_value, difficulty, reward_coins, reward_xp) VALUES
  ('Hydration Starter', 'Drink 1.5L of water today', 'daily', 'water_ml', 1500, 'easy', 10, 50),
  ('Morning Steps', 'Walk 6,000 steps today', 'daily', 'steps', 6000, 'easy', 10, 50),
  ('Light Activity', 'Walk 5,000 steps today', 'daily', 'steps', 5000, 'easy', 10, 50)
ON CONFLICT DO NOTHING;

-- Daily Medium Quests
INSERT INTO public.quest_templates (title, description, type, metric, target_value, difficulty, reward_coins, reward_xp) VALUES
  ('Step Goal', 'Walk 12,000 steps today', 'daily', 'steps', 12000, 'medium', 20, 100),
  ('Stay Hydrated', 'Drink 2.2L of water today', 'daily', 'water_ml', 2200, 'medium', 20, 100),
  ('Meal Tracker', 'Log 3 meals today', 'daily', 'meals_logged', 3, 'medium', 15, 75),
  ('Active Day', 'Walk 10,000 steps today', 'daily', 'steps', 10000, 'medium', 20, 100)
ON CONFLICT DO NOTHING;

-- Daily Hard Quests
INSERT INTO public.quest_templates (title, description, type, metric, target_value, difficulty, reward_coins, reward_xp) VALUES
  ('Step Champion', 'Walk 20,000 steps today', 'daily', 'steps', 20000, 'hard', 35, 200),
  ('Hydration Master', 'Drink 3L of water today', 'daily', 'water_ml', 3000, 'hard', 30, 150),
  ('Calorie Burner', 'Burn 500 calories today', 'daily', 'calories_burned', 500, 'hard', 35, 200)
ON CONFLICT DO NOTHING;

-- Weekly Quests
INSERT INTO public.quest_templates (title, description, type, metric, target_value, difficulty, reward_coins, reward_xp) VALUES
  ('Weekly Warrior', 'Walk 70,000 steps this week', 'weekly', 'steps', 70000, 'medium', 100, 500),
  ('Meal Consistency', 'Log meals on 5 days this week', 'weekly', 'meals_logged', 5, 'medium', 80, 400),
  ('Hydration Champion', 'Hit water goal on 4 days this week', 'weekly', 'water_ml', 8800, 'medium', 80, 400),
  ('Session Attender', 'Attend 2 sessions this week', 'weekly', 'sessions_attended', 2, 'medium', 100, 500)
ON CONFLICT DO NOTHING;

COMMIT;


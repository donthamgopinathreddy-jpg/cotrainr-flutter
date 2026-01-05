-- ============================================
-- Daily Streak and Login Tracking Schema
-- ============================================

-- ============================================
-- 1. USER_LOGINS TABLE
-- ============================================
-- Tracks daily logins for streak calculation

CREATE TABLE IF NOT EXISTS public.user_logins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  login_date DATE NOT NULL DEFAULT CURRENT_DATE,
  login_count INTEGER DEFAULT 1, -- Number of logins on this date
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, login_date) -- One record per user per day
);

CREATE INDEX IF NOT EXISTS idx_user_logins_user_id ON public.user_logins(user_id);
CREATE INDEX IF NOT EXISTS idx_user_logins_login_date ON public.user_logins(login_date DESC);
CREATE INDEX IF NOT EXISTS idx_user_logins_user_date ON public.user_logins(user_id, login_date DESC);

-- ============================================
-- 2. ENABLE RLS
-- ============================================

ALTER TABLE public.user_logins ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. RLS POLICIES
-- ============================================

DROP POLICY IF EXISTS "Users can view own logins" ON public.user_logins;
DROP POLICY IF EXISTS "Users can insert own logins" ON public.user_logins;
DROP POLICY IF EXISTS "Users can update own logins" ON public.user_logins;

-- Users can view their own login records
CREATE POLICY "Users can view own logins"
  ON public.user_logins FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Users can insert their own login records
CREATE POLICY "Users can insert own logins"
  ON public.user_logins FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can update their own login records (to increment login_count)
CREATE POLICY "Users can update own logins"
  ON public.user_logins FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 4. TRIGGER FOR updated_at
-- ============================================

DROP TRIGGER IF EXISTS update_user_logins_updated_at ON public.user_logins;

CREATE TRIGGER update_user_logins_updated_at
  BEFORE UPDATE ON public.user_logins
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. FUNCTION TO RECORD LOGIN
-- ============================================
-- This function handles login recording with upsert logic

CREATE OR REPLACE FUNCTION record_daily_login(user_id_param UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.user_logins (user_id, login_date, login_count)
  VALUES (user_id_param, CURRENT_DATE, 1)
  ON CONFLICT (user_id, login_date)
  DO UPDATE SET
    login_count = user_logins.login_count + 1,
    updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION record_daily_login(UUID) TO authenticated;

-- ============================================
-- 6. FUNCTION TO GET CURRENT STREAK
-- ============================================
-- Calculates consecutive days of login ending today

CREATE OR REPLACE FUNCTION get_current_streak(user_id_param UUID)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  streak_count INTEGER := 0;
  check_date DATE := CURRENT_DATE;
  has_login BOOLEAN;
BEGIN
  -- Check if user logged in today
  SELECT EXISTS(
    SELECT 1 FROM public.user_logins
    WHERE user_id = user_id_param AND login_date = check_date
  ) INTO has_login;
  
  -- If no login today, return 0
  IF NOT has_login THEN
    RETURN 0;
  END IF;
  
  -- Count consecutive days backwards from today
  LOOP
    SELECT EXISTS(
      SELECT 1 FROM public.user_logins
      WHERE user_id = user_id_param AND login_date = check_date
    ) INTO has_login;
    
    IF has_login THEN
      streak_count := streak_count + 1;
      check_date := check_date - INTERVAL '1 day';
    ELSE
      EXIT;
    END IF;
  END LOOP;
  
  RETURN streak_count;
END;
$$;

GRANT EXECUTE ON FUNCTION get_current_streak(UUID) TO authenticated, anon;

-- ============================================
-- 7. FUNCTION TO GET TOTAL LOGIN COUNT
-- ============================================

CREATE OR REPLACE FUNCTION get_total_login_count(user_id_param UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT COUNT(DISTINCT login_date)::INTEGER
  FROM public.user_logins
  WHERE user_id = user_id_param;
$$;

GRANT EXECUTE ON FUNCTION get_total_login_count(UUID) TO authenticated, anon;

-- ============================================
-- 8. FUNCTION TO GET LONGEST STREAK
-- ============================================
-- Gets the longest streak ever achieved by the user

CREATE OR REPLACE FUNCTION get_longest_streak(user_id_param UUID)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  max_streak INTEGER := 0;
  current_streak INTEGER := 0;
  prev_date DATE;
  curr_date DATE;
BEGIN
  -- Get all login dates ordered
  FOR curr_date IN
    SELECT DISTINCT login_date
    FROM public.user_logins
    WHERE user_id = user_id_param
    ORDER BY login_date
  LOOP
    IF prev_date IS NULL OR curr_date = prev_date + INTERVAL '1 day' THEN
      -- Consecutive day
      current_streak := current_streak + 1;
    ELSE
      -- Gap found, reset streak
      IF current_streak > max_streak THEN
        max_streak := current_streak;
      END IF;
      current_streak := 1;
    END IF;
    prev_date := curr_date;
  END LOOP;
  
  -- Check final streak
  IF current_streak > max_streak THEN
    max_streak := current_streak;
  END IF;
  
  RETURN max_streak;
END;
$$;

GRANT EXECUTE ON FUNCTION get_longest_streak(UUID) TO authenticated, anon;

SELECT 'Streak schema complete! Table: user_logins. Functions: record_daily_login, get_current_streak, get_total_login_count, get_longest_streak.' AS status;


















-- ============================================
-- CoTrainr Complete Schema Reset - UPDATED
-- ============================================
-- Run this in Supabase SQL Editor in parts (A, B, C, D)
-- 
-- This schema includes:
-- ✅ Profiles with dob, gender, display_name, user_id (searchable)
-- ✅ Daily stats for steps, calories, water (used for streak tracking)
-- ✅ Posts, likes, comments, follows (for CoCircle social features)
-- ✅ Quests and user quest progress (for gamification)
-- ✅ Trainer profiles and verifications
-- ✅ Messaging (conversations, messages)
-- ✅ Meals and meal photos (for meal tracking)
-- ✅ BMI auto-calculation triggers (when height/weight changes)
-- ✅ Complete RLS policies for all tables
-- ✅ Indexes for performance optimization
-- ============================================

-- ============================================
-- SQL PART A: CLEANUP OLD TABLES, FUNCTIONS, TRIGGERS
-- ============================================

BEGIN;

-- 1) Drop triggers and functions that may be failing on auth signup
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
    DROP TRIGGER on_auth_user_created ON auth.users;
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- ignore
END $$;

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 2) Drop app tables if they exist
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversation_members CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;

DROP TABLE IF EXISTS public.post_likes CASCADE;
DROP TABLE IF EXISTS public.post_comments CASCADE;
DROP TABLE IF EXISTS public.posts CASCADE;
DROP TABLE IF EXISTS public.follows CASCADE;

DROP TABLE IF EXISTS public.meal_photos CASCADE;
DROP TABLE IF EXISTS public.meals CASCADE;

DROP TABLE IF EXISTS public.daily_stats CASCADE;

DROP TABLE IF EXISTS public.reward_events CASCADE;
DROP TABLE IF EXISTS public.user_quest_progress CASCADE;
DROP TABLE IF EXISTS public.quests CASCADE;

DROP TABLE IF EXISTS public.trainer_verifications CASCADE;
DROP TABLE IF EXISTS public.trainer_profiles CASCADE;

DROP TABLE IF EXISTS public.profiles CASCADE;

COMMIT;

-- ============================================
-- SQL PART B: CREATE CORE TABLES
-- ============================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Profiles
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  user_id TEXT NOT NULL, -- This is your searchable user id like gopi_5412
  email TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  display_name TEXT GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,

  phone TEXT NOT NULL, -- India only, store 10 digits or +91xxxxxxxxxx
  role TEXT NOT NULL CHECK (role IN ('client','trainer','admin')),

  category TEXT NOT NULL, -- Client goal category, or primary category
  categories TEXT[] DEFAULT '{}'::TEXT[], -- Optional multi select

  height_cm NUMERIC,
  weight_kg NUMERIC,
  bmi NUMERIC,
  bmi_status TEXT,
  
  dob DATE, -- Date of birth
  gender TEXT CHECK (gender IN ('male','female','other','prefer_not_to_say')), -- Gender

  avatar_path TEXT, -- Storage path
  cover_path TEXT,  -- Storage path

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX profiles_user_id_unique ON public.profiles(user_id);
CREATE UNIQUE INDEX profiles_email_unique ON public.profiles(email);

-- Trainer profile
CREATE TABLE public.trainer_profiles (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  years_experience INT,
  specialties TEXT[] DEFAULT '{}'::TEXT[],
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  rating NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trainer verifications
CREATE TABLE public.trainer_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES public.trainer_profiles(user_id) ON DELETE CASCADE,
  doc_type TEXT NOT NULL, -- aadhar, driving_license, passport, etc
  doc_path TEXT NOT NULL, -- Storage path
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  rejection_reason TEXT,
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Daily stats (used for steps, calories, water tracking and streak calculation)
CREATE TABLE public.daily_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  stat_date DATE NOT NULL,
  steps INT NOT NULL DEFAULT 0,
  calories_burned INT NOT NULL DEFAULT 0,
  water_ml INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, stat_date)
);

-- Index for faster queries on daily_stats (used for weekly stats and streak calculation)
CREATE INDEX daily_stats_user_date_idx ON public.daily_stats(user_id, stat_date DESC);

-- Meals
CREATE TABLE public.meals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  meal_date DATE NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast','lunch','snacks','dinner','extra')),
  title TEXT,
  notes TEXT,
  total_calories INT DEFAULT 0,
  total_protein_g NUMERIC DEFAULT 0,
  total_carbs_g NUMERIC DEFAULT 0,
  total_fat_g NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.meal_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_id UUID NOT NULL REFERENCES public.meals(id) ON DELETE CASCADE,
  photo_path TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Cocircle posts
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  caption TEXT NOT NULL CHECK (char_length(caption) <= 1000),
  media_type TEXT CHECK (media_type IN ('image','video')),
  media_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.post_likes (
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE public.post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK (char_length(body) <= 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.follows (
  follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id <> following_id)
);

-- Messaging
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.conversation_members (
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT,
  media_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Quests and rewards
CREATE TABLE public.quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  metric TEXT NOT NULL CHECK (metric IN ('steps','water','calories','meal_logging','session_attended')),
  target INT NOT NULL,
  coins_reward INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE public.user_quest_progress (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  progress INT NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, quest_id)
);

CREATE TABLE public.reward_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL, -- quest_complete, referral, etc
  coins INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMIT;

-- ============================================
-- SQL PART C: BMI CALCULATION, UPDATED_AT TRIGGER, SAFE AUTH TRIGGER
-- ============================================

BEGIN;

-- Updated_at helper
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- BMI helpers
CREATE OR REPLACE FUNCTION public.compute_bmi(weight_kg NUMERIC, height_cm NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
  h_m NUMERIC;
BEGIN
  IF weight_kg IS NULL OR height_cm IS NULL OR height_cm <= 0 THEN
    RETURN NULL;
  END IF;
  h_m := height_cm / 100.0;
  RETURN ROUND((weight_kg / (h_m*h_m))::NUMERIC, 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.bmi_status(bmi NUMERIC)
RETURNS TEXT AS $$
BEGIN
  IF bmi IS NULL THEN RETURN NULL; END IF;
  IF bmi < 18.5 THEN RETURN 'underweight';
  ELSIF bmi < 25 THEN RETURN 'normal';
  ELSIF bmi < 30 THEN RETURN 'overweight';
  ELSE RETURN 'obese';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update BMI when height or weight changes
CREATE OR REPLACE FUNCTION public.on_profile_metrics_change()
RETURNS TRIGGER AS $$
BEGIN
  NEW.bmi := public.compute_bmi(NEW.weight_kg, NEW.height_cm);
  NEW.bmi_status := public.bmi_status(NEW.bmi);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_metrics_bmi ON public.profiles;
CREATE TRIGGER profiles_metrics_bmi
BEFORE INSERT OR UPDATE OF height_cm, weight_kg ON public.profiles
FOR EACH ROW EXECUTE PROCEDURE public.on_profile_metrics_change();

-- Function to create profile (bypasses RLS for initial profile creation)
CREATE OR REPLACE FUNCTION public.create_user_profile(
  p_id UUID,
  p_user_id TEXT,
  p_email TEXT,
  p_first_name TEXT,
  p_last_name TEXT,
  p_phone TEXT,
  p_role TEXT,
  p_category TEXT,
  p_categories TEXT[],
  p_height_cm NUMERIC,
  p_weight_kg NUMERIC,
  p_dob DATE,
  p_gender TEXT,
  p_avatar_path TEXT,
  p_cover_path TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, user_id, email, first_name, last_name, phone, role,
    category, categories, height_cm, weight_kg, dob, gender,
    avatar_path, cover_path
  ) VALUES (
    p_id, p_user_id, p_email, p_first_name, p_last_name, p_phone, p_role,
    p_category, p_categories, p_height_cm, p_weight_kg, p_dob, p_gender,
    p_avatar_path, p_cover_path
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

-- Minimal auth trigger, do NOT insert into profiles here
-- Keep it minimal so signup never fails
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Do nothing, your app will insert profile after signUp
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

COMMIT;

-- ============================================
-- SQL PART D: ENABLE RLS RULES
-- ============================================

BEGIN;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quest_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_events ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "profiles read all" ON public.profiles FOR SELECT USING (true);
-- Allow insert if auth.uid() matches id (works for signup when session exists)
-- Note: If email confirmation is required, user must confirm email first
CREATE POLICY "profiles insert own" ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles update own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Trainer profiles
CREATE POLICY "trainer read all" ON public.trainer_profiles FOR SELECT USING (true);
CREATE POLICY "trainer insert own" ON public.trainer_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "trainer update own" ON public.trainer_profiles FOR UPDATE USING (auth.uid() = user_id);

-- Daily stats
CREATE POLICY "stats read own" ON public.daily_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "stats upsert own" ON public.daily_stats FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "stats update own" ON public.daily_stats FOR UPDATE USING (auth.uid() = user_id);

-- Meals
CREATE POLICY "meals read own" ON public.meals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "meals insert own" ON public.meals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "meals update own" ON public.meals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "meals delete own" ON public.meals FOR DELETE USING (auth.uid() = user_id);

-- Meal photos
CREATE POLICY "meal photos read own" ON public.meal_photos
FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.meals m WHERE m.id = meal_id AND m.user_id = auth.uid())
);
CREATE POLICY "meal photos insert own" ON public.meal_photos
FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.meals m WHERE m.id = meal_id AND m.user_id = auth.uid())
);
CREATE POLICY "meal photos delete own" ON public.meal_photos
FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.meals m WHERE m.id = meal_id AND m.user_id = auth.uid())
);

-- Cocircle
CREATE POLICY "posts read all" ON public.posts FOR SELECT USING (true);
CREATE POLICY "posts insert own" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts update own" ON public.posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "posts delete own" ON public.posts FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "likes read all" ON public.post_likes FOR SELECT USING (true);
CREATE POLICY "likes insert own" ON public.post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes delete own" ON public.post_likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "comments read all" ON public.post_comments FOR SELECT USING (true);
CREATE POLICY "comments insert own" ON public.post_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "comments delete own" ON public.post_comments FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "follows read all" ON public.follows FOR SELECT USING (true);
CREATE POLICY "follows insert own" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "follows delete own" ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- Quests
CREATE POLICY "quests read all" ON public.quests FOR SELECT USING (true);
CREATE POLICY "user quest read own" ON public.user_quest_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user quest upsert own" ON public.user_quest_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user quest update own" ON public.user_quest_progress FOR UPDATE USING (auth.uid() = user_id);

-- Reward events
CREATE POLICY "rewards read own" ON public.reward_events FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "rewards insert own" ON public.reward_events FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Messaging
CREATE POLICY "conversations read own" ON public.conversations FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.conversation_members cm
    WHERE cm.conversation_id = conversations.id AND cm.user_id = auth.uid()
  )
);
CREATE POLICY "conversations insert own" ON public.conversations FOR INSERT WITH CHECK (true);

CREATE POLICY "conversation_members read own" ON public.conversation_members FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "conversation_members insert own" ON public.conversation_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "conversation_members delete own" ON public.conversation_members FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "messages read own" ON public.messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.conversation_members cm
    WHERE cm.conversation_id = messages.conversation_id AND cm.user_id = auth.uid()
  )
);
CREATE POLICY "messages insert own" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "messages update own" ON public.messages FOR UPDATE USING (auth.uid() = sender_id);
CREATE POLICY "messages delete own" ON public.messages FOR DELETE USING (auth.uid() = sender_id);

-- Trainer verifications
CREATE POLICY "trainer verifications read own" ON public.trainer_verifications FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.trainer_profiles tp
    WHERE tp.user_id = trainer_verifications.trainer_id AND tp.user_id = auth.uid()
  )
);
CREATE POLICY "trainer verifications insert own" ON public.trainer_verifications FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trainer_profiles tp
    WHERE tp.user_id = trainer_verifications.trainer_id AND tp.user_id = auth.uid()
  )
);

COMMIT;


-- ============================================
-- Safe Profiles Table Setup - Prevents 500 Error
-- ============================================
-- This script creates a profiles table with nullable fields
-- and a safe trigger that only inserts id + email
-- ============================================

-- ============================================
-- STEP 1: CREATE PROFILES TABLE
-- (Keep most fields NULLABLE to avoid trigger failure)
-- ============================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  email TEXT,
  
  first_name TEXT,
  
  last_name TEXT,
  
  display_name TEXT,
  
  user_id TEXT UNIQUE, -- username/userid for login
  
  phone TEXT,
  
  height_cm NUMERIC,
  
  weight_kg NUMERIC,
  
  bmi NUMERIC,
  
  role TEXT CHECK (role IN ('client', 'trainer')) DEFAULT 'client',
  
  trainer_category TEXT, -- for trainer role
  
  experience_years INTEGER, -- for trainer role
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 2: CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS profiles_role_idx ON public.profiles(role);
CREATE INDEX IF NOT EXISTS profiles_userid_idx ON public.profiles(user_id);

-- ============================================
-- STEP 3: ADD UPDATED_AT TRIGGER (OPTIONAL)
-- ============================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ============================================
-- STEP 4: CREATE SAFE TRIGGER ON auth.users
-- (ONLY INSERT id + email - prevents 500 error)
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles(id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_new_auth_user() TO postgres, service_role;
ALTER FUNCTION public.handle_new_auth_user() OWNER TO postgres;

-- ============================================
-- STEP 5: ENABLE RLS AND POLICIES
-- (Required for client insert/update)
-- ============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can select their own profile
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can insert their own profile
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Policy: Users can update their own profile
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================
-- VERIFICATION (Optional - run to check)
-- ============================================

-- Check table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'profiles'
-- ORDER BY ordinal_position;

-- Check triggers
-- SELECT trigger_name, event_manipulation, event_object_table, action_statement
-- FROM information_schema.triggers
-- WHERE event_object_table = 'profiles' OR event_object_schema = 'auth';















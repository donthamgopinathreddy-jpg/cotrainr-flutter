-- ============================================
-- Fix Signup Trigger Issue
-- ============================================
-- This script fixes the "Database error saving new user" issue
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Check existing triggers (run this first to see what exists)
-- SELECT 
--   tgname as trigger_name,
--   pg_get_triggerdef(oid) as trigger_definition
-- FROM pg_trigger 
-- WHERE tgrelid = 'auth.users'::regclass;

-- Step 2: Drop any problematic triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS auth.handle_new_user() CASCADE;

-- Step 3: Create a safe trigger function that won't fail
-- This creates a minimal profile if one doesn't exist, but won't fail if it does
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username TEXT;
  v_username_lower TEXT;
BEGIN
  -- Get username from metadata or generate one
  v_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    'user_' || substr(NEW.id::text, 1, 8)
  );
  v_username_lower := LOWER(v_username);
  
  -- Try to create profile - use ON CONFLICT to avoid errors
  INSERT INTO public.profiles (id, username, username_lower, email)
  VALUES (
    NEW.id,
    v_username,
    v_username_lower,
    COALESCE(NEW.email, '')
  )
  ON CONFLICT (id) DO NOTHING; -- Don't fail if profile already exists
  
  -- Try to create user_stats - use ON CONFLICT to avoid errors
  INSERT INTO public.user_stats (user_id, total_xp, coins, level)
  VALUES (NEW.id, 0, 0, 1)
  ON CONFLICT (user_id) DO NOTHING; -- Don't fail if stats already exist
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the user creation
    RAISE WARNING 'Error in handle_new_user trigger: %', SQLERRM;
    RETURN NEW; -- Still return NEW so user creation succeeds
END;
$$;

-- Step 4: Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, service_role;

-- Make sure the function has proper ownership
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- ============================================
-- Alternative: If you want to disable triggers entirely
-- (Uncomment the following if you prefer to handle everything in the app)
-- ============================================
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

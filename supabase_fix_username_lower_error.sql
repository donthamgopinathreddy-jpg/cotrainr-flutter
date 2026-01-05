-- ============================================
-- Fix "cannot insert into username_lower" Error
-- ============================================
-- The error: cannot insert a non-DEFAULT value into column "username_lower"
-- This means username_lower is likely a generated column or has a DEFAULT
-- ============================================

-- Step 1: Check the current definition of username_lower
-- Run this first to see what type of column it is:
-- SELECT 
--   column_name,
--   data_type,
--   column_default,
--   is_generated,
--   generation_expression
-- FROM information_schema.columns
-- WHERE table_schema = 'public' 
--   AND table_name = 'profiles'
--   AND column_name = 'username_lower';

-- Step 2: Fix Option A - If username_lower is a generated column, remove it from trigger
-- Drop existing problematic triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Create a safe trigger that doesn't insert into username_lower
-- (Let it be generated automatically or use DEFAULT)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username TEXT;
BEGIN
  -- Get username from metadata or generate one
  v_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    'user_' || substr(NEW.id::text, 1, 8)
  );
  
  -- Insert profile WITHOUT username_lower (let it be generated/default)
  -- Only insert columns that are allowed
  INSERT INTO public.profiles (id, username, email)
  VALUES (
    NEW.id,
    v_username,
    COALESCE(NEW.email, '')
  )
  ON CONFLICT (id) DO NOTHING;
  
  -- Try to create user_stats
  INSERT INTO public.user_stats (user_id, total_xp, coins, level)
  VALUES (NEW.id, 0, 0, 1)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail user creation even if trigger has issues
    RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, service_role;
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- ============================================
-- Step 3: Fix Option B - If username_lower should be manually set
-- Make sure the column allows manual inserts
-- ============================================

-- If username_lower has a DEFAULT that prevents inserts, we need to check:
-- ALTER TABLE public.profiles 
--   ALTER COLUMN username_lower DROP DEFAULT;

-- Or if it's a generated column, we might need to change it:
-- ALTER TABLE public.profiles 
--   ALTER COLUMN username_lower DROP EXPRESSION;

-- ============================================
-- Step 4: Alternative - Disable trigger entirely (RECOMMENDED)
-- Since we handle profile creation in the app, this is safest
-- ============================================

-- Uncomment these lines to completely disable the trigger:
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
















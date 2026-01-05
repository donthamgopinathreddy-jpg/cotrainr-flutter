-- ============================================
-- Add username_lower column to existing profiles table
-- ============================================
-- Run this if you have an existing profiles table without username_lower
-- ============================================

BEGIN;

-- Add username_lower column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'username_lower'
  ) THEN
    -- Add the column as nullable first
    ALTER TABLE public.profiles 
    ADD COLUMN username_lower TEXT;
    
    -- Populate it with lowercase values from username or user_id (whichever exists)
    IF EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'profiles' 
      AND column_name = 'username'
    ) THEN
      -- Use username column if it exists
      UPDATE public.profiles 
      SET username_lower = LOWER(username) 
      WHERE username IS NOT NULL;
      
      -- For rows without username, use a generated unique value based on id
      UPDATE public.profiles 
      SET username_lower = 'user_' || REPLACE(id::TEXT, '-', '')
      WHERE username_lower IS NULL;
    ELSIF EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'profiles' 
      AND column_name = 'user_id'
    ) THEN
      -- Use user_id column if it exists (from safe setup)
      UPDATE public.profiles 
      SET username_lower = LOWER(user_id) 
      WHERE user_id IS NOT NULL;
      
      -- For rows without user_id, use a generated unique value based on id
      UPDATE public.profiles 
      SET username_lower = 'user_' || REPLACE(id::TEXT, '-', '')
      WHERE username_lower IS NULL;
    ELSE
      -- If neither username nor user_id exists, use id-based values
      UPDATE public.profiles 
      SET username_lower = 'user_' || REPLACE(id::TEXT, '-', '')
      WHERE username_lower IS NULL;
    END IF;
    
    -- Now make it NOT NULL (all rows should have values now)
    ALTER TABLE public.profiles 
    ALTER COLUMN username_lower SET NOT NULL;
    
    -- Add unique constraint
    ALTER TABLE public.profiles 
    ADD CONSTRAINT profiles_username_lower_unique UNIQUE (username_lower);
    
    -- Create index
    CREATE INDEX IF NOT EXISTS idx_profiles_username_lower ON public.profiles(username_lower);
  END IF;
END $$;

COMMIT;


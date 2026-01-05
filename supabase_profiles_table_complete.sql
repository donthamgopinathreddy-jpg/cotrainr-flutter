-- ============================================
-- Complete Profiles Table Setup for CoTrainr
-- ============================================
-- This script creates/updates the profiles table with all required fields
-- Fields: email, display_name, user_id (username), phonenumber, height, weight, role, categories
-- ============================================

-- ============================================
-- 1. CREATE/UPDATE PROFILES TABLE
-- ============================================

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- User identification
  username TEXT UNIQUE NOT NULL, -- user_id (username for login)
  username_lower TEXT UNIQUE NOT NULL, -- lowercase version for case-insensitive lookups
  email TEXT UNIQUE NOT NULL,
  display_name TEXT, -- first_name + last_name combined
  
  -- Personal information
  first_name TEXT,
  last_name TEXT,
  phone TEXT, -- phonenumber (format: +91XXXXXXXXXX)
  
  -- Body metrics
  height_cm INTEGER, -- height in centimeters
  weight_kg NUMERIC(5,2), -- weight in kilograms
  bmi NUMERIC(4,2),
  bmi_status TEXT CHECK (bmi_status IN ('underweight', 'normal', 'overweight', 'obese')),
  
  -- User role and preferences
  role TEXT CHECK (role IN ('client', 'trainer')) DEFAULT 'client',
  categories TEXT[] DEFAULT '{}', -- array of categories (e.g., ['boxing', 'yoga', 'strength'])
  
  -- Profile images
  profile_photo_url TEXT,
  cover_photo_url TEXT,
  
  -- Additional fields
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  dob DATE,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Index for username lookups (for login)
CREATE INDEX IF NOT EXISTS idx_profiles_username_lower ON public.profiles(username_lower);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role) WHERE role IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_categories_gin ON public.profiles USING GIN (categories) WHERE categories IS NOT NULL;

-- ============================================
-- 3. CREATE FUNCTION TO AUTO-UPDATE DISPLAY_NAME
-- ============================================

-- Function to automatically update display_name when first_name or last_name changes
CREATE OR REPLACE FUNCTION public.update_display_name()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Combine first_name and last_name
  NEW.display_name := TRIM(
    COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, '')
  );
  
  -- If display_name is just whitespace, set it to NULL
  IF NEW.display_name = '' OR NEW.display_name = ' ' THEN
    NEW.display_name := NULL;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to auto-update display_name
DROP TRIGGER IF EXISTS trigger_update_display_name ON public.profiles;
CREATE TRIGGER trigger_update_display_name
  BEFORE INSERT OR UPDATE OF first_name, last_name ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_display_name();

-- ============================================
-- 4. CREATE FUNCTION TO AUTO-UPDATE UPDATED_AT
-- ============================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Create trigger to auto-update updated_at
DROP TRIGGER IF EXISTS trigger_update_updated_at ON public.profiles;
CREATE TRIGGER trigger_update_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 5. CREATE FUNCTION TO AUTO-CREATE PROFILE ON USER SIGNUP
-- ============================================

-- Function to automatically create a profile when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username TEXT;
  v_email TEXT;
BEGIN
  -- Get username from metadata or generate one
  v_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    'user_' || substr(NEW.id::text, 1, 8)
  );
  
  -- Get email
  v_email := COALESCE(NEW.email, '');
  
  -- Insert profile with basic info (app will update with full details)
  -- Note: We don't insert username_lower here to avoid the "cannot insert into username_lower" error
  -- The app will handle the full profile creation
  INSERT INTO public.profiles (id, username, username_lower, email)
  VALUES (
    NEW.id,
    v_username,
    LOWER(v_username),
    v_email
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail user creation even if profile creation has issues
    RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger on auth.users to auto-create profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, service_role;
ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

-- ============================================
-- 6. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Users can insert their own profile (for initial creation)
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Policy: Allow service role to do everything (for triggers and admin operations)
DROP POLICY IF EXISTS "Service role can manage profiles" ON public.profiles;
CREATE POLICY "Service role can manage profiles"
  ON public.profiles
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- 7. UPDATE EXISTING RECORDS (if any)
-- ============================================

-- Update existing profiles to have display_name if they don't have it
UPDATE public.profiles
SET display_name = TRIM(
  COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')
)
WHERE display_name IS NULL 
  AND (first_name IS NOT NULL OR last_name IS NOT NULL);

-- ============================================
-- 8. ADD COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE public.profiles IS 'User profiles table - stores all user information';
COMMENT ON COLUMN public.profiles.username IS 'User ID (username) - used for login along with email';
COMMENT ON COLUMN public.profiles.username_lower IS 'Lowercase username for case-insensitive lookups';
COMMENT ON COLUMN public.profiles.email IS 'User email address';
COMMENT ON COLUMN public.profiles.display_name IS 'Full display name (first_name + last_name) - auto-generated';
COMMENT ON COLUMN public.profiles.phone IS 'Phone number (format: +91XXXXXXXXXX)';
COMMENT ON COLUMN public.profiles.height_cm IS 'Height in centimeters';
COMMENT ON COLUMN public.profiles.weight_kg IS 'Weight in kilograms';
COMMENT ON COLUMN public.profiles.role IS 'User role: client or trainer';
COMMENT ON COLUMN public.profiles.categories IS 'Array of fitness categories user is interested in';

-- ============================================
-- VERIFICATION QUERIES (Optional - run to check)
-- ============================================

-- Check table structure
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'profiles'
-- ORDER BY ordinal_position;

-- Check indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'profiles';

-- Check triggers
-- SELECT trigger_name, event_manipulation, event_object_table, action_statement
-- FROM information_schema.triggers
-- WHERE event_object_table = 'profiles';















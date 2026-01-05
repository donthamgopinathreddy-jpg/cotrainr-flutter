-- ============================================
-- CoTrainr Supabase Migration - Extend Existing Schema
-- ============================================
-- This script extends your existing tables instead of recreating them
-- ============================================

-- ============================================
-- 1. EXTEND EXISTING PROFILES TABLE
-- ============================================

-- Add new columns to existing profiles table
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  ADD COLUMN IF NOT EXISTS dob DATE,
  ADD COLUMN IF NOT EXISTS height_cm INTEGER,
  ADD COLUMN IF NOT EXISTS weight_kg NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS bmi NUMERIC(4,2),
  ADD COLUMN IF NOT EXISTS bmi_status TEXT CHECK (bmi_status IN ('underweight', 'normal', 'overweight', 'obese')),
  ADD COLUMN IF NOT EXISTS categories TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS cover_photo_url TEXT;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_profiles_username_lower ON public.profiles(username_lower);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role) WHERE role IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_categories_gin ON public.profiles USING GIN (categories) WHERE categories IS NOT NULL;

-- ============================================
-- 2. EXTEND EXISTING TRAINERS TABLE
-- ============================================

-- Add new columns to existing trainers table
ALTER TABLE public.trainers
  ADD COLUMN IF NOT EXISTS categories TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS bio TEXT,
  ADD COLUMN IF NOT EXISTS specialization TEXT;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_trainers_categories_gin ON public.trainers USING GIN (categories) WHERE categories IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_trainers_status ON public.trainers(verified_trainer) WHERE verified_trainer IS NOT NULL;

-- ============================================
-- 3. EXTEND EXISTING TRAINER_VERIFICATIONS TABLE
-- ============================================

-- Add new columns if needed (check what already exists)
ALTER TABLE public.trainer_verifications
  ADD COLUMN IF NOT EXISTS verification_type TEXT,
  ADD COLUMN IF NOT EXISTS document_url TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- ============================================
-- 4. CREATE NEW TABLES (ai_plans, subscriptions)
-- ============================================

-- AI PLANS TABLE
CREATE TABLE IF NOT EXISTS public.ai_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  plan_type TEXT CHECK (plan_type IN ('meal', 'workout')) NOT NULL,
  plan_data JSONB NOT NULL,
  shared_with_trainer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_plans_user_id ON public.ai_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_plans_type ON public.ai_plans(plan_type);
CREATE INDEX IF NOT EXISTS idx_ai_plans_shared_with ON public.ai_plans(shared_with_trainer_id) WHERE shared_with_trainer_id IS NOT NULL;

-- SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  plan_type TEXT CHECK (plan_type IN ('free', 'basic', 'premium')) NOT NULL DEFAULT 'free',
  status TEXT CHECK (status IN ('active', 'cancelled', 'expired')) NOT NULL DEFAULT 'active',
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
CREATE UNIQUE INDEX IF NOT EXISTS uq_subscriptions_user_active
  ON public.subscriptions(user_id)
  WHERE status = 'active';

-- ============================================
-- 5. ENABLE RLS ON NEW TABLES
-- ============================================

ALTER TABLE public.ai_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 6. UPDATE RLS POLICIES FOR PROFILES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view other profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public read user_id" ON public.profiles;
DROP POLICY IF EXISTS "Public read user_id for availability check" ON public.profiles;
DROP POLICY IF EXISTS "Own profile read" ON public.profiles;
DROP POLICY IF EXISTS "Own profile insert" ON public.profiles;
DROP POLICY IF EXISTS "Own profile update" ON public.profiles;

-- Create optimized policies
CREATE POLICY "Own profile read"
  ON public.profiles FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = id);

CREATE POLICY "Own profile insert"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

CREATE POLICY "Own profile update"
  ON public.profiles FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- Public view for limited profile data (using existing columns)
CREATE OR REPLACE VIEW public_profiles AS
SELECT 
  id,
  username AS user_id,
  profile_photo_url,
  cover_photo_url,
  role,
  categories
FROM public.profiles;

ALTER VIEW public_profiles OWNER TO postgres;
GRANT SELECT ON public_profiles TO anon, authenticated;

-- ============================================
-- 7. UPDATE RLS POLICIES FOR TRAINERS
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own trainer" ON public.trainers;
DROP POLICY IF EXISTS "Users can view own trainer record" ON public.trainers;
DROP POLICY IF EXISTS "Anyone can view approved trainers" ON public.trainers;
DROP POLICY IF EXISTS "Public can view approved trainers" ON public.trainers;
DROP POLICY IF EXISTS "Users can insert own trainer" ON public.trainers;
DROP POLICY IF EXISTS "Users can insert own trainer record" ON public.trainers;
DROP POLICY IF EXISTS "Users can update own trainer" ON public.trainers;
DROP POLICY IF EXISTS "Users can update own trainer record" ON public.trainers;
DROP POLICY IF EXISTS "Own trainer read" ON public.trainers;
DROP POLICY IF EXISTS "Public read approved trainers" ON public.trainers;
DROP POLICY IF EXISTS "Own trainer insert" ON public.trainers;
DROP POLICY IF EXISTS "Own trainer update pending" ON public.trainers;

-- Create policies using existing structure (user_id is PK, verified_trainer boolean)
CREATE POLICY "Own trainer read"
  ON public.trainers FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Public read approved trainers"
  ON public.trainers FOR SELECT TO anon, authenticated
  USING (verified_trainer = true);

CREATE POLICY "Own trainer insert"
  ON public.trainers FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own trainer update pending"
  ON public.trainers FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id AND verified_trainer = false)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 8. UPDATE RLS POLICIES FOR TRAINER_VERIFICATIONS
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own verification" ON public.trainer_verifications;
DROP POLICY IF EXISTS "Users can insert own verification" ON public.trainer_verifications;
DROP POLICY IF EXISTS "Users can update own verification" ON public.trainer_verifications;
DROP POLICY IF EXISTS "Own verification read" ON public.trainer_verifications;
DROP POLICY IF EXISTS "Own verification insert" ON public.trainer_verifications;
DROP POLICY IF EXISTS "Own verification update pending" ON public.trainer_verifications;

-- Create policies using existing structure (trainer_id column)
CREATE POLICY "Own verification read"
  ON public.trainer_verifications FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = trainer_id);

CREATE POLICY "Own verification insert"
  ON public.trainer_verifications FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = trainer_id);

CREATE POLICY "Own verification update pending"
  ON public.trainer_verifications FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) = trainer_id
    AND status = 'pending'
  )
  WITH CHECK ((SELECT auth.uid()) = trainer_id);

-- ============================================
-- 9. RLS POLICIES FOR NEW TABLES
-- ============================================

-- AI PLANS POLICIES
DROP POLICY IF EXISTS "Users can view own ai plans" ON public.ai_plans;
DROP POLICY IF EXISTS "Users can insert own ai plans" ON public.ai_plans;
DROP POLICY IF EXISTS "Users can update own ai plans" ON public.ai_plans;
DROP POLICY IF EXISTS "Users can delete own ai plans" ON public.ai_plans;
DROP POLICY IF EXISTS "Own ai plans read" ON public.ai_plans;
DROP POLICY IF EXISTS "Own ai plans insert" ON public.ai_plans;
DROP POLICY IF EXISTS "Own ai plans update" ON public.ai_plans;
DROP POLICY IF EXISTS "Own ai plans delete" ON public.ai_plans;

CREATE POLICY "Own ai plans read"
  ON public.ai_plans FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own ai plans insert"
  ON public.ai_plans FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own ai plans update"
  ON public.ai_plans FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own ai plans delete"
  ON public.ai_plans FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- SUBSCRIPTIONS POLICIES
DROP POLICY IF EXISTS "Users can view own subscription" ON public.subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscription" ON public.subscriptions;
DROP POLICY IF EXISTS "Users can update own subscription" ON public.subscriptions;
DROP POLICY IF EXISTS "Own subscription read" ON public.subscriptions;
DROP POLICY IF EXISTS "Own subscription insert" ON public.subscriptions;
DROP POLICY IF EXISTS "Own subscription update" ON public.subscriptions;

CREATE POLICY "Own subscription read"
  ON public.subscriptions FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own subscription insert"
  ON public.subscriptions FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own subscription update"
  ON public.subscriptions FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 10. TRIGGERS FOR updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Add triggers only if updated_at column exists and trigger doesn't exist
DO $$
BEGIN
  -- Profiles trigger (only if updated_at exists)
  IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' 
              AND table_name = 'profiles' 
              AND column_name = 'updated_at') THEN
    DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
    CREATE TRIGGER update_profiles_updated_at
      BEFORE UPDATE ON public.profiles
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- Trainers trigger
  IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' 
              AND table_name = 'trainers' 
              AND column_name = 'updated_at') THEN
    DROP TRIGGER IF EXISTS update_trainers_updated_at ON public.trainers;
    CREATE TRIGGER update_trainers_updated_at
      BEFORE UPDATE ON public.trainers
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  -- Trainer verifications trigger
  IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' 
              AND table_name = 'trainer_verifications' 
              AND column_name = 'updated_at') THEN
    DROP TRIGGER IF EXISTS update_trainer_verifications_updated_at ON public.trainer_verifications;
    CREATE TRIGGER update_trainer_verifications_updated_at
      BEFORE UPDATE ON public.trainer_verifications
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Triggers for new tables
DROP TRIGGER IF EXISTS update_ai_plans_updated_at ON public.ai_plans;
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON public.subscriptions;

CREATE TRIGGER update_ai_plans_updated_at
  BEFORE UPDATE ON public.ai_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 11. HELPER FUNCTION (Updated for existing schema)
-- ============================================

CREATE OR REPLACE FUNCTION check_user_id_availability(user_id_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF user_id_to_check IS NULL OR user_id_to_check = '' THEN
    RETURN FALSE;
  END IF;

  IF user_id_to_check !~ '^[a-zA-Z0-9_]+$' THEN
    RETURN FALSE;
  END IF;

  -- Use username_lower from existing profiles table
  RETURN NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE username_lower = LOWER(user_id_to_check)
  );
END;
$$;

REVOKE ALL ON FUNCTION check_user_id_availability(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION check_user_id_availability(TEXT) TO anon, authenticated;

-- ============================================
-- 12. STORAGE BUCKETS
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('covers', 'covers', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('posts', 'posts', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('trainer-documents', 'trainer-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================
-- 13. STORAGE POLICIES
-- ============================================

-- Drop all existing storage policies
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
  END LOOP;
END $$;

-- AVATARS POLICIES
CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- COVERS POLICIES
CREATE POLICY "covers_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'covers');

CREATE POLICY "covers_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "covers_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "covers_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- POSTS POLICIES
CREATE POLICY "posts_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'posts');

CREATE POLICY "posts_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "posts_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "posts_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- TRAINER-DOCUMENTS POLICIES
CREATE POLICY "trainer_docs_user_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "trainer_docs_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "trainer_docs_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "trainer_docs_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

SELECT 'Migration complete! Existing tables extended, new tables created, policies updated.' AS status;


















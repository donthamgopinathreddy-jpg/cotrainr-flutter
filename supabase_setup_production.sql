-- ============================================
-- CoTrainr Supabase Production-Ready Setup
-- ============================================
-- Optimized with proper RLS, indexes, and security
-- ============================================

-- ============================================
-- 1. CREATE ENUMS
-- ============================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender_enum') THEN
    CREATE TYPE gender_enum AS ENUM ('male', 'female', 'other');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bmi_status_enum') THEN
    CREATE TYPE bmi_status_enum AS ENUM ('underweight', 'normal', 'overweight', 'obese');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_enum') THEN
    CREATE TYPE role_enum AS ENUM ('client', 'trainer');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trainer_status_enum') THEN
    CREATE TYPE trainer_status_enum AS ENUM ('pending', 'approved', 'rejected');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'plan_type_enum') THEN
    CREATE TYPE plan_type_enum AS ENUM ('free', 'basic', 'premium');
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status_enum') THEN
    CREATE TYPE subscription_status_enum AS ENUM ('active', 'cancelled', 'expired');
  END IF;
END $$;

-- ============================================
-- 2. CREATE TABLES
-- ============================================

-- PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL UNIQUE,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  gender gender_enum,
  dob DATE,
  height_cm INTEGER,
  weight_kg NUMERIC(5,2),
  bmi NUMERIC(4,2),
  bmi_status bmi_status_enum,
  role role_enum NOT NULL DEFAULT 'client',
  categories TEXT[] DEFAULT '{}',
  profile_photo_url TEXT,
  cover_photo_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_lower_user_id ON profiles (LOWER(user_id));
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_categories_gin ON profiles USING GIN (categories);

-- TRAINERS TABLE (references profiles for consistency)
CREATE TABLE IF NOT EXISTS trainers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  years_of_experience INTEGER NOT NULL DEFAULT 0,
  categories TEXT[] DEFAULT '{}',
  status trainer_status_enum NOT NULL DEFAULT 'pending',
  bio TEXT,
  specialization TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trainers_user_id ON trainers(user_id);
CREATE INDEX IF NOT EXISTS idx_trainers_status ON trainers(status);
CREATE INDEX IF NOT EXISTS idx_trainers_categories_gin ON trainers USING GIN (categories);

-- TRAINER_VERIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS trainer_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status trainer_status_enum NOT NULL DEFAULT 'pending',
  verification_type TEXT,
  document_url TEXT,
  notes TEXT,
  verified_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trainer_verifications_user_id ON trainer_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_trainer_verifications_status ON trainer_verifications(status);

-- AI PLANS TABLE
CREATE TABLE IF NOT EXISTS ai_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  plan_type TEXT CHECK (plan_type IN ('meal', 'workout')) NOT NULL,
  plan_data JSONB NOT NULL,
  shared_with_trainer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_plans_user_id ON ai_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_plans_type ON ai_plans(plan_type);
CREATE INDEX IF NOT EXISTS idx_ai_plans_shared_with ON ai_plans(shared_with_trainer_id) WHERE shared_with_trainer_id IS NOT NULL;

-- SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  plan_type plan_type_enum NOT NULL DEFAULT 'free',
  status subscription_status_enum NOT NULL DEFAULT 'active',
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
-- Enforce one active subscription per user
CREATE UNIQUE INDEX IF NOT EXISTS uq_subscriptions_user_active
  ON subscriptions(user_id)
  WHERE status = 'active';

-- ============================================
-- 3. ENABLE RLS
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. RLS POLICIES FOR PROFILES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view other profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Public read user_id" ON profiles;
DROP POLICY IF EXISTS "Public read user_id for availability check" ON profiles;

-- Own profile access
CREATE POLICY "Own profile read"
  ON profiles FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = id);

CREATE POLICY "Own profile insert"
  ON profiles FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

CREATE POLICY "Own profile update"
  ON profiles FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- Public view for limited profile data (via view, not direct table access)
CREATE OR REPLACE VIEW public_profiles AS
SELECT 
  id,
  user_id,
  first_name,
  last_name,
  profile_photo_url,
  cover_photo_url,
  role,
  categories
FROM profiles;

ALTER VIEW public_profiles OWNER TO postgres;
GRANT SELECT ON public_profiles TO anon, authenticated;

-- ============================================
-- 5. RLS POLICIES FOR TRAINERS
-- ============================================

DROP POLICY IF EXISTS "Users can view own trainer" ON trainers;
DROP POLICY IF EXISTS "Users can view own trainer record" ON trainers;
DROP POLICY IF EXISTS "Anyone can view approved trainers" ON trainers;
DROP POLICY IF EXISTS "Users can insert own trainer" ON trainers;
DROP POLICY IF EXISTS "Users can insert own trainer record" ON trainers;
DROP POLICY IF EXISTS "Users can update own trainer" ON trainers;
DROP POLICY IF EXISTS "Users can update own trainer record" ON trainers;

CREATE POLICY "Own trainer read"
  ON trainers FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = (SELECT id FROM profiles WHERE id = trainers.user_id));

CREATE POLICY "Public read approved trainers"
  ON trainers FOR SELECT TO anon, authenticated
  USING (status = 'approved');

CREATE POLICY "Own trainer insert"
  ON trainers FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own trainer update pending"
  ON trainers FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) = user_id 
    AND status = 'pending'
  )
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 6. RLS POLICIES FOR TRAINER_VERIFICATIONS
-- ============================================

DROP POLICY IF EXISTS "Users can view own verification" ON trainer_verifications;
DROP POLICY IF EXISTS "Users can insert own verification" ON trainer_verifications;
DROP POLICY IF EXISTS "Users can update own verification" ON trainer_verifications;

CREATE POLICY "Own verification read"
  ON trainer_verifications FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own verification insert"
  ON trainer_verifications FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own verification update pending"
  ON trainer_verifications FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    AND status = 'pending'
  )
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 7. RLS POLICIES FOR AI_PLANS
-- ============================================

DROP POLICY IF EXISTS "Users can view own ai plans" ON ai_plans;
DROP POLICY IF EXISTS "Users can insert own ai plans" ON ai_plans;
DROP POLICY IF EXISTS "Users can update own ai plans" ON ai_plans;
DROP POLICY IF EXISTS "Users can delete own ai plans" ON ai_plans;

CREATE POLICY "Own ai plans read"
  ON ai_plans FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own ai plans insert"
  ON ai_plans FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own ai plans update"
  ON ai_plans FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own ai plans delete"
  ON ai_plans FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 8. RLS POLICIES FOR SUBSCRIPTIONS
-- ============================================

DROP POLICY IF EXISTS "Users can view own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Users can update own subscription" ON subscriptions;

CREATE POLICY "Own subscription read"
  ON subscriptions FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own subscription insert"
  ON subscriptions FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Own subscription update"
  ON subscriptions FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 9. TRIGGERS FOR updated_at
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

-- Drop existing triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_trainers_updated_at ON trainers;
DROP TRIGGER update_trainer_verifications_updated_at ON trainer_verifications;
DROP TRIGGER IF EXISTS update_ai_plans_updated_at ON ai_plans;
DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;

-- Create triggers for all tables
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trainers_updated_at
  BEFORE UPDATE ON trainers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trainer_verifications_updated_at
  BEFORE UPDATE ON trainer_verifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_plans_updated_at
  BEFORE UPDATE ON ai_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 10. HELPER FUNCTION (Hardened)
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

  RETURN NOT EXISTS (
    SELECT 1 FROM profiles WHERE LOWER(user_id) = LOWER(user_id_to_check)
  );
END;
$$;

REVOKE ALL ON FUNCTION check_user_id_availability(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION check_user_id_availability(TEXT) TO anon, authenticated;

-- ============================================
-- 11. STORAGE BUCKETS
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
-- 12. STORAGE POLICIES
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

SELECT 'Production setup complete! All tables, policies, indexes, and security measures are in place.' AS status;


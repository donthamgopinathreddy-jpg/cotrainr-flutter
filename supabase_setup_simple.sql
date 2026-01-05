-- ============================================
-- CoTrainr Supabase Setup Script (SIMPLE & FIXED)
-- ============================================
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. CREATE TABLES
-- ============================================

-- PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  dob DATE,
  height_cm INTEGER,
  weight_kg NUMERIC(5,2),
  bmi NUMERIC(4,2),
  bmi_status TEXT CHECK (bmi_status IN ('underweight', 'normal', 'overweight', 'obese')),
  role TEXT CHECK (role IN ('client', 'trainer')) DEFAULT 'client',
  categories TEXT[] DEFAULT '{}',
  profile_photo_url TEXT,
  cover_photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- TRAINERS TABLE
CREATE TABLE IF NOT EXISTS trainers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  years_of_experience INTEGER DEFAULT 0,
  categories TEXT[] DEFAULT '{}',
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  bio TEXT,
  specialization TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trainers_user_id ON trainers(user_id);
CREATE INDEX IF NOT EXISTS idx_trainers_status ON trainers(status);

-- TRAINER_VERIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS trainer_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  verification_type TEXT,
  document_url TEXT,
  notes TEXT,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trainer_verifications_user_id ON trainer_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_trainer_verifications_status ON trainer_verifications(status);

-- AI PLANS TABLE
CREATE TABLE IF NOT EXISTS ai_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_type TEXT CHECK (plan_type IN ('meal', 'workout')) NOT NULL,
  plan_data JSONB NOT NULL,
  shared_with_trainer_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_plans_user_id ON ai_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_plans_type ON ai_plans(plan_type);

-- SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  plan_type TEXT CHECK (plan_type IN ('free', 'basic', 'premium')) DEFAULT 'free',
  status TEXT CHECK (status IN ('active', 'cancelled', 'expired')) DEFAULT 'active',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- ============================================
-- 2. ENABLE RLS
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. RLS POLICIES FOR PROFILES
-- ============================================

DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view other profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Public read user_id" ON profiles;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can view other profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Public read user_id"
  ON profiles FOR SELECT
  USING (true);

-- ============================================
-- 4. RLS POLICIES FOR TRAINERS
-- ============================================

DROP POLICY IF EXISTS "Users can view own trainer" ON trainers;
DROP POLICY IF EXISTS "Anyone can view approved trainers" ON trainers;
DROP POLICY IF EXISTS "Users can insert own trainer" ON trainers;
DROP POLICY IF EXISTS "Users can update own trainer" ON trainers;

CREATE POLICY "Users can view own trainer"
  ON trainers FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view approved trainers"
  ON trainers FOR SELECT
  USING (status = 'approved');

CREATE POLICY "Users can insert own trainer"
  ON trainers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trainer"
  ON trainers FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 5. RLS POLICIES FOR TRAINER_VERIFICATIONS
-- ============================================

DROP POLICY IF EXISTS "Users can view own verification" ON trainer_verifications;
DROP POLICY IF EXISTS "Users can insert own verification" ON trainer_verifications;
DROP POLICY IF EXISTS "Users can update own verification" ON trainer_verifications;

CREATE POLICY "Users can view own verification"
  ON trainer_verifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own verification"
  ON trainer_verifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own verification"
  ON trainer_verifications FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 6. RLS POLICIES FOR AI_PLANS
-- ============================================

DROP POLICY IF EXISTS "Users can view own ai plans" ON ai_plans;
DROP POLICY IF EXISTS "Users can insert own ai plans" ON ai_plans;
DROP POLICY IF EXISTS "Users can update own ai plans" ON ai_plans;
DROP POLICY IF EXISTS "Users can delete own ai plans" ON ai_plans;

CREATE POLICY "Users can view own ai plans"
  ON ai_plans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own ai plans"
  ON ai_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own ai plans"
  ON ai_plans FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own ai plans"
  ON ai_plans FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 7. RLS POLICIES FOR SUBSCRIPTIONS
-- ============================================

DROP POLICY IF EXISTS "Users can view own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Users can update own subscription" ON subscriptions;

CREATE POLICY "Users can view own subscription"
  ON subscriptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription"
  ON subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription"
  ON subscriptions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 8. TRIGGERS
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_trainers_updated_at ON trainers;
DROP TRIGGER IF EXISTS update_trainer_verifications_updated_at ON trainer_verifications;

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

-- ============================================
-- 9. HELPER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION check_user_id_availability(user_id_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF user_id_to_check !~ '^[a-zA-Z0-9_]+$' THEN
    RETURN FALSE;
  END IF;
  
  RETURN NOT EXISTS (
    SELECT 1 FROM profiles WHERE LOWER(user_id) = LOWER(user_id_to_check)
  );
END;
$$;

-- ============================================
-- 10. STORAGE BUCKETS (Run separately if needed)
-- ============================================
-- Note: You may need to create buckets manually in Storage section
-- Then run the storage policies below

-- ============================================
-- 11. STORAGE POLICIES (Simplified - No column references)
-- ============================================
-- Only run these AFTER creating buckets manually in Storage section

-- Drop all existing storage policies first
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON storage.objects';
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

SELECT 'Setup complete! Tables and policies created.' AS status;


















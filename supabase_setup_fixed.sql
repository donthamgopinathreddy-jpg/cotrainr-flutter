-- ============================================
-- CoTrainr Supabase Complete Setup Script (FIXED)
-- ============================================
-- Run this script in your Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
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

-- Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- ============================================
-- 2. TRAINERS TABLE
-- ============================================
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

-- ============================================
-- 3. TRAINER_VERIFICATIONS TABLE
-- ============================================
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

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainers ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_verifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view other profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Public read user_id for availability check" ON profiles;

DROP POLICY IF EXISTS "Users can view own trainer record" ON trainers;
DROP POLICY IF EXISTS "Anyone can view approved trainers" ON trainers;
DROP POLICY IF EXISTS "Users can insert own trainer record" ON trainers;
DROP POLICY IF EXISTS "Users can update own trainer record" ON trainers;

DROP POLICY IF EXISTS "Users can view own verification" ON trainer_verifications;
DROP POLICY IF EXISTS "Users can insert own verification" ON trainer_verifications;
DROP POLICY IF EXISTS "Users can update own verification" ON trainer_verifications;

-- ============================================
-- PROFILES POLICIES
-- ============================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can view other profiles (for public profile viewing)
CREATE POLICY "Users can view other profiles"
  ON profiles FOR SELECT
  USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Public read for user_id column (for availability check)
CREATE POLICY "Public read user_id for availability check"
  ON profiles FOR SELECT
  USING (true);

-- ============================================
-- TRAINERS POLICIES
-- ============================================

-- Users can view their own trainer record
CREATE POLICY "Users can view own trainer record"
  ON trainers FOR SELECT
  USING (auth.uid() = user_id);

-- Anyone can view approved trainers
CREATE POLICY "Anyone can view approved trainers"
  ON trainers FOR SELECT
  USING (status = 'approved');

-- Users can insert their own trainer record
CREATE POLICY "Users can insert own trainer record"
  ON trainers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own trainer record (only if pending)
CREATE POLICY "Users can update own trainer record"
  ON trainers FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- TRAINER_VERIFICATIONS POLICIES
-- ============================================

-- Users can view their own verification
CREATE POLICY "Users can view own verification"
  ON trainer_verifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own verification
CREATE POLICY "Users can insert own verification"
  ON trainer_verifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own verification (only if pending)
CREATE POLICY "Users can update own verification"
  ON trainer_verifications FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 5. FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_trainers_updated_at ON trainers;
DROP TRIGGER IF EXISTS update_trainer_verifications_updated_at ON trainer_verifications;

-- Trigger for profiles
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for trainers
CREATE TRIGGER update_trainers_updated_at
  BEFORE UPDATE ON trainers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for trainer_verifications
CREATE TRIGGER update_trainer_verifications_updated_at
  BEFORE UPDATE ON trainer_verifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. HELPER FUNCTIONS
-- ============================================

-- Function to check user_id availability
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
-- 7. STORAGE BUCKETS SETUP
-- ============================================

-- Create avatars bucket (for profile photos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Create covers bucket (for cover photos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'covers',
  'covers',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Create posts bucket (for post images/videos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'posts',
  'posts',
  true,
  52428800,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime'];

-- Create trainer-documents bucket (for verification documents)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'trainer-documents',
  'trainer-documents',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

-- ============================================
-- 8. STORAGE POLICIES
-- ============================================

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Public read access for avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;

DROP POLICY IF EXISTS "Public read access for covers" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own cover" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own cover" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own cover" ON storage.objects;

DROP POLICY IF EXISTS "Public read access for posts" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own posts" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own posts" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own posts" ON storage.objects;

DROP POLICY IF EXISTS "Users can read own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own documents" ON storage.objects;

-- ============================================
-- AVATARS BUCKET POLICIES
-- ============================================

-- Public read access for avatars
CREATE POLICY "Public read access for avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Users can upload their own avatar (folder structure: {user_uuid}/filename)
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own avatar
CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================
-- COVERS BUCKET POLICIES
-- ============================================

-- Public read access for covers
CREATE POLICY "Public read access for covers"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'covers');

-- Users can upload their own cover
CREATE POLICY "Users can upload own cover"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own cover
CREATE POLICY "Users can update own cover"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own cover
CREATE POLICY "Users can delete own cover"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================
-- POSTS BUCKET POLICIES
-- ============================================

-- Public read access for posts
CREATE POLICY "Public read access for posts"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'posts');

-- Users can upload their own posts
CREATE POLICY "Users can upload own posts"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own posts
CREATE POLICY "Users can update own posts"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own posts
CREATE POLICY "Users can delete own posts"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================
-- TRAINER-DOCUMENTS BUCKET POLICIES
-- ============================================

-- Users can read their own documents
CREATE POLICY "Users can read own documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can upload their own documents
CREATE POLICY "Users can upload own documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own documents
CREATE POLICY "Users can update own documents"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own documents
CREATE POLICY "Users can delete own documents"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================
-- 9. ADDITIONAL TABLES
-- ============================================

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

ALTER TABLE ai_plans ENABLE ROW LEVEL SECURITY;

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

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

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
-- COMPLETE
-- ============================================
SELECT 'Setup complete! All tables, policies, and buckets have been created.' AS status;


















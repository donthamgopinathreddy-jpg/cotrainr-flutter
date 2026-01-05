# Supabase Setup Guide

## 1. Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Create a new project or select an existing one
3. Go to **Settings** → **API**
4. Copy your:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (under "Project API keys")

## 2. Configure the App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual credentials:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

## 3. Database Schema

### Required Tables

#### `profiles` table
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  gender TEXT,
  dob DATE,
  height_cm INTEGER,
  weight_kg NUMERIC,
  bmi NUMERIC,
  bmi_status TEXT,
  role TEXT CHECK (role IN ('client', 'trainer')),
  categories TEXT[],
  profile_photo_url TEXT,
  cover_photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Policy: Public read for user_id (for availability check)
CREATE POLICY "Public read user_id for availability check"
  ON profiles FOR SELECT
  USING (true);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

#### `trainers` table
```sql
CREATE TABLE trainers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  years_of_experience INTEGER,
  categories TEXT[],
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE trainers ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own trainer record
CREATE POLICY "Users can view own trainer record"
  ON trainers FOR SELECT
  USING (auth.uid() = user_id);
```

#### `trainer_verifications` table
```sql
CREATE TABLE trainer_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE trainer_verifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own verification
CREATE POLICY "Users can view own verification"
  ON trainer_verifications FOR SELECT
  USING (auth.uid() = user_id);
```

## 4. Storage Setup (for Profile/Cover Photos)

### Create Storage Buckets

1. Go to **Storage** in Supabase Dashboard
2. Create a bucket named `avatars` (for profile photos)
3. Create a bucket named `covers` (for cover photos)
4. Set both buckets to **Public**

### Storage Policies

```sql
-- Policy for avatars bucket
CREATE POLICY "Public read access for avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Policy for covers bucket
CREATE POLICY "Public read access for covers"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'covers');

CREATE POLICY "Users can upload own cover"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'covers' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own cover"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'covers' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## 5. Authentication Settings

1. Go to **Authentication** → **Settings** in Supabase Dashboard
2. Enable **Email** provider
3. Configure email templates (optional)
4. Set **Site URL** to your app's URL

## 6. Testing

After setup:
1. Run the app
2. Try creating an account
3. Check Supabase Dashboard → **Authentication** → **Users** to see the new user
4. Check **Table Editor** → **profiles** to see the profile data

## 7. Troubleshooting

### User ID always shows "Taken"
- Check RLS policies on `profiles` table
- Ensure the "Public read user_id" policy is enabled
- Or create an RPC function with `security definer`:

```sql
CREATE OR REPLACE FUNCTION check_user_id_availability(user_id_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM profiles WHERE user_id = user_id_to_check
  );
END;
$$;
```

### Profile creation fails
- Check that all required fields are provided
- Verify RLS policies allow INSERT
- Check Supabase logs for detailed error messages

## 8. Next Steps

- Set up email verification (optional)
- Configure password reset flow
- Add social login providers (Google, Apple, etc.)
- Set up real-time subscriptions for profile updates


















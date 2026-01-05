# Supabase Quick Setup Guide

## Step 1: Run the SQL Script

1. Go to your Supabase Dashboard: https://nvtozwtuyhwqkqvftpyi.supabase.co
2. Click on **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire contents of `supabase_setup_complete.sql`
5. Paste it into the SQL Editor
6. Click **Run** (or press Ctrl+Enter)

This will create:
- ✅ All required tables
- ✅ Row Level Security (RLS) policies
- ✅ Storage buckets
- ✅ Storage policies
- ✅ Helper functions and triggers

## Step 2: Verify Tables Were Created

1. Go to **Table Editor** in the left sidebar
2. You should see these tables:
   - `profiles`
   - `trainers`
   - `trainer_verifications`
   - `ai_plans`
   - `subscriptions`

## Step 3: Verify Storage Buckets

1. Go to **Storage** in the left sidebar
2. You should see these buckets:
   - `avatars` (Public)
   - `covers` (Public)
   - `posts` (Public)
   - `trainer-documents` (Private)

## Step 4: Test the Connection

1. Run your Flutter app: `flutter run`
2. Try creating a new account
3. Check in Supabase Dashboard:
   - **Authentication** → **Users** (should see new user)
   - **Table Editor** → **profiles** (should see profile data)

## Troubleshooting

### If storage buckets weren't created:
The SQL script tries to create buckets, but if it fails, create them manually:

1. Go to **Storage** → **New bucket**
2. Create each bucket with these settings:

**avatars:**
- Name: `avatars`
- Public: ✅ Yes
- File size limit: 5 MB
- Allowed MIME types: `image/jpeg, image/png, image/webp`

**covers:**
- Name: `covers`
- Public: ✅ Yes
- File size limit: 10 MB
- Allowed MIME types: `image/jpeg, image/png, image/webp`

**posts:**
- Name: `posts`
- Public: ✅ Yes
- File size limit: 50 MB
- Allowed MIME types: `image/jpeg, image/png, image/webp, video/mp4, video/quicktime`

**trainer-documents:**
- Name: `trainer-documents`
- Public: ❌ No (Private)
- File size limit: 10 MB
- Allowed MIME types: `image/jpeg, image/png, image/webp, application/pdf`

### If User ID check always shows "Taken":
1. Go to **Table Editor** → **profiles**
2. Check the RLS policies are enabled
3. Verify the "Public read user_id for availability check" policy exists

### If profile creation fails:
1. Check **Authentication** → **Users** to see if the user was created
2. Check **Logs** in Supabase Dashboard for error messages
3. Verify all required fields are being sent from the app

## Database Schema Overview

### profiles
- Stores user profile information
- Linked to `auth.users` via `id`
- Contains: user_id, email, name, phone, body metrics, role, etc.

### trainers
- Stores trainer-specific information
- Only created when user selects "trainer" role
- Status: pending → approved/rejected

### trainer_verifications
- Stores verification documents for trainers
- Links to trainer's user_id
- Status: pending → approved/rejected

### ai_plans
- Stores AI-generated meal/workout plans
- Can be shared with trainers

### subscriptions
- Stores user subscription plans
- Plans: free, basic, premium

## File Storage Structure

When uploading files, use this structure:
- **Profile photos**: `avatars/{user_id}/profile.jpg`
- **Cover photos**: `covers/{user_id}/cover.jpg`
- **Post media**: `posts/{user_id}/{post_id}/{filename}`
- **Trainer docs**: `trainer-documents/{user_id}/{doc_type}/{filename}`

## Security Notes

- All tables have Row Level Security (RLS) enabled
- Users can only access their own data
- Public read access is limited to necessary fields
- Storage buckets have policies to prevent unauthorized access
- Trainer documents are private (only owner can access)

## Next Steps

After setup:
1. ✅ Test user registration
2. ✅ Test login with email/User ID
3. ✅ Test profile photo upload
4. ✅ Test trainer application flow
5. ✅ Verify data appears correctly in Supabase Dashboard

Your app is now fully connected to Supabase! 🎉


















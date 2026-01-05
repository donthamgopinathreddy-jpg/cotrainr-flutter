# Supabase Edge Function Setup Guide

## What is an Edge Function?

Supabase Edge Functions are serverless backend functions that run on Supabase in Deno. They let you execute private logic securely with your service key on the server, so secrets never go inside the Flutter app.

## Why Use Edge Function for Profile Creation?

1. **Avoids RLS Issues**: Uses service role key, bypasses Row Level Security safely
2. **Prevents 500 Errors**: No database trigger failures during signup
3. **Secure**: Service role key never exposed to client
4. **Reliable**: Server-side logic is more stable than client-side inserts

## Setup Steps

### 1. Install Supabase CLI

```bash
# Install Supabase CLI (if not already installed)
# Windows (PowerShell):
winget install Supabase.CLI

# macOS:
brew install supabase/tap/supabase

# Or download from: https://github.com/supabase/cli/releases
```

### 2. Login to Supabase CLI

```bash
supabase login
```

### 3. Link Your Project

```bash
# Get your project reference ID from Supabase Dashboard
# Dashboard → Settings → General → Reference ID

supabase link --project-ref YOUR_PROJECT_REF
```

### 4. Create the Edge Function

The function file is already created at: `supabase/functions/create_profile/index.ts`

### 5. Set Environment Secrets

```bash
# Set secrets (required for service role access)
supabase secrets set SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="YOUR_SERVICE_ROLE_KEY"
```

**To get your Service Role Key:**
- Go to Supabase Dashboard
- Settings → API
- Copy "service_role" key (NOT the anon key!)

### 6. Test Locally (Optional)

```bash
# Start local Supabase (requires Docker)
supabase start

# Serve functions locally
supabase functions serve create_profile --no-verify-jwt
```

### 7. Deploy to Production

```bash
# Deploy the function
supabase functions deploy create_profile

# Verify deployment
supabase functions list
```

## How It Works

### Flutter Signup Flow:

1. User fills signup form
2. `supabase.auth.signUp()` creates auth user
3. After success, call Edge Function:
   ```dart
   await supabase.functions.invoke('create_profile', body: {...})
   ```
4. Edge Function (server-side):
   - Uses service role key (bypasses RLS)
   - Inserts profile row
   - Calculates BMI
   - Creates trainer_profiles if role is trainer
5. Flutter navigates based on role

### Edge Function Benefits:

- ✅ No RLS blocking issues
- ✅ No trigger failures
- ✅ Service role key secure on server
- ✅ BMI calculated server-side
- ✅ All profile creation in one transaction

## Troubleshooting

### Function Not Found
- Make sure function is deployed: `supabase functions deploy create_profile`
- Check function name matches: `create_profile`

### Authentication Errors
- Verify secrets are set: `supabase secrets list`
- Check service role key is correct

### Database Errors
- Check SQL schema matches function expectations
- Verify all required fields are sent from Flutter
- Check unique constraints (user_id, email)

## Files Created

- `supabase/functions/create_profile/index.ts` - Edge Function code
- `supabase/config.toml` - Local development config
- `EDGE_FUNCTION_SETUP.md` - This guide

## Next Steps

1. Run the setup commands above
2. Deploy the function
3. Test signup flow
4. Monitor function logs in Supabase Dashboard → Edge Functions → Logs















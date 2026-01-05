# Deploy Edge Function - Quick Guide

## Step-by-Step Commands

### 1. Install Supabase CLI (if not installed)

**Windows (PowerShell):**
```powershell
winget install Supabase.CLI
```

**macOS:**
```bash
brew install supabase/tap/supabase
```

**Or download from:** https://github.com/supabase/cli/releases

### 2. Login to Supabase

```bash
supabase login
```
This will open a browser to authenticate.

### 3. Link Your Project

```bash
# Get your project reference ID from:
# Supabase Dashboard → Settings → General → Reference ID

supabase link --project-ref YOUR_PROJECT_REF
```

### 4. Set Secrets (Required!)

```bash
# Get these from Supabase Dashboard → Settings → API

# Your project URL
supabase secrets set SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"

# Your SERVICE ROLE KEY (NOT the anon key!)
# Dashboard → Settings → API → service_role key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="your_service_role_key_here"
```

**⚠️ IMPORTANT:** Never put the service_role key in your Flutter app! Only in Edge Function secrets.

### 5. Deploy the Function

```bash
supabase functions deploy create_profile
```

### 6. Verify Deployment

```bash
# List all deployed functions
supabase functions list

# View function logs
supabase functions logs create_profile
```

## Testing

### Test Locally (Optional)

```bash
# Start local Supabase (requires Docker)
supabase start

# Serve function locally
supabase functions serve create_profile --no-verify-jwt

# Test with curl:
curl -X POST http://localhost:54321/functions/v1/create_profile \
  -H "Content-Type: application/json" \
  -d '{
    "auth_user_id": "test-uuid",
    "email": "test@example.com",
    "user_id": "testuser",
    "first_name": "Test",
    "last_name": "User",
    "phone": "+911234567890",
    "height_cm": 175,
    "weight_kg": 70,
    "role": "client",
    "category": "general",
    "categories": []
  }'
```

### Test in Production

After deployment, test signup in your Flutter app. Check function logs if there are errors:

```bash
supabase functions logs create_profile --follow
```

## Troubleshooting

### "Function not found"
- Make sure function is deployed: `supabase functions deploy create_profile`
- Check function name matches exactly: `create_profile`

### "Authentication failed"
- Verify secrets are set: `supabase secrets list`
- Check service_role key is correct (not anon key)

### "Database error"
- Check SQL schema matches function expectations
- Verify all required fields are sent from Flutter
- Check unique constraints (user_id, email)

### View Function Logs
```bash
# Real-time logs
supabase functions logs create_profile --follow

# Or view in Dashboard:
# Supabase Dashboard → Edge Functions → create_profile → Logs
```

## What the Function Does

1. Receives signup data from Flutter
2. Uses service role key (bypasses RLS)
3. Calculates BMI server-side
4. Inserts profile row
5. Creates trainer_profiles if role is trainer
6. Returns success or error

This prevents "Database error saving new user" because:
- ✅ No RLS blocking (uses service role)
- ✅ No trigger failures (no trigger needed)
- ✅ All validation server-side
- ✅ Secure (service key never in app)















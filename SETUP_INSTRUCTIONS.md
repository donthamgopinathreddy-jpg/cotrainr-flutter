# CoTrainr Setup Instructions

## 🔧 Quick Setup

### 1. Add Your Supabase Credentials

Open `lib/config/supabase_config.dart` and replace the placeholder values:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

**Where to find these:**
1. Go to your Supabase project dashboard
2. Click on "Settings" → "API"
3. Copy the "Project URL" → paste as `supabaseUrl`
4. Copy the "anon public" key → paste as `supabaseAnonKey`

### 2. Run the App

```bash
flutter pub get
flutter run
```

## 📱 App Flow

1. **Login Page** - Users will see login/signup screen first
2. **Main Navigation** - After authentication, users see the main app with:
   - Home page (analytics, CoCircle)
   - Discover page
   - Quests page
   - CoCircle page (social features)
   - Profile page

## 🗄️ Database Setup

Make sure your Supabase database has these tables:
- `users` - User profiles
- `steps` - Daily step counts
- `water_intake` - Daily water intake
- `calories` - Daily calorie data

## ⚠️ Troubleshooting

### App shows blank screen:
- Check if Supabase credentials are correct
- Check console for error messages
- Make sure Supabase is initialized (check logs)

### Login not working:
- Verify Supabase Auth is enabled in your project
- Check email confirmation settings in Supabase

### Database errors:
- Ensure tables exist in Supabase
- Check Row Level Security (RLS) policies

## 📝 Notes

- The app will work without Supabase, but features will be limited
- All data is currently using placeholder values until database is connected
- Steps data comes from sensor service (may show 0 if permissions not granted)







# Signup Fields Saved to Supabase

## Profile Fields Saved During Account Creation

All the following fields are saved to the `profiles` table when a user creates an account:

### Required Fields:
1. **userid** (`username`) - The unique username chosen by the user
2. **email** - User's email address
3. **phonenumber** (`phone`) - User's phone number (format: +91XXXXXXXXXX)
4. **height** (`height_cm`) - User's height in centimeters
5. **weight** (`weight_kg`) - User's weight in kilograms
6. **display_name** - Combined first name + last name
7. **categories** - Array of selected fitness categories

### Additional Fields:
- `first_name` - User's first name
- `last_name` - User's last name
- `username_lower` - Lowercase version of username (for case-insensitive lookups)
- `gender` - User's gender (male/female/other)
- `dob` - Date of birth
- `bmi` - Calculated BMI
- `bmi_status` - BMI category (underweight/normal/overweight/obese)
- `role` - User role (client/trainer)
- `profile_photo_url` - Profile picture URL (null initially, can be set later)
- `cover_photo_url` - Cover image URL (null initially, can be set later)

## Login Support

The login page supports **both**:
- ✅ **Email + Password** - User can login with their email address
- ✅ **User ID + Password** - User can login with their username (userid)

The system automatically detects if the input is an email (contains '@') or a username, and looks up the corresponding email for authentication.

## Database Setup

Run these SQL scripts in Supabase SQL Editor:

1. `supabase_add_display_name.sql` - Adds display_name column and auto-update trigger
2. `supabase_fix_trainer_years_experience.sql` - Adds years_of_experience to trainers table (if not already present)

## Notes

- Profile picture and cover image are optional during signup (set to null initially)
- Users can upload profile/cover images later through the profile edit page
- Display name is automatically generated from first_name + last_name, but can also be set explicitly
- All fields are validated before account creation















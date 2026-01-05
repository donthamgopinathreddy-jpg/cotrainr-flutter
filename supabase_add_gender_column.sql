-- Add gender column to profiles table if it doesn't exist
-- Run this if you already have the profiles table

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('male','female','other','prefer_not_to_say'));

-- Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'profiles' 
  AND column_name = 'gender';













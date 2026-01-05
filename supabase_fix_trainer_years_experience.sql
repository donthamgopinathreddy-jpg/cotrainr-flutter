-- ============================================
-- Fix: Add years_of_experience column to trainers table
-- ============================================
-- This column is required for trainer signup but may be missing
-- ============================================

-- Add years_of_experience column if it doesn't exist
ALTER TABLE public.trainers
  ADD COLUMN IF NOT EXISTS years_of_experience INTEGER DEFAULT 0;

-- Add a comment for documentation
COMMENT ON COLUMN public.trainers.years_of_experience IS 'Number of years of training experience';

-- Verify the column was added
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' 
--   AND table_name = 'trainers'
--   AND column_name = 'years_of_experience';















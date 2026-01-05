-- ============================================
-- Remove Foods Without Micronutrients
-- ============================================
-- This script removes all foods from foods_catalog that don't have
-- micronutrients data (micros_json is NULL or empty)
-- ============================================

BEGIN;

-- Delete foods that don't have micronutrients
DELETE FROM public.foods_catalog
WHERE micros_json IS NULL 
   OR micros_json = '{}'::jsonb
   OR jsonb_typeof(micros_json) = 'null';

-- Show count of remaining foods
SELECT COUNT(*) as remaining_foods_count
FROM public.foods_catalog;

COMMIT;

-- ============================================
-- Note: After running this, make sure to run:
-- 1. supabase_foods_catalog_data.sql (to add foods with micronutrients)
-- 2. supabase_foods_micronutrients_update.sql (to update micronutrients)
-- ============================================


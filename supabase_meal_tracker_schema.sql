-- ============================================
-- CoTrainr Meal Tracker Schema
-- ============================================
-- Complete schema for meal tracking with analytics
-- ============================================
-- 
-- IMPORTANT: This schema requires the 'profiles' table to exist.
-- The profiles table must have an 'id' column of type UUID that references auth.users(id).
-- 
-- If you haven't created the profiles table yet, run one of these first:
-- - supabase_profiles_table_complete.sql (recommended - includes all fields)
-- - supabase_profiles_safe_setup.sql (minimal setup)
-- 
-- Or ensure your existing profiles table has:
--   id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
-- 
-- TROUBLESHOOTING:
-- If you get "column 'user_id' does not exist" error:
-- 1. Ensure profiles table exists with 'id' column (not 'user_id')
-- 2. Drop existing meal tracker tables if they have wrong structure:
--    DROP TABLE IF EXISTS public.meal_items CASCADE;
--    DROP TABLE IF EXISTS public.meal_days CASCADE;
--    DROP TABLE IF EXISTS public.meal_photos CASCADE;
--    DROP TABLE IF EXISTS public.favorites_foods CASCADE;
--    DROP TABLE IF EXISTS public.trainer_meal_sharing CASCADE;
--    DROP TABLE IF EXISTS public.trainer_notes CASCADE;
-- 3. Then run this script again
-- ============================================

BEGIN;

-- ============================================
-- 0. ENSURE PROFILES TABLE EXISTS
-- ============================================
-- IMPORTANT: This schema requires the 'profiles' table to exist
-- with an 'id' column of type UUID that references auth.users(id).
-- 
-- If the profiles table doesn't exist, create it first:
--   CREATE TABLE IF NOT EXISTS public.profiles (
--     id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
--   );
-- 
-- Or run: supabase_profiles_table_complete.sql (recommended)
-- ============================================
-- Create minimal profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);

-- ============================================
-- 1. FOODS CATALOG TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.foods_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  default_unit TEXT NOT NULL, -- 'pcs', 'g', 'ml', 'bowl', 'cup', etc.
  per_unit_grams DECIMAL(10,2) NOT NULL, -- How many grams per unit (e.g., 50g per piece for egg)
  kcal_per_100g DECIMAL(10,2) NOT NULL,
  protein_per_100g DECIMAL(10,2) NOT NULL DEFAULT 0,
  carbs_per_100g DECIMAL(10,2) NOT NULL DEFAULT 0,
  fat_per_100g DECIMAL(10,2) NOT NULL DEFAULT 0,
  fiber_per_100g DECIMAL(10,2) DEFAULT 0,
  sugar_per_100g DECIMAL(10,2) DEFAULT 0,
  sodium_per_100g DECIMAL(10,2) DEFAULT 0,
  iron_per_100g DECIMAL(10,2) DEFAULT 0,
  calcium_per_100g DECIMAL(10,2) DEFAULT 0,
  potassium_per_100g DECIMAL(10,2) DEFAULT 0,
  micros_json JSONB, -- Additional micronutrients
  tags TEXT[], -- Array of tags: ['South Indian', 'Breakfast', 'Protein', etc.]
  is_indian BOOLEAN NOT NULL DEFAULT TRUE,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS foods_catalog_name_idx ON public.foods_catalog USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS foods_catalog_tags_idx ON public.foods_catalog USING gin(tags);
CREATE INDEX IF NOT EXISTS foods_catalog_is_verified_idx ON public.foods_catalog(is_verified);

-- ============================================
-- 2. MEAL DAYS TABLE (Daily Totals)
-- ============================================
CREATE TABLE IF NOT EXISTS public.meal_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  calorie_target INT NOT NULL DEFAULT 2000,
  protein_target DECIMAL(10,2) NOT NULL DEFAULT 120,
  carbs_target DECIMAL(10,2) NOT NULL DEFAULT 250,
  fat_target DECIMAL(10,2) NOT NULL DEFAULT 65,
  total_kcal INT NOT NULL DEFAULT 0,
  total_protein DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_carbs DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_fat DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_water_ml INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, date)
);

CREATE INDEX IF NOT EXISTS meal_days_user_date_idx ON public.meal_days(user_id, date DESC);

-- ============================================
-- 3. MEAL ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.meal_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'snacks', 'dinner', 'custom')),
  food_id UUID NOT NULL REFERENCES public.foods_catalog(id) ON DELETE RESTRICT,
  quantity DECIMAL(10,2) NOT NULL,
  unit TEXT NOT NULL,
  kcal DECIMAL(10,2) NOT NULL, -- Calculated: (quantity * per_unit_grams / 100) * kcal_per_100g
  protein DECIMAL(10,2) NOT NULL DEFAULT 0,
  carbs DECIMAL(10,2) NOT NULL DEFAULT 0,
  fat DECIMAL(10,2) NOT NULL DEFAULT 0,
  fiber DECIMAL(10,2) DEFAULT 0,
  sugar DECIMAL(10,2) DEFAULT 0,
  sodium DECIMAL(10,2) DEFAULT 0,
  iron DECIMAL(10,2) DEFAULT 0,
  calcium DECIMAL(10,2) DEFAULT 0,
  potassium DECIMAL(10,2) DEFAULT 0,
  micros_json JSONB, -- Additional micronutrients
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS meal_items_user_date_idx ON public.meal_items(user_id, date DESC);
CREATE INDEX IF NOT EXISTS meal_items_meal_type_idx ON public.meal_items(user_id, date, meal_type);
CREATE INDEX IF NOT EXISTS meal_items_food_idx ON public.meal_items(food_id);

-- ============================================
-- 4. MEAL PHOTOS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.meal_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'snacks', 'dinner', 'custom')),
  storage_path TEXT NOT NULL, -- Path in Supabase Storage
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days')
);

CREATE INDEX IF NOT EXISTS meal_photos_user_date_idx ON public.meal_photos(user_id, date DESC);
CREATE INDEX IF NOT EXISTS meal_photos_expires_at_idx ON public.meal_photos(expires_at);

-- ============================================
-- 5. FAVORITES FOODS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.favorites_foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  food_id UUID NOT NULL REFERENCES public.foods_catalog(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, food_id)
);

CREATE INDEX IF NOT EXISTS favorites_foods_user_idx ON public.favorites_foods(user_id);

-- ============================================
-- 6. TRAINER MEAL SHARING TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.trainer_meal_sharing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  share_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (trainer_id, client_id)
);

CREATE INDEX IF NOT EXISTS trainer_meal_sharing_trainer_idx ON public.trainer_meal_sharing(trainer_id);
CREATE INDEX IF NOT EXISTS trainer_meal_sharing_client_idx ON public.trainer_meal_sharing(client_id);

-- ============================================
-- 7. TRAINER NOTES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.trainer_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  note_text TEXT NOT NULL,
  note_type TEXT CHECK (note_type IN ('meal_plan', 'suggestion', 'feedback', 'other')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS trainer_notes_trainer_client_idx ON public.trainer_notes(trainer_id, client_id, date DESC);

-- ============================================
-- 8. RLS POLICIES
-- ============================================

-- Foods Catalog - Public read access
ALTER TABLE public.foods_catalog ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view verified foods" ON public.foods_catalog;
CREATE POLICY "Anyone can view verified foods"
  ON public.foods_catalog FOR SELECT
  USING (is_verified = TRUE);

-- Meal Days
ALTER TABLE public.meal_days ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own meal days" ON public.meal_days;
CREATE POLICY "Users can manage their own meal days"
  ON public.meal_days FOR ALL
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Trainers can view client meal days" ON public.meal_days;
CREATE POLICY "Trainers can view client meal days"
  ON public.meal_days FOR SELECT
  USING (
    user_id IN (
      SELECT client_id FROM public.trainer_meal_sharing
      WHERE trainer_id = auth.uid()
        AND share_enabled = TRUE
    )
  );

-- Meal Items
ALTER TABLE public.meal_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own meal items" ON public.meal_items;
CREATE POLICY "Users can manage their own meal items"
  ON public.meal_items FOR ALL
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Trainers can view client meal items" ON public.meal_items;
CREATE POLICY "Trainers can view client meal items"
  ON public.meal_items FOR SELECT
  USING (
    user_id IN (
      SELECT client_id FROM public.trainer_meal_sharing
      WHERE trainer_id = auth.uid()
        AND share_enabled = TRUE
    )
  );

-- Meal Photos
ALTER TABLE public.meal_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own meal photos" ON public.meal_photos;
CREATE POLICY "Users can manage their own meal photos"
  ON public.meal_photos FOR ALL
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Trainers can view client meal photos" ON public.meal_photos;
CREATE POLICY "Trainers can view client meal photos"
  ON public.meal_photos FOR SELECT
  USING (
    user_id IN (
      SELECT client_id FROM public.trainer_meal_sharing
      WHERE trainer_id = auth.uid()
        AND share_enabled = TRUE
    )
  );

-- Favorites Foods
ALTER TABLE public.favorites_foods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own favorites" ON public.favorites_foods;
CREATE POLICY "Users can manage their own favorites"
  ON public.favorites_foods FOR ALL
  USING (auth.uid() = user_id);

-- Trainer Meal Sharing
ALTER TABLE public.trainer_meal_sharing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their trainer sharing" ON public.trainer_meal_sharing;
CREATE POLICY "Users can manage their trainer sharing"
  ON public.trainer_meal_sharing FOR ALL
  USING (auth.uid() = client_id OR auth.uid() = trainer_id);

-- Trainer Notes
ALTER TABLE public.trainer_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trainers and clients can manage notes" ON public.trainer_notes;
CREATE POLICY "Trainers and clients can manage notes"
  ON public.trainer_notes FOR ALL
  USING (auth.uid() = trainer_id OR auth.uid() = client_id);

-- ============================================
-- 9. TRIGGERS - Auto Update Meal Days Totals
-- ============================================

-- Function to update meal_days totals
CREATE OR REPLACE FUNCTION public.update_meal_days_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  date_val DATE;
  user_id_val UUID;
  new_totals RECORD;
BEGIN
  -- Get date and user_id from trigger context
  IF TG_OP = 'DELETE' THEN
    date_val := OLD.date;
    user_id_val := OLD.user_id;
  ELSE
    date_val := NEW.date;
    user_id_val := NEW.user_id;
  END IF;
  
  -- Calculate totals for the date
  SELECT 
    COALESCE(SUM(kcal)::INT, 0) as total_kcal,
    COALESCE(SUM(protein), 0) as total_protein,
    COALESCE(SUM(carbs), 0) as total_carbs,
    COALESCE(SUM(fat), 0) as total_fat
  INTO new_totals
  FROM public.meal_items
  WHERE user_id = user_id_val AND date = date_val;
  
  -- Update or insert meal_days
  INSERT INTO public.meal_days (user_id, date, total_kcal, total_protein, total_carbs, total_fat, updated_at)
  VALUES (user_id_val, date_val, new_totals.total_kcal, new_totals.total_protein, new_totals.total_carbs, new_totals.total_fat, NOW())
  ON CONFLICT (user_id, date)
  DO UPDATE SET
    total_kcal = new_totals.total_kcal,
    total_protein = new_totals.total_protein,
    total_carbs = new_totals.total_carbs,
    total_fat = new_totals.total_fat,
    updated_at = NOW();
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Trigger on meal_items
DROP TRIGGER IF EXISTS meal_items_update_totals_trigger ON public.meal_items;
CREATE TRIGGER meal_items_update_totals_trigger
  AFTER INSERT OR UPDATE OR DELETE ON public.meal_items
  FOR EACH ROW
  EXECUTE FUNCTION public.update_meal_days_totals();

-- ============================================
-- 10. FUNCTION - Cleanup Expired Photos
-- ============================================

CREATE OR REPLACE FUNCTION public.cleanup_expired_meal_photos()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete expired photo records
  -- Note: This should be called by a scheduled job
  -- Storage files should be deleted separately via Storage API
  DELETE FROM public.meal_photos
  WHERE expires_at < NOW();
END;
$$;

-- ============================================
-- 11. SAMPLE INDIAN FOODS DATA
-- ============================================

-- South Indian Breakfast
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, tags, is_verified) VALUES
  ('Idli', 'pcs', 50, 106, 3.5, 25.0, 0.5, 1.2, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Dosa', 'pcs', 120, 160, 2.5, 30.0, 5.0, 1.5, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Vada', 'pcs', 60, 220, 4.5, 35.0, 8.0, 2.0, ARRAY['South Indian', 'Breakfast', 'Snacks'], TRUE),
  ('Upma', 'bowl', 200, 180, 3.0, 28.0, 6.0, 1.8, ARRAY['South Indian', 'Breakfast'], TRUE),
  ('Pongal', 'bowl', 250, 190, 4.0, 32.0, 5.0, 2.0, ARRAY['South Indian', 'Breakfast'], TRUE)
ON CONFLICT DO NOTHING;

-- North Indian Breads
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, tags, is_verified) VALUES
  ('Roti', 'pcs', 35, 260, 9.0, 50.0, 2.0, 2.5, ARRAY['North Indian'], TRUE),
  ('Chapati', 'pcs', 40, 270, 10.0, 48.0, 2.5, 2.8, ARRAY['North Indian'], TRUE),
  ('Naan', 'pcs', 90, 280, 8.0, 52.0, 6.0, 2.0, ARRAY['North Indian'], TRUE),
  ('Paratha', 'pcs', 80, 320, 7.5, 45.0, 12.0, 2.2, ARRAY['North Indian', 'Breakfast'], TRUE)
ON CONFLICT DO NOTHING;

-- Proteins
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, tags, is_verified) VALUES
  ('Paneer', 'g', 1, 265, 18.0, 2.0, 20.0, ARRAY['North Indian', 'Protein'], TRUE),
  ('Egg', 'pcs', 50, 155, 13.0, 1.1, 11.0, ARRAY['Protein'], TRUE),
  ('Chicken Breast', 'g', 1, 165, 31.0, 0.0, 3.6, ARRAY['Protein'], TRUE),
  ('Chicken Curry', 'bowl', 200, 200, 15.0, 8.0, 12.0, ARRAY['North Indian', 'Protein', 'Lunch', 'Dinner'], TRUE),
  ('Paneer Butter Masala', 'bowl', 200, 250, 12.0, 10.0, 18.0, ARRAY['North Indian', 'Protein', 'Lunch', 'Dinner'], TRUE),
  ('Dal', 'bowl', 150, 120, 7.0, 20.0, 2.0, ARRAY['North Indian', 'Protein', 'Lunch', 'Dinner'], TRUE)
ON CONFLICT DO NOTHING;

-- Rice Dishes
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, tags, is_verified) VALUES
  ('Biryani', 'bowl', 250, 300, 8.0, 45.0, 12.0, ARRAY['North Indian', 'Lunch', 'Dinner'], TRUE),
  ('Plain Rice', 'bowl', 150, 130, 2.7, 28.0, 0.3, ARRAY['Lunch', 'Dinner'], TRUE),
  ('Curd Rice', 'bowl', 200, 170, 3.5, 32.0, 4.0, ARRAY['South Indian', 'Lunch', 'Dinner'], TRUE)
ON CONFLICT DO NOTHING;

-- Fruits
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, tags, is_verified) VALUES
  ('Banana', 'pcs', 120, 89, 1.1, 23.0, 0.3, 2.6, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Apple', 'pcs', 150, 52, 0.3, 14.0, 0.2, 2.4, ARRAY['Fruits', 'Snacks'], TRUE),
  ('Mango', 'pcs', 200, 60, 0.8, 15.0, 0.4, 1.6, ARRAY['Fruits'], TRUE)
ON CONFLICT DO NOTHING;

-- Dairy
INSERT INTO public.foods_catalog (name, default_unit, per_unit_grams, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, tags, is_verified) VALUES
  ('Milk', 'ml', 1, 42, 3.4, 5.0, 1.0, ARRAY['Dairy'], TRUE),
  ('Curd/Yogurt', 'bowl', 200, 59, 10.0, 3.6, 0.4, ARRAY['Dairy'], TRUE),
  ('Buttermilk', 'ml', 1, 38, 3.3, 4.8, 1.0, ARRAY['Dairy'], TRUE)
ON CONFLICT DO NOTHING;

COMMIT;


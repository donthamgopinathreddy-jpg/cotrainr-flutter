-- ============================================
-- NEARBY MAP SETUP - PostGIS & RPC Function
-- ============================================
-- This script enables PostGIS extension and creates
-- an RPC function to find nearby trainers, nutritionists, and centers
-- ============================================

-- Step 1: Enable PostGIS extension (run once per database)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Step 2: Ensure profiles table has lat/lng columns
-- (Add these if they don't exist)
DO $$
BEGIN
  -- Add lat column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'lat'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN lat DOUBLE PRECISION;
  END IF;

  -- Add lng column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'lng'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN lng DOUBLE PRECISION;
  END IF;

  -- Add rating column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'rating'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN rating NUMERIC(3,2) DEFAULT 0.0;
  END IF;
END $$;

-- Step 3: Create centers table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.centers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  rating NUMERIC(3,2) DEFAULT 0.0,
  address TEXT,
  phone TEXT,
  website TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: Create RPC function for nearby entities
CREATE OR REPLACE FUNCTION public.nearby_entities(
  in_lat DOUBLE PRECISION,
  in_lng DOUBLE PRECISION,
  in_radius_m INTEGER DEFAULT 5000,
  in_kind TEXT DEFAULT 'all'  -- 'trainer' | 'nutritionist' | 'center' | 'all'
)
RETURNS TABLE(
  kind TEXT,
  id UUID,
  name TEXT,
  rating NUMERIC,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  distance_m DOUBLE PRECISION,
  avatar_url TEXT
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  WITH me AS (
    SELECT ST_SetSRID(ST_MakePoint(in_lng, in_lat), 4326)::geography AS g
  ),
  trainers AS (
    SELECT
      'trainer'::TEXT AS kind,
      p.id,
      COALESCE(p.display_name, p.first_name || ' ' || p.last_name, 'Trainer') AS name,
      COALESCE(p.rating, 0.0) AS rating,
      p.lat,
      p.lng,
      ST_Distance(
        ST_SetSRID(ST_MakePoint(p.lng, p.lat), 4326)::geography,
        (SELECT g FROM me)
      ) AS distance_m,
      p.avatar_path AS avatar_url
    FROM public.profiles p, me
    WHERE p.role = 'trainer'
      AND p.lat IS NOT NULL 
      AND p.lng IS NOT NULL
      AND ST_DWithin(
        ST_SetSRID(ST_MakePoint(p.lng, p.lat), 4326)::geography,
        me.g,
        in_radius_m
      )
  ),
  nutritionists AS (
    SELECT
      'nutritionist'::TEXT AS kind,
      p.id,
      COALESCE(p.display_name, p.first_name || ' ' || p.last_name, 'Nutritionist') AS name,
      COALESCE(p.rating, 0.0) AS rating,
      p.lat,
      p.lng,
      ST_Distance(
        ST_SetSRID(ST_MakePoint(p.lng, p.lat), 4326)::geography,
        (SELECT g FROM me)
      ) AS distance_m,
      p.avatar_path AS avatar_url
    FROM public.profiles p, me
    WHERE p.role = 'nutritionist'
      AND p.lat IS NOT NULL 
      AND p.lng IS NOT NULL
      AND ST_DWithin(
        ST_SetSRID(ST_MakePoint(p.lng, p.lat), 4326)::geography,
        me.g,
        in_radius_m
      )
  ),
  centers AS (
    SELECT
      'center'::TEXT AS kind,
      c.id,
      c.name,
      COALESCE(c.rating, 0.0) AS rating,
      c.lat,
      c.lng,
      ST_Distance(
        ST_SetSRID(ST_MakePoint(c.lng, c.lat), 4326)::geography,
        (SELECT g FROM me)
      ) AS distance_m,
      NULL::TEXT AS avatar_url
    FROM public.centers c, me
    WHERE COALESCE(c.is_active, TRUE) = TRUE
      AND c.lat IS NOT NULL 
      AND c.lng IS NOT NULL
      AND ST_DWithin(
        ST_SetSRID(ST_MakePoint(c.lng, c.lat), 4326)::geography,
        me.g,
        in_radius_m
      )
  )
  SELECT * FROM trainers WHERE in_kind IN ('all', 'trainer')
  UNION ALL
  SELECT * FROM nutritionists WHERE in_kind IN ('all', 'nutritionist')
  UNION ALL
  SELECT * FROM centers WHERE in_kind IN ('all', 'center')
  ORDER BY distance_m ASC
  LIMIT 200;
$$;

-- Step 5: Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.nearby_entities TO authenticated;
GRANT EXECUTE ON FUNCTION public.nearby_entities TO anon;

-- Step 6: RLS policies for centers table
ALTER TABLE public.centers ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read active centers
CREATE POLICY "Anyone can view active centers"
  ON public.centers
  FOR SELECT
  USING (is_active = TRUE);

-- ============================================
-- NOTES:
-- 1. Make sure to add Google Maps API key in:
--    - Android: android/app/src/main/AndroidManifest.xml
--    - iOS: ios/Runner/AppDelegate.swift or Info.plist
-- 
-- 2. Location permissions required:
--    - Android: ACCESS_FINE_LOCATION in AndroidManifest.xml
--    - iOS: NSLocationWhenInUseUsageDescription in Info.plist
-- 
-- 3. Update profiles table with lat/lng for trainers/nutritionists
-- 4. Add centers data to centers table
-- ============================================


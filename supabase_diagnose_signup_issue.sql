-- ============================================
-- Diagnose Signup Issue
-- ============================================
-- Run this FIRST to see what's causing the problem
-- ============================================

-- 1. Check for triggers on auth.users
SELECT 
  tgname as trigger_name,
  pg_get_triggerdef(oid) as trigger_definition,
  tgenabled as is_enabled
FROM pg_trigger 
WHERE tgrelid = 'auth.users'::regclass;

-- 2. Check profiles table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 3. Check if profiles table has required constraints
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.profiles'::regclass;

-- 4. Check for any functions that might be called
SELECT 
  proname as function_name,
  pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname LIKE '%user%' 
  AND pronamespace = 'public'::regnamespace;
















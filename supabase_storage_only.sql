-- ============================================
-- PART 2: STORAGE BUCKETS AND POLICIES
-- ============================================
-- Run this AFTER creating buckets manually OR if buckets already exist
-- ============================================
-- IMPORTANT: Create buckets manually first in Storage section:
-- 1. Go to Storage → New bucket
-- 2. Create: avatars (public), covers (public), posts (public), trainer-documents (private)
-- ============================================

-- ============================================
-- 1. CREATE STORAGE BUCKETS (if not created manually)
-- ============================================

-- Try to create buckets (may fail if already exist - that's okay)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('covers', 'covers', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('posts', 'posts', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('trainer-documents', 'trainer-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. DROP EXISTING STORAGE POLICIES
-- ============================================

-- Drop all existing policies on storage.objects
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
  END LOOP;
END $$;

-- ============================================
-- 3. STORAGE POLICIES FOR AVATARS
-- ============================================

CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================
-- 4. STORAGE POLICIES FOR COVERS
-- ============================================

CREATE POLICY "covers_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'covers');

CREATE POLICY "covers_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "covers_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "covers_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'covers' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================
-- 5. STORAGE POLICIES FOR POSTS
-- ============================================

CREATE POLICY "posts_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'posts');

CREATE POLICY "posts_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "posts_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "posts_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'posts' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================
-- 6. STORAGE POLICIES FOR TRAINER-DOCUMENTS
-- ============================================

CREATE POLICY "trainer_docs_user_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "trainer_docs_user_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "trainer_docs_user_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "trainer_docs_user_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'trainer-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

SELECT 'Storage policies created successfully!' AS status;


















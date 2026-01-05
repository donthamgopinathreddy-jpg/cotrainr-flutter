-- ============================================
-- CoCircle (Community) Tables for Supabase
-- ============================================
-- Posts, Likes, Comments, Follows
-- ============================================

-- ============================================
-- 1. POSTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  caption TEXT,
  media_url TEXT, -- URL to image/video in storage
  media_type TEXT CHECK (media_type IN ('photo', 'video')) DEFAULT 'photo',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);

-- ============================================
-- 2. POST LIKES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, user_id) -- One like per user per post
);

CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON public.post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON public.post_likes(user_id);

-- ============================================
-- 3. POST COMMENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  comment_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON public.post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_user_id ON public.post_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_created_at ON public.post_comments(created_at DESC);

-- ============================================
-- 4. FOLLOWS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(follower_id, following_id), -- One follow relationship per pair
  CHECK (follower_id != following_id) -- Can't follow yourself
);

CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);

-- ============================================
-- 5. ENABLE RLS
-- ============================================

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 6. RLS POLICIES FOR POSTS
-- ============================================

DROP POLICY IF EXISTS "Anyone can view posts" ON public.posts;
DROP POLICY IF EXISTS "Users can create own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;

-- Public read (anyone can view posts)
CREATE POLICY "Public read posts"
  ON public.posts FOR SELECT
  TO anon, authenticated
  USING (true);

-- Users can create their own posts
CREATE POLICY "Users can create own posts"
  ON public.posts FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can update their own posts
CREATE POLICY "Users can update own posts"
  ON public.posts FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can delete their own posts
CREATE POLICY "Users can delete own posts"
  ON public.posts FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 7. RLS POLICIES FOR POST LIKES
-- ============================================

DROP POLICY IF EXISTS "Anyone can view likes" ON public.post_likes;
DROP POLICY IF EXISTS "Users can like posts" ON public.post_likes;
DROP POLICY IF EXISTS "Users can unlike own likes" ON public.post_likes;

-- Public read (anyone can view likes)
CREATE POLICY "Public read likes"
  ON public.post_likes FOR SELECT
  TO anon, authenticated
  USING (true);

-- Users can like posts
CREATE POLICY "Users can like posts"
  ON public.post_likes FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can unlike (delete) their own likes
CREATE POLICY "Users can unlike own likes"
  ON public.post_likes FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 8. RLS POLICIES FOR POST COMMENTS
-- ============================================

DROP POLICY IF EXISTS "Anyone can view comments" ON public.post_comments;
DROP POLICY IF EXISTS "Users can create comments" ON public.post_comments;
DROP POLICY IF EXISTS "Users can update own comments" ON public.post_comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON public.post_comments;

-- Public read (anyone can view comments)
CREATE POLICY "Public read comments"
  ON public.post_comments FOR SELECT
  TO anon, authenticated
  USING (true);

-- Users can create comments
CREATE POLICY "Users can create comments"
  ON public.post_comments FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can update their own comments
CREATE POLICY "Users can update own comments"
  ON public.post_comments FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments"
  ON public.post_comments FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================
-- 9. RLS POLICIES FOR FOLLOWS
-- ============================================

DROP POLICY IF EXISTS "Anyone can view follows" ON public.follows;
DROP POLICY IF EXISTS "Users can follow others" ON public.follows;
DROP POLICY IF EXISTS "Users can unfollow" ON public.follows;

-- Public read (anyone can view follow relationships)
CREATE POLICY "Public read follows"
  ON public.follows FOR SELECT
  TO anon, authenticated
  USING (true);

-- Users can follow others
CREATE POLICY "Users can follow others"
  ON public.follows FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = follower_id);

-- Users can unfollow (delete their follow relationships)
CREATE POLICY "Users can unfollow"
  ON public.follows FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = follower_id);

-- ============================================
-- 10. TRIGGERS FOR updated_at
-- ============================================

DROP TRIGGER IF EXISTS update_posts_updated_at ON public.posts;
DROP TRIGGER IF EXISTS update_post_comments_updated_at ON public.post_comments;

CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_post_comments_updated_at
  BEFORE UPDATE ON public.post_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 11. HELPER FUNCTIONS (for getting counts)
-- ============================================

-- Function to get like count for a post
CREATE OR REPLACE FUNCTION get_post_like_count(post_id_param UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(*)::INTEGER
  FROM public.post_likes
  WHERE post_id = post_id_param;
$$;

-- Function to get comment count for a post
CREATE OR REPLACE FUNCTION get_post_comment_count(post_id_param UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(*)::INTEGER
  FROM public.post_comments
  WHERE post_id = post_id_param;
$$;

-- Function to check if user liked a post
CREATE OR REPLACE FUNCTION is_post_liked_by_user(post_id_param UUID, user_id_param UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS(
    SELECT 1
    FROM public.post_likes
    WHERE post_id = post_id_param AND user_id = user_id_param
  );
$$;

-- Function to get follower count
CREATE OR REPLACE FUNCTION get_follower_count(user_id_param UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(*)::INTEGER
  FROM public.follows
  WHERE following_id = user_id_param;
$$;

-- Function to get following count
CREATE OR REPLACE FUNCTION get_following_count(user_id_param UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
  SELECT COUNT(*)::INTEGER
  FROM public.follows
  WHERE follower_id = user_id_param;
$$;

-- Function to check if user follows another user
CREATE OR REPLACE FUNCTION is_following(follower_id_param UUID, following_id_param UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS(
    SELECT 1
    FROM public.follows
    WHERE follower_id = follower_id_param AND following_id = following_id_param
  );
$$;

GRANT EXECUTE ON FUNCTION get_post_like_count(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_post_comment_count(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_post_liked_by_user(UUID, UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_follower_count(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_following_count(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION is_following(UUID, UUID) TO anon, authenticated;

SELECT 'CoCircle schema complete! Tables: posts, post_likes, post_comments, follows. RLS policies and helper functions created.' AS status;



















-- Posts table (band wall/feed)
CREATE TABLE public.posts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  artist_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  text TEXT NOT NULL DEFAULT '',
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Posts are viewable by everyone" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Artists can create own posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = artist_id);
CREATE POLICY "Artists can delete own posts" ON public.posts FOR DELETE USING (auth.uid() = artist_id);
CREATE POLICY "Admins can delete posts" ON public.posts FOR DELETE USING (has_role(auth.uid(), 'admin'::app_role));

-- Post likes table
CREATE TABLE public.post_likes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(post_id, user_id)
);
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Likes are viewable by everyone" ON public.post_likes FOR SELECT USING (true);
CREATE POLICY "Users can like" ON public.post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike" ON public.post_likes FOR DELETE USING (auth.uid() = user_id);

-- Classifieds table
CREATE TABLE public.classifieds (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  category TEXT NOT NULL DEFAULT '',
  estado TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL DEFAULT '',
  contact TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
ALTER TABLE public.classifieds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Classifieds are viewable by everyone" ON public.classifieds FOR SELECT USING (true);
CREATE POLICY "Users can create own classifieds" ON public.classifieds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own classifieds" ON public.classifieds FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own classifieds" ON public.classifieds FOR DELETE USING (auth.uid() = user_id);

-- Add exclusive flag to content table
ALTER TABLE public.content ADD COLUMN is_exclusive BOOLEAN NOT NULL DEFAULT false;

-- Enable realtime for posts
ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.post_likes;

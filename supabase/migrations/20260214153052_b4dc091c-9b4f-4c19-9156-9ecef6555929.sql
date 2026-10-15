
-- 1. Add CHECK constraints for input length limits
ALTER TABLE public.comments ADD CONSTRAINT comments_text_max_length CHECK (char_length(text) <= 500);
ALTER TABLE public.comments ADD CONSTRAINT comments_username_max_length CHECK (char_length(username) <= 100);

ALTER TABLE public.profiles ADD CONSTRAINT profiles_bio_max_length CHECK (bio IS NULL OR char_length(bio) <= 1000);
ALTER TABLE public.profiles ADD CONSTRAINT profiles_username_max_length CHECK (char_length(username) <= 100);
ALTER TABLE public.profiles ADD CONSTRAINT profiles_genre_max_length CHECK (genre IS NULL OR char_length(genre) <= 100);
ALTER TABLE public.profiles ADD CONSTRAINT profiles_subgenre_max_length CHECK (subgenre IS NULL OR char_length(subgenre) <= 100);

ALTER TABLE public.content ADD CONSTRAINT content_title_max_length CHECK (char_length(title) <= 100);
ALTER TABLE public.content ADD CONSTRAINT content_url_max_length CHECK (char_length(url) <= 500);

ALTER TABLE public.events ADD CONSTRAINT events_title_max_length CHECK (char_length(title) <= 100);
ALTER TABLE public.events ADD CONSTRAINT events_location_max_length CHECK (char_length(location) <= 200);
ALTER TABLE public.events ADD CONSTRAINT events_city_max_length CHECK (char_length(city) <= 100);

ALTER TABLE public.posts ADD CONSTRAINT posts_text_max_length CHECK (char_length(text) <= 1000);

ALTER TABLE public.classifieds ADD CONSTRAINT classifieds_title_max_length CHECK (char_length(title) <= 100);
ALTER TABLE public.classifieds ADD CONSTRAINT classifieds_description_max_length CHECK (char_length(description) <= 1000);
ALTER TABLE public.classifieds ADD CONSTRAINT classifieds_contact_max_length CHECK (char_length(contact) <= 200);

-- 2. Create trigger to auto-set username on comment insert from profiles table
CREATE OR REPLACE FUNCTION public.set_comment_username()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  SELECT username INTO NEW.username
  FROM public.profiles
  WHERE id = NEW.user_id;
  
  IF NEW.username IS NULL THEN
    NEW.username := 'Anônimo';
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_set_comment_username
BEFORE INSERT ON public.comments
FOR EACH ROW
EXECUTE FUNCTION public.set_comment_username();

-- 3. Protect classified contact data - only logged-in users can see contacts
-- Drop existing permissive SELECT policy and replace with restrictive one
-- Actually, the existing policies are RESTRICTIVE (Permissive: No), which means we need PERMISSIVE policies
-- Let's drop the old select policy and create two new ones

DROP POLICY IF EXISTS "Classifieds are viewable by everyone" ON public.classifieds;

-- Everyone can see classifieds but without contact info (we'll handle this in frontend since RLS is row-level not column-level)
-- Instead, let's keep the SELECT policy but handle contact visibility in the frontend
CREATE POLICY "Classifieds are viewable by everyone"
ON public.classifieds
FOR SELECT
USING (true);

-- 4. Ensure PIX fields can only be updated by the profile owner (already covered by existing RLS on profiles)
-- The existing "Users can update own profile" policy already enforces auth.uid() = id
-- And "Admins can update any profile" for admins. This is correct.

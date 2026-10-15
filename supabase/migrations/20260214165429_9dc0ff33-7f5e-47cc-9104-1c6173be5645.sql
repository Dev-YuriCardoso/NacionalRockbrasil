
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, user_type, accepted_terms, terms_accepted_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    COALESCE((NEW.raw_user_meta_data->>'user_type')::public.user_type, 'fã'),
    COALESCE((NEW.raw_user_meta_data->>'accepted_terms')::boolean, false),
    CASE WHEN (NEW.raw_user_meta_data->>'accepted_terms')::boolean = true THEN now() ELSE NULL END
  );
  RETURN NEW;
END;
$$;

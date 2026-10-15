
ALTER TABLE public.profiles
ADD COLUMN accepted_terms boolean NOT NULL DEFAULT false,
ADD COLUMN terms_accepted_at timestamp with time zone;

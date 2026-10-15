
-- Add city column to events table
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS city text NOT NULL DEFAULT '';

-- Add new content types for Bandcamp and SoundCloud
ALTER TYPE public.content_type ADD VALUE IF NOT EXISTS 'bandcamp_link';
ALTER TYPE public.content_type ADD VALUE IF NOT EXISTS 'soundcloud_link';

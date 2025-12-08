-- Portfolio App Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE,
  email TEXT,
  name TEXT,
  bio TEXT,
  about TEXT,
  theme TEXT,
  avatar_url TEXT,
  linkedin_url TEXT,
  instagram_url TEXT,
  twitter_url TEXT,
  pinterest_url TEXT,
  github_url TEXT,
  skills TEXT,
  projects TEXT,
  experience TEXT,
  education TEXT,
  location TEXT,
  website_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create photos table
CREATE TABLE IF NOT EXISTS photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create blog_posts table
CREATE TABLE IF NOT EXISTS blog_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  excerpt TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create follows table for user following
CREATE TABLE IF NOT EXISTS follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Create meetings table for scheduling meetings
CREATE TABLE IF NOT EXISTS meetings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  google_meet_link TEXT NOT NULL,
  scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'cancelled')),
  message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;

-- Profiles policies
-- Drop existing policies if they exist (safe to run multiple times)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Anyone can read profiles
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Photos policies
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Photos are viewable by everyone" ON photos;
DROP POLICY IF EXISTS "Users can insert own photos" ON photos;
DROP POLICY IF EXISTS "Users can update own photos" ON photos;
DROP POLICY IF EXISTS "Users can delete own photos" ON photos;

-- Anyone can read photos
CREATE POLICY "Photos are viewable by everyone" ON photos
  FOR SELECT USING (true);

-- Users can insert their own photos
CREATE POLICY "Users can insert own photos" ON photos
  FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Users can update their own photos
CREATE POLICY "Users can update own photos" ON photos
  FOR UPDATE USING (auth.uid() = profile_id);

-- Users can delete their own photos
CREATE POLICY "Users can delete own photos" ON photos
  FOR DELETE USING (auth.uid() = profile_id);

-- Blog posts policies
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Blog posts are viewable by everyone" ON blog_posts;
DROP POLICY IF EXISTS "Users can insert own blog posts" ON blog_posts;
DROP POLICY IF EXISTS "Users can update own blog posts" ON blog_posts;
DROP POLICY IF EXISTS "Users can delete own blog posts" ON blog_posts;

-- Anyone can read blog posts
CREATE POLICY "Blog posts are viewable by everyone" ON blog_posts
  FOR SELECT USING (true);

-- Users can insert their own blog posts
CREATE POLICY "Users can insert own blog posts" ON blog_posts
  FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Users can update their own blog posts
CREATE POLICY "Users can update own blog posts" ON blog_posts
  FOR UPDATE USING (auth.uid() = profile_id);

-- Users can delete their own blog posts
CREATE POLICY "Users can delete own blog posts" ON blog_posts
  FOR DELETE USING (auth.uid() = profile_id);

-- Follows policies
DROP POLICY IF EXISTS "Follows are viewable by everyone" ON follows;
DROP POLICY IF EXISTS "Users can follow others" ON follows;
DROP POLICY IF EXISTS "Users can unfollow" ON follows;

-- Anyone can read follows
CREATE POLICY "Follows are viewable by everyone" ON follows
  FOR SELECT USING (true);

-- Users can follow others
CREATE POLICY "Users can follow others" ON follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow (delete their own follows)
CREATE POLICY "Users can unfollow" ON follows
  FOR DELETE USING (auth.uid() = follower_id);

-- Meetings policies
DROP POLICY IF EXISTS "Meetings are viewable by participants" ON meetings;
DROP POLICY IF EXISTS "Users can request meetings" ON meetings;
DROP POLICY IF EXISTS "Users can update own meetings" ON meetings;
DROP POLICY IF EXISTS "Users can delete own meeting requests" ON meetings;

-- Users can view meetings they're involved in
CREATE POLICY "Meetings are viewable by participants" ON meetings
  FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = recipient_id);

-- Users can request meetings
CREATE POLICY "Users can request meetings" ON meetings
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

-- Users can update meetings they're involved in (accept/decline)
CREATE POLICY "Users can update own meetings" ON meetings
  FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = recipient_id);

-- Users can delete their own meeting requests
CREATE POLICY "Users can delete own meeting requests" ON meetings
  FOR DELETE USING (auth.uid() = requester_id);

-- Function to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', '')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, profiles.name),
    avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a new user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create storage buckets for avatars and photos
-- Note: You need to create these buckets in Supabase Dashboard > Storage
-- Bucket name: 'avatars' - Public bucket
-- Bucket name: 'photos' - Public bucket

-- Storage policies for avatars bucket
-- (Run these after creating the 'avatars' bucket in Storage)
-- DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
-- 
-- CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
--   FOR SELECT USING (bucket_id = 'avatars');
-- 
-- CREATE POLICY "Users can upload own avatar" ON storage.objects
--   FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
-- 
-- CREATE POLICY "Users can update own avatar" ON storage.objects
--   FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for photos bucket
-- (Run these after creating the 'photos' bucket in Storage)
-- DROP POLICY IF EXISTS "Photos are publicly accessible" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can upload own photos" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can delete own photos" ON storage.objects;
-- 
-- CREATE POLICY "Photos are publicly accessible" ON storage.objects
--   FOR SELECT USING (bucket_id = 'photos');
-- 
-- CREATE POLICY "Users can upload own photos" ON storage.objects
--   FOR INSERT WITH CHECK (bucket_id = 'photos' AND auth.uid()::text = (storage.foldername(name))[1]);
-- 
-- CREATE POLICY "Users can delete own photos" ON storage.objects
--   FOR DELETE USING (bucket_id = 'photos' AND auth.uid()::text = (storage.foldername(name))[1]);


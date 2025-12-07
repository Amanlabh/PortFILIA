# Setup Guide - Troubleshooting

## Common Issues

### "Database error saving new user"

This error typically means one of the following:

1. **Database tables not created** - The most common issue
   - Solution: Run the SQL script in `database-schema.sql` in your Supabase SQL Editor
   - Go to: Supabase Dashboard → SQL Editor → New Query
   - Copy and paste the entire contents of `database-schema.sql`
   - Click "Run"

2. **Row Level Security (RLS) policies not set up**
   - The SQL script includes RLS policies, but if you're getting this error, make sure all policies were created successfully
   - Check in Supabase Dashboard → Authentication → Policies

3. **Username already exists**
   - The improved error handling will now show a specific message if the username is taken
   - Try a different username

4. **Email confirmation required**
   - Supabase may require email confirmation
   - Check your email inbox for a confirmation link
   - Or disable email confirmation in Supabase Dashboard → Authentication → Settings

## Step-by-Step Setup

### 1. Create Database Tables

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Click **New Query**
4. Copy the entire contents of `database-schema.sql`
5. Paste into the SQL Editor
6. Click **Run** (or press Cmd/Ctrl + Enter)
7. Verify success - you should see "Success. No rows returned"

### 2. Verify Tables Were Created

1. Go to **Table Editor** in Supabase Dashboard
2. You should see three tables:
   - `profiles`
   - `photos`
   - `blog_posts`

### 3. Create Storage Buckets

1. Go to **Storage** in Supabase Dashboard
2. Click **New bucket**
3. Create bucket named `avatars`:
   - Name: `avatars`
   - Public bucket: **Yes** (toggle ON)
   - Click **Create bucket**
4. Create bucket named `photos`:
   - Name: `photos`
   - Public bucket: **Yes** (toggle ON)
   - Click **Create bucket**

### 4. Set Up Storage Policies

1. Go to **SQL Editor** again
2. Run this SQL for avatars bucket:

```sql
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own avatar" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

3. Run this SQL for photos bucket:

```sql
CREATE POLICY "Photos are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'photos');

CREATE POLICY "Users can upload own photos" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own photos" ON storage.objects
  FOR DELETE USING (bucket_id = 'photos' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 5. Disable Email Confirmation (Optional)

If you want users to sign up without email confirmation:

1. Go to **Authentication** → **Settings**
2. Under **Email Auth**, toggle OFF **Enable email confirmations**
3. Click **Save**

### 6. Test the Application

1. Start the dev server: `npm run dev`
2. Go to `http://localhost:5173`
3. Click **Get Started** or go to `/login`
4. Click **Create Account**
5. Fill in email, password (min 6 chars), and username
6. Click **Sign Up**

If you still get errors, check the browser console (F12) for more details.

## Quick Verification

Run this in Supabase SQL Editor to verify everything is set up:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'photos', 'blog_posts');

-- Check if policies exist
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('profiles', 'photos', 'blog_posts');
```

You should see:
- 3 tables in the first query
- Multiple policies in the second query

# Portfolio Web App

A modern portfolio creation web application built with Vue.js and Supabase. Create your personal portfolio, showcase your work, upload photos, write blog posts, and connect your social media profiles.

## Features

- 🔐 **Authentication** - Google OAuth sign-in with Supabase
- 👤 **Profile Management** - Create and customize your portfolio
- 🔗 **Social Links** - Add LinkedIn, Instagram, Twitter, Pinterest, and GitHub profiles
- 📸 **Photo Gallery** - Upload and display photos with captions
- ✍️ **Blog** - Write and share blog posts
- 🎨 **Modern UI** - Clean, minimalist design with monospace font
- 📱 **Responsive** - Works on all devices

## Tech Stack

- **Vue.js 3** - Progressive JavaScript framework
- **Vite** - Next generation frontend tooling
- **Vue Router** - Official router for Vue.js
- **Supabase** - Backend as a Service (Authentication, Database, Storage)

## Setup Instructions

### ⚠️ IMPORTANT: Database Setup Required First!

**Before running the app, you MUST set up the database tables. If you see "Database error saving new user", it means the database isn't configured yet.**

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Up Supabase Database (REQUIRED)

**This step is critical!** Without it, signup/login will fail.

1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Open the file `database-schema.sql` in this project
5. Copy the **entire contents** of `database-schema.sql`
6. Paste into the SQL Editor
7. Click **Run** (or press Cmd/Ctrl + Enter)
8. You should see "Success. No rows returned"

**Verify tables were created:**
- Go to **Table Editor** in Supabase Dashboard
- You should see three tables: `profiles`, `photos`, `blog_posts`

**If you get errors, see `SETUP.md` for detailed troubleshooting.**

### 3. Set Up Supabase Storage

1. In Supabase Dashboard, go to **Storage**
2. Create two public buckets:
   - **Bucket name:** `avatars` (Public bucket)
   - **Bucket name:** `photos` (Public bucket)

3. After creating the buckets, run these policies in the SQL Editor:

```sql
-- Storage policies for avatars bucket
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own avatar" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for photos bucket
CREATE POLICY "Photos are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'photos');

CREATE POLICY "Users can upload own photos" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own photos" ON storage.objects
  FOR DELETE USING (bucket_id = 'photos' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### 4. Configure Google OAuth

**This is required for authentication to work!**

1. Follow the detailed guide in `GOOGLE_AUTH_SETUP.md`
2. Enable Google provider in Supabase Dashboard
3. Get OAuth credentials from Google Cloud Console
4. Configure them in Supabase

### 5. Run Development Server

```bash
npm run dev
```

The app will be available at `http://localhost:5173`

## Usage

1. **Sign In** - Click "Continue with Google" to sign in with your Google account
2. **Set Username** - On first login, you'll be asked to set a username for your portfolio URL
2. **Create Portfolio** - Fill in your profile information, add social links, and upload photos
3. **Write Blog Posts** - Share your thoughts and experiences
4. **View Portfolio** - Your portfolio will be available at `/portfolio/your-username`
5. **Share** - Share your portfolio URL with others

## Project Structure

```
src/
├── components/          # Reusable components
├── views/              # Page components
│   ├── Home.vue       # Landing page
│   ├── Login.vue      # Authentication
│   ├── Portfolio.vue  # Portfolio display
│   ├── EditPortfolio.vue  # Portfolio editor
│   └── BlogPost.vue   # Blog post view
├── router/            # Vue Router configuration
├── supabase.js        # Supabase client setup
├── App.vue            # Root component
├── main.js            # Application entry point
└── style.css          # Global styles
```

## Database Schema

- **profiles** - User profile information and social links
- **photos** - User uploaded photos
- **blog_posts** - Blog posts

See `database-schema.sql` for complete schema definition.

## Build for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

## License

MIT
# PortFILIA

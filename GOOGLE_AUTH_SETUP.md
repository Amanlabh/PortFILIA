# Google OAuth Setup Guide

This app now uses **Google OAuth only** for authentication. Follow these steps to configure Google authentication in Supabase.

## Step 1: Enable Google Provider in Supabase

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Authentication** → **Providers** (left sidebar)
4. Find **Google** in the list
5. Toggle **Enable Google provider** to ON

## Step 2: Get Google OAuth Credentials

1. Go to Google Cloud Console: https://console.cloud.google.com/
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. If prompted, configure the OAuth consent screen first:
   - Choose **External** user type
   - Fill in the required information (App name, User support email, Developer contact)
   - Add your email to test users if needed
   - Save and continue through the scopes (default is fine)
   - Save and continue through test users
   - Back to dashboard

6. Create OAuth Client ID:
   - Application type: **Web application**
   - Name: Your app name (e.g., "Portfolio App")
   - **Authorized JavaScript origins**: 
     - `http://localhost:5173` (for development)
     - `https://yourdomain.com` (for production)
   - **Authorized redirect URIs**:
     - `http://localhost:5173/auth/callback` (for development)
     - `https://yourdomain.com/auth/callback` (for production)
   - Click **Create**
   - Copy the **Client ID** and **Client Secret**

## Step 3: Configure Google in Supabase

1. Go back to Supabase Dashboard → **Authentication** → **Providers** → **Google**
2. Paste your **Client ID** and **Client Secret** from Google Cloud Console
3. Click **Save**

## Step 4: Update Redirect URL in Supabase

1. In Supabase Dashboard, go to **Authentication** → **URL Configuration**
2. Add your redirect URLs:
   - **Site URL**: `http://localhost:5173` (for development) or your production URL
   - **Redirect URLs**: Add `http://localhost:5173/auth/callback` (and production URL if applicable)

## Step 5: Test the Authentication

1. Start your development server: `npm run dev`
2. Go to `http://localhost:5173/login`
3. Click **Continue with Google**
4. You should be redirected to Google's sign-in page
5. After signing in, you'll be redirected back to the app
6. If it's your first time, you'll be asked to set a username for your portfolio

## Troubleshooting

### "Redirect URI mismatch" error

- Make sure the redirect URI in Google Cloud Console exactly matches: `http://localhost:5173/auth/callback`
- Check that the Site URL in Supabase matches your app URL

### "Invalid client" error

- Verify your Client ID and Client Secret are correct in Supabase
- Make sure Google OAuth is enabled in Supabase

### User redirected but not logged in

- Check the browser console for errors
- Verify the database tables are set up (run `database-schema.sql`)
- Check that RLS policies are correctly configured

### Username not being saved

- Make sure the `profiles` table exists and has a `username` column
- Check that RLS policies allow users to insert/update their own profiles

## Production Setup

When deploying to production:

1. Update Google Cloud Console OAuth credentials:
   - Add your production domain to **Authorized JavaScript origins**
   - Add `https://yourdomain.com/auth/callback` to **Authorized redirect URIs**

2. Update Supabase:
   - Set **Site URL** to your production URL
   - Add production redirect URL to **Redirect URLs**

3. Update the redirect URL in `src/views/Login.vue` if needed (it should automatically use `window.location.origin`)

## Notes

- Users will be asked to set a username on their first login
- The username is used for the portfolio URL: `/portfolio/username`
- Google profile information (name, avatar) is automatically imported
- Users can update their username later in the Edit Portfolio page


<template>
  <div class="login-container">
    <div class="login-box">
      <h1>// LOGIN</h1>
      <div class="auth-form">
        <div class="google-signin-section">
          <p class="signin-text">Showcase Your Work in Style</p>
          <p class="signin-subtext">Create your professional portfolio in minutes</p>
          <button @click="handleGoogleSignIn" :disabled="loading" class="google-button">
            <svg class="google-icon" viewBox="0 0 24 24" width="20" height="20">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            {{ loading ? 'Loading...' : 'Continue with Google' }}
          </button>
          <button class="secondary username-button" @click="showUsernameInput = true" v-if="!showUsernameInput">
            ~/username
          </button>
        </div>
        
        <div v-if="showUsernameInput" class="username-section">
          <input
            v-model="username"
            type="text"
            placeholder="Enter username for your portfolio URL"
            class="input-field"
            @keyup.enter="setUsername"
          />
          <button @click="setUsername" :disabled="loading || !username.trim()" class="button primary">
            Set Username
          </button>
          <button class="button secondary" @click="showUsernameInput = false">
            Cancel
          </button>
        </div>
        
        <p v-if="error" class="error">{{ error }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()
const username = ref('')
const loading = ref(false)
const error = ref('')
const showUsernameInput = ref(false)

const handleGoogleSignIn = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const { data, error: authError } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`
      }
    })
    
    if (authError) throw authError
  } catch (err) {
    error.value = err.message || 'Failed to sign in with Google'
    loading.value = false
  }
}

const setUsername = async () => {
  if (!username.value.trim()) {
    error.value = 'Username is required'
    return
  }
  
  // Validate username format
  const usernameRegex = /^[a-zA-Z0-9_-]+$/
  const cleanUsername = username.value.trim().toLowerCase()
  
  if (!usernameRegex.test(cleanUsername)) {
    error.value = 'Username can only contain letters, numbers, dashes, and underscores'
    return
  }
  
  if (cleanUsername.length < 3) {
    error.value = 'Username must be at least 3 characters'
    return
  }
  
  loading.value = true
  error.value = ''
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    if (!user) {
      error.value = 'Please sign in first'
      loading.value = false
      return
    }
    
    // Check if username is already taken
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('username')
      .eq('username', cleanUsername)
      .single()
    
    if (existingProfile) {
      error.value = 'Username already taken. Please choose another.'
      loading.value = false
      return
    }
    
    // Update or create profile with username
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert({
        id: user.id,
        username: cleanUsername,
        email: user.email,
        name: user.user_metadata?.full_name || user.user_metadata?.name || '',
        avatar_url: user.user_metadata?.avatar_url || user.user_metadata?.picture || ''
      })
    
    if (profileError) throw profileError
    
    showUsernameInput.value = false
    router.push('/edit')
  } catch (err) {
    error.value = err.message || 'Failed to set username'
    console.error('Username error:', err)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  // Check if user is already logged in
  const { data: { session } } = await supabase.auth.getSession()
  
  if (session) {
    // Check if user has a profile with username
    const { data: profile } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', session.user.id)
      .single()
    
    if (profile?.username) {
      router.push('/edit')
    } else {
      showUsernameInput.value = true
    }
  }
  
  // Handle OAuth callback
  const { data: { session: newSession } } = await supabase.auth.getSession()
  if (newSession) {
    // Check if profile exists
    const { data: profile } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', newSession.user.id)
      .single()
    
    if (!profile || !profile.username) {
      showUsernameInput.value = true
    } else {
      router.push('/edit')
    }
  }
})
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  background: #f5f5f0;
}

.login-box {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  padding: 2rem;
  border-radius: 4px;
  max-width: 400px;
  width: 100%;
}

.login-box h1 {
  margin-bottom: 1.5rem;
  font-size: 1.5rem;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.google-signin-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem 0;
}

.signin-text {
  font-size: 1.2rem;
  font-weight: 500;
  margin: 0;
}

.signin-subtext {
  font-size: 0.9rem;
  color: #666;
  margin: 0;
}

.google-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 0.8em 1.5em;
  background: #1a1a1a;
  color: #f5f5f0;
  border: 1px solid #1a1a1a;
  font-size: 1rem;
  font-weight: 500;
}

.google-button:hover:not(:disabled) {
  background: #333;
}

.google-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.google-icon {
  flex-shrink: 0;
}

.username-button {
  width: 100%;
  padding: 0.6em 1.2em;
  font-size: 0.9rem;
}

.username-section {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  padding-top: 1rem;
  border-top: 1px solid #e0e0e0;
}

.input-field {
  width: 100%;
}

.error {
  color: #d32f2f;
  font-size: 0.85em;
  margin-top: 0.5rem;
  text-align: center;
}
</style>

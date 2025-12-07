<template>
  <div class="callback-container">
    <div class="callback-box">
      <h1>// AUTHENTICATING</h1>
      <p v-if="loading">Completing sign in...</p>
      <div v-else-if="error" class="error-section">
        <p class="error">{{ error }}</p>
        <div v-if="error.includes('Database') || error.includes('table')" class="help-text">
          <p><strong>Setup Required:</strong></p>
          <ol>
            <li>Go to Supabase Dashboard → SQL Editor</li>
            <li>Run the SQL from <code>database-schema.sql</code></li>
            <li>Verify tables exist in Table Editor</li>
            <li>Try signing in again</li>
          </ol>
        </div>
      </div>
      <div v-else-if="needsUsername" class="username-form">
        <h2>Set Your Username</h2>
        <p class="subtext">Choose a username for your portfolio URL</p>
        <input
          v-model="username"
          type="text"
          placeholder="username"
          class="input-field"
          @keyup.enter="setUsername"
        />
        <button @click="setUsername" :disabled="saving || !username.trim()" class="button primary">
          {{ saving ? 'Saving...' : 'Continue' }}
        </button>
        <p v-if="usernameError" class="error">{{ usernameError }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()
const loading = ref(true)
const error = ref('')
const needsUsername = ref(false)
const username = ref('')
const saving = ref(false)
const usernameError = ref('')
let authSubscription = null

onMounted(async () => {
  // Check for error in URL hash
  const hashParams = new URLSearchParams(window.location.hash.substring(1))
  const errorParam = hashParams.get('error')
  const errorDescription = hashParams.get('error_description')
  
  if (errorParam) {
    error.value = errorDescription || `Authentication error: ${errorParam}`
    loading.value = false
    return
  }
  
  // Set up auth state listener to handle OAuth callback
  const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
    console.log('Auth state change:', event, session?.user?.email)
    
    if (event === 'SIGNED_IN' && session) {
      await processSession(session)
    } else if (event === 'SIGNED_OUT') {
      error.value = 'Sign in was cancelled or failed. Please try again.'
      loading.value = false
    }
  })
  
  authSubscription = subscription
  
  // Also try to get session immediately (in case it's already processed)
  try {
    // Wait a moment for Supabase to process the hash
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const { data: { session }, error: sessionError } = await supabase.auth.getSession()
    
    if (sessionError) {
      error.value = sessionError.message
      loading.value = false
      return
    }
    
    if (session) {
      await processSession(session)
    } else {
      // Wait a bit more for the auth state change to fire
      setTimeout(() => {
        if (loading.value) {
          error.value = 'No session found. Please try signing in again.'
          loading.value = false
        }
      }, 2000)
    }
  } catch (err) {
    error.value = err.message || 'An error occurred'
    loading.value = false
    console.error('Auth callback error:', err)
  }
})

onUnmounted(() => {
  if (authSubscription) {
    authSubscription.unsubscribe()
  }
})

const processSession = async (session) => {
  try {
    // Clear the URL hash after processing
    if (window.location.hash) {
      window.history.replaceState(null, '', window.location.pathname)
    }
    
    // Check if profile exists with username
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', session.user.id)
      .single()
    
    if (profileError) {
      if (profileError.code === 'PGRST116') {
        // Profile doesn't exist - this is fine, we'll create it
        console.log('Profile does not exist, will create new one')
      } else if (profileError.code === '42P01') {
        // Table doesn't exist
        error.value = 'Database table not found. Please run the database-schema.sql script in Supabase SQL Editor.'
        loading.value = false
        return
      } else {
        // Other error
        console.error('Profile query error:', profileError)
        // Continue anyway - we'll try to create/update
      }
    }
    
    if (!profile || !profile.username) {
      // Try to create or update profile
      let profileData = null
      let createError = null
      
      // First try to insert (if profile doesn't exist)
      if (!profile) {
        const { data, error: insertError } = await supabase
          .from('profiles')
          .insert({
            id: session.user.id,
            email: session.user.email,
            name: session.user.user_metadata?.full_name || session.user.user_metadata?.name || '',
            avatar_url: session.user.user_metadata?.avatar_url || session.user.user_metadata?.picture || ''
          })
          .select()
          .single()
        
        if (insertError) {
          // If insert fails, try update (profile might exist but query failed)
          if (insertError.code === '23505') { // Unique violation - profile exists
            const { data: updateData, error: updateError } = await supabase
              .from('profiles')
              .update({
                email: session.user.email,
                name: session.user.user_metadata?.full_name || session.user.user_metadata?.name || '',
                avatar_url: session.user.user_metadata?.avatar_url || session.user.user_metadata?.picture || ''
              })
              .eq('id', session.user.id)
              .select()
              .single()
            
            if (updateError) {
              createError = updateError
            } else {
              profileData = updateData
            }
          } else {
            createError = insertError
          }
        } else {
          profileData = data
        }
      } else {
        // Profile exists but no username - just update if needed
        const { data: updateData, error: updateError } = await supabase
          .from('profiles')
          .update({
            email: session.user.email,
            name: session.user.user_metadata?.full_name || session.user.user_metadata?.name || profile.name || '',
            avatar_url: session.user.user_metadata?.avatar_url || session.user.user_metadata?.picture || profile.avatar_url || ''
          })
          .eq('id', session.user.id)
          .select()
          .single()
        
        if (updateError) {
          createError = updateError
        } else {
          profileData = updateData
        }
      }
      
      if (createError) {
        console.error('Error creating/updating profile:', createError)
        const errorMsg = createError.message || createError.details || createError.hint || 'Failed to save profile'
        error.value = `Database error: ${errorMsg}. Please make sure the database tables are set up correctly (run database-schema.sql in Supabase SQL Editor).`
        loading.value = false
        return
      }
      
      // If profile was created/updated successfully but has no username, show username input
      if (!profileData?.username) {
        needsUsername.value = true
        loading.value = false
        return
      }
      
      // Profile has username, redirect
      router.push('/edit')
      return
    }
    
    // User has username, redirect to edit
    router.push('/edit')
  } catch (err) {
    error.value = err.message || 'An error occurred while processing your session'
    loading.value = false
    console.error('Process session error:', err)
  }
}

const setUsername = async () => {
  if (!username.value.trim()) {
    usernameError.value = 'Username is required'
    return
  }
  
  // Validate username format
  const usernameRegex = /^[a-zA-Z0-9_-]+$/
  const cleanUsername = username.value.trim().toLowerCase()
  
  if (!usernameRegex.test(cleanUsername)) {
    usernameError.value = 'Username can only contain letters, numbers, dashes, and underscores'
    return
  }
  
  if (cleanUsername.length < 3) {
    usernameError.value = 'Username must be at least 3 characters'
    return
  }
  
  saving.value = true
  usernameError.value = ''
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    if (!user) {
      usernameError.value = 'Please sign in first'
      saving.value = false
      return
    }
    
    // Check if username is already taken by another user
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id, username')
      .eq('username', cleanUsername)
      .single()
    
    if (existingProfile && existingProfile.id !== user.id) {
      usernameError.value = 'Username already taken. Please choose another.'
      saving.value = false
      return
    }
    
    // Update profile with username
    const { error: updateError } = await supabase
      .from('profiles')
      .update({ username: cleanUsername })
      .eq('id', user.id)
    
    if (updateError) throw updateError
    
    router.push('/edit')
  } catch (err) {
    usernameError.value = err.message || 'Failed to set username'
    console.error('Username error:', err)
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.callback-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
  background: #f5f5f0;
}

.callback-box {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  padding: 2rem;
  border-radius: 4px;
  max-width: 400px;
  width: 100%;
  text-align: center;
}

.callback-box h1 {
  margin-bottom: 1.5rem;
  font-size: 1.5rem;
}

.callback-box h2 {
  margin-bottom: 0.5rem;
  font-size: 1.2rem;
}

.subtext {
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 1.5rem;
}

.username-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-top: 1.5rem;
}

.input-field {
  width: 100%;
}

.error {
  color: #d32f2f;
  font-size: 0.85em;
  margin-top: 0.5rem;
}

.error-section {
  text-align: left;
}

.help-text {
  margin-top: 1.5rem;
  padding: 1rem;
  background: #f9f9f9;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 0.85em;
}

.help-text p {
  margin-bottom: 0.5rem;
}

.help-text ol {
  margin-left: 1.5rem;
  margin-top: 0.5rem;
}

.help-text li {
  margin-bottom: 0.5rem;
  line-height: 1.5;
}

.help-text code {
  background: #e0e0e0;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-size: 0.9em;
}
</style>


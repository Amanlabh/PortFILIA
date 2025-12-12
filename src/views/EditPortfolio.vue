<template>
  <div class="edit-container">
    <nav class="navbar">
      <div class="nav-content">
        <router-link to="/" class="logo">// PortFILIA</router-link>
        <div class="nav-links">
          <router-link :to="`/portfolio/${profile?.username}`" v-if="profile?.username">
            View Portfolio
          </router-link>
          <router-link to="/dashboard">
            Dashboard
          </router-link>
          <button @click="handleLogout" class="logout-btn">Logout</button>
        </div>
      </div>
    </nav>
    
    <div class="container">
      <div v-if="loading" class="loading">
        <p>Loading...</p>
      </div>
      
      <div v-else class="edit-content">
        <h1>// EDIT PORTFOLIO</h1>
        
        <div class="form-section">
          <h2>Basic Information</h2>
          <div class="form-group">
            <label>Name</label>
            <input v-model="formData.name" type="text" placeholder="Your name" />
          </div>
          <div class="form-group">
            <label>Username (for URL)</label>
            <input 
              v-model="formData.username" 
              type="text" 
              placeholder="username" 
              :class="{ 'error-input': usernameError }"
              @blur="() => {
                if (!formData.username) return
                const error = validateUsername(formData.username)
                usernameError = error || ''
              }"
            />
            <small>Your portfolio will be at: /portfolio/{{ formData.username || 'username' }}</small>
            <div v-if="usernameError" class="error-message">
              {{ usernameError }}
            </div>
          </div>
          <div class="form-group">
            <label>Location</label>
            <input v-model="formData.location" type="text" placeholder="City, Country" />
          </div>
          <div class="form-group">
            <label>Bio</label>
            <textarea v-model="formData.bio" rows="3" placeholder="Short bio"></textarea>
          </div>
          <div class="form-group">
            <label>About</label>
            <textarea v-model="formData.about" rows="10" placeholder="Tell us about yourself"></textarea>
          </div>
        </div>
        
        <div class="form-section">
          <h2>Additional Information</h2>
          <div class="form-group">
            <label>Skills (comma-separated)</label>
            <input v-model="formData.skills" type="text" placeholder="JavaScript, React, Vue, etc." />
          </div>
          <div class="form-group">
            <label>Experience</label>
            <textarea v-model="formData.experience" rows="8" placeholder="Your work experience..."></textarea>
          </div>
          <div class="form-group">
            <label>Education</label>
            <textarea v-model="formData.education" rows="6" placeholder="Your education background..."></textarea>
          </div>
          <div class="form-group">
            <label>Projects</label>
            <textarea v-model="formData.projects" rows="8" placeholder="Your projects and achievements..."></textarea>
          </div>
        </div>
        
        <div class="form-section">
          <h2>Social Links</h2>
          <div class="form-group">
            <label>Website URL</label>
            <input v-model="formData.website_url" type="url" placeholder="https://yourwebsite.com" />
          </div>
          <div class="form-group">
            <label>LinkedIn URL</label>
            <input v-model="formData.linkedin_url" type="url" placeholder="https://linkedin.com/in/..." />
          </div>
          <div class="form-group">
            <label>Instagram URL</label>
            <input v-model="formData.instagram_url" type="url" placeholder="https://instagram.com/..." />
          </div>
          <div class="form-group">
            <label>Twitter URL</label>
            <input v-model="formData.twitter_url" type="url" placeholder="https://twitter.com/..." />
          </div>
          <div class="form-group">
            <label>Pinterest URL</label>
            <input v-model="formData.pinterest_url" type="url" placeholder="https://pinterest.com/..." />
          </div>
          <div class="form-group">
            <label>GitHub URL</label>
            <input v-model="formData.github_url" type="url" placeholder="https://github.com/..." />
          </div>
        </div>
        
        <div class="form-section">
          <h2>Profile Photo</h2>
          <div class="form-group">
            <input type="file" @change="handleAvatarUpload" accept="image/*" />
            <div v-if="formData.avatar_url" class="avatar-preview">
              <img :src="formData.avatar_url" alt="Avatar preview" />
            </div>
          </div>
        </div>
        
        <div class="form-section">
          <h2>Photos</h2>
          <div class="form-group">
            <input type="file" @change="handlePhotoUpload" accept="image/*" multiple />
          </div>
          <div class="photos-list">
            <div v-for="photo in photos" :key="photo.id" class="photo-item">
              <img :src="photo.url" alt="Photo" />
              <input v-model="photo.caption" @blur="updatePhoto(photo)" placeholder="Caption" />
              <button @click="deletePhoto(photo.id)" class="delete-btn">Delete</button>
            </div>
          </div>
        </div>
        
        <div class="form-section">
          <h2>Blog Posts</h2>
          <button @click="showNewPost = true" class="button">New Blog Post</button>
          <div v-if="showNewPost" class="blog-editor">
            <input v-model="newPost.title" placeholder="Post title" />
            <textarea v-model="newPost.content" rows="15" placeholder="Write your blog post..."></textarea>
            <div class="editor-actions">
              <button @click="saveBlogPost" class="button">Save Post</button>
              <button @click="cancelNewPost" class="button secondary">Cancel</button>
            </div>
          </div>
          <div class="blog-list">
            <div v-for="post in blogPosts" :key="post.id" class="blog-item">
              <h3>{{ post.title }}</h3>
              <p class="blog-meta">{{ formatDate(post.created_at) }}</p>
              <div class="blog-actions">
                <button @click="editBlogPost(post)" class="button secondary">Edit</button>
                <button @click="deleteBlogPost(post.id)" class="button secondary">Delete</button>
              </div>
            </div>
          </div>
        </div>
        
        <div class="form-actions">
          <button @click="saveProfile" class="button primary" :disabled="saving">
            {{ saving ? 'Saving...' : 'Save Portfolio' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()
const profile = ref(null)
const photos = ref([])
const blogPosts = ref([])
const loading = ref(true)
const saving = ref(false)
const showNewPost = ref(false)
const usernameError = ref('')

const formData = ref({
  name: '',
  username: '',
  bio: '',
  about: '',
  theme: '',
  location: '',
  skills: '',
  experience: '',
  education: '',
  projects: '',
  website_url: '',
  linkedin_url: '',
  instagram_url: '',
  twitter_url: '',
  pinterest_url: '',
  github_url: '',
  avatar_url: ''
})

const newPost = ref({
  title: '',
  content: ''
})


const loadProfile = async () => {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      router.push('/login')
      return
    }
    
    const { data: profileData, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()
    
    if (error && error.code !== 'PGRST116') throw error
    
    if (profileData) {
      profile.value = profileData
      Object.assign(formData.value, profileData)
      if (!formData.value.theme) {
        formData.value.theme = localStorage.getItem('selectedTemplate') || 'minimal'
      }
    } else {
      // Create profile if doesn't exist (for Google OAuth users)
      const { data: newProfile, error: createError } = await supabase
        .from('profiles')
        .insert({
          id: user.id,
          email: user.email,
          name: user.user_metadata?.full_name || user.user_metadata?.name || '',
          avatar_url: user.user_metadata?.avatar_url || user.user_metadata?.picture || ''
        })
        .select()
        .single()
      
      if (createError) throw createError
      profile.value = newProfile
      Object.assign(formData.value, newProfile)
      formData.value.theme = localStorage.getItem('selectedTemplate') || 'minimal'
    }
    
    // Load photos
    const { data: photosData } = await supabase
      .from('photos')
      .select('*')
      .eq('profile_id', user.id)
      .order('created_at', { ascending: false })
    
    photos.value = photosData || []
    
    // Load blog posts
    const { data: blogData } = await supabase
      .from('blog_posts')
      .select('*')
      .eq('profile_id', user.id)
      .order('created_at', { ascending: false })
    
    blogPosts.value = blogData || []
  } catch (err) {
    console.error('Error loading profile:', err)
  } finally {
    loading.value = false
  }
}

const validateUsername = (username) => {
  if (!username) return 'Username is required'
  if (username.length < 3) return 'Username must be at least 3 characters'
  if (!/^[a-z0-9_-]+$/.test(username)) {
    return 'Username can only contain lowercase letters, numbers, underscores, and hyphens'
  }
  return null
}

const checkUsernameAvailability = async (username) => {
  if (!username || username === profile.value?.username) return true
  
  const { data: existingProfile } = await supabase
    .from('profiles')
    .select('id')
    .eq('username', username)
    .neq('id', profile.value?.id)
    .single()
    
  return !existingProfile
}

const saveProfile = async () => {
  saving.value = true
  usernameError.value = ''
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    // Validate username
    const validationError = validateUsername(formData.value.username)
    if (validationError) {
      usernameError.value = validationError
      saving.value = false
      return
    }
    
    // Check if username is available
    const isUsernameAvailable = await checkUsernameAvailability(formData.value.username)
    if (!isUsernameAvailable) {
      usernameError.value = 'Username is already taken. Please choose another.'
      saving.value = false
      return
    }
    
    // If we get here, username is valid and available
    const { error } = await supabase
      .from('profiles')
      .update({
        ...formData.value,
        updated_at: new Date().toISOString()
      })
      .eq('id', user.id)
    
    if (error) throw error
    
    // Update local profile data
    profile.value = { ...profile.value, ...formData.value }
    alert('Portfolio saved successfully!')
  } catch (err) {
    console.error('Save error:', err)
    alert('Error saving portfolio: ' + (err.message || 'Unknown error'))
  } finally {
    saving.value = false
  }
}

const handleAvatarUpload = async (event) => {
  const file = event.target.files[0]
  if (!file) return
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    const fileExt = file.name.split('.').pop()
    const fileName = `${user.id}/avatar.${fileExt}`
    
    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(fileName, file, { upsert: true })
    
    if (uploadError) throw uploadError
    
    const { data } = supabase.storage
      .from('avatars')
      .getPublicUrl(fileName)
    
    formData.value.avatar_url = data.publicUrl
  } catch (err) {
    alert('Error uploading avatar: ' + err.message)
  }
}

const handlePhotoUpload = async (event) => {
  const files = Array.from(event.target.files)
  if (!files.length) return
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    for (const file of files) {
      const fileExt = file.name.split('.').pop()
      const fileName = `${user.id}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`
      
      const { error: uploadError } = await supabase.storage
        .from('photos')
        .upload(fileName, file)
      
      if (uploadError) throw uploadError
      
      const { data } = supabase.storage
        .from('photos')
        .getPublicUrl(fileName)
      
      const { data: photoData, error: insertError } = await supabase
        .from('photos')
        .insert({
          profile_id: user.id,
          url: data.publicUrl,
          caption: ''
        })
        .select()
        .single()
      
      if (!insertError) {
        photos.value.unshift(photoData)
      }
    }
  } catch (err) {
    alert('Error uploading photos: ' + err.message)
  }
}

const updatePhoto = async (photo) => {
  try {
    const { error } = await supabase
      .from('photos')
      .update({ caption: photo.caption })
      .eq('id', photo.id)
    
    if (error) throw error
  } catch (err) {
    console.error('Error updating photo:', err)
  }
}

const deletePhoto = async (id) => {
  if (!confirm('Delete this photo?')) return
  
  try {
    const { error } = await supabase
      .from('photos')
      .delete()
      .eq('id', id)
    
    if (error) throw error
    
    photos.value = photos.value.filter(p => p.id !== id)
  } catch (err) {
    alert('Error deleting photo: ' + err.message)
  }
}

const saveBlogPost = async () => {
  if (!newPost.value.title || !newPost.value.content) {
    alert('Please fill in title and content')
    return
  }
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    
    const { data, error } = await supabase
      .from('blog_posts')
      .insert({
        profile_id: user.id,
        title: newPost.value.title,
        content: newPost.value.content,
        excerpt: newPost.value.content.length > 150 ? newPost.value.content.substring(0, 150) : newPost.value.content
      })
      .select()
      .single()
    
    if (error) throw error
    
    blogPosts.value.unshift(data)
    cancelNewPost()
  } catch (err) {
    alert('Error saving blog post: ' + err.message)
  }
}

const cancelNewPost = () => {
  showNewPost.value = false
  newPost.value = { title: '', content: '' }
}

const editBlogPost = (post) => {
  router.push(`/blog/${post.id}?edit=true`)
}

const deleteBlogPost = async (id) => {
  if (!confirm('Delete this blog post?')) return
  
  try {
    const { error } = await supabase
      .from('blog_posts')
      .delete()
      .eq('id', id)
    
    if (error) throw error
    
    blogPosts.value = blogPosts.value.filter(p => p.id !== id)
  } catch (err) {
    alert('Error deleting blog post: ' + err.message)
  }
}

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const handleLogout = async () => {
  await supabase.auth.signOut()
  router.push('/')
}

onMounted(async () => {
  await loadProfile()
})
</script>

<style scoped>
.edit-container {
  min-height: 100vh;
}

.navbar {
  border-bottom: 1px solid #1a1a1a;
  padding: 1rem 0;
  background: #ffffff;
}

.nav-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo {
  font-weight: 600;
  font-size: 1.2rem;
  text-decoration: none;
}

.nav-links {
  display: flex;
  gap: 1.5rem;
  align-items: center;
}

.nav-links a {
  text-decoration: none;
}

.logout-btn {
  background: transparent;
  border: 1px solid #1a1a1a;
  color: #1a1a1a;
  padding: 0.5em 1em;
  font-size: 0.9em;
}

.edit-content {
  padding: 3rem 0;
}

.edit-content h1 {
  margin-bottom: 2rem;
  font-size: 2rem;
}

.form-section {
  margin-bottom: 3rem;
  padding: 2rem;
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
}

.form-section h2 {
  margin-bottom: 1.5rem;
  font-size: 1.3rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.form-group input,
.form-group textarea {
  width: 100%;
}

.form-group small {
  display: block;
  margin-top: 0.5rem;
  font-size: 0.85em;
  color: #666;
}

.avatar-preview {
  margin-top: 1rem;
}

.avatar-preview img {
  width: 150px;
  height: 150px;
  object-fit: cover;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
}

.photos-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-top: 1.5rem;
}

.photo-item {
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  padding: 1rem;
}

.photo-item img {
  width: 100%;
  height: 150px;
  object-fit: cover;
  margin-bottom: 0.5rem;
  border: 1px solid #1a1a1a;
}

.photo-item input {
  width: 100%;
  margin-bottom: 0.5rem;
  font-size: 0.85em;
}

.delete-btn {
  width: 100%;
  padding: 0.4em;
  font-size: 0.85em;
  background: #d32f2f;
  border-color: #d32f2f;
  color: #f5f5f0;
}

.blog-editor {
  margin: 1.5rem 0;
  padding: 1.5rem;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  background: #ffffff;
}

.blog-editor input,
.blog-editor textarea {
  width: 100%;
  margin-bottom: 1rem;
}

.editor-actions {
  display: flex;
  gap: 1rem;
}

.blog-list {
  margin-top: 1.5rem;
}

.blog-item {
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  padding: 1.5rem;
  margin-bottom: 1rem;
}

.blog-item h3 {
  margin-bottom: 0.5rem;
}

.blog-meta {
  font-size: 0.85em;
  color: #666;
  margin-bottom: 1rem;
}

.blog-actions {
  display: flex;
  gap: 1rem;
}

.form-actions {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid #1a1a1a;
}

.button {
  padding: 0.8em 1.5em;
}

.button.primary {
  background: #1a1a1a;
  color: #f5f5f0;
}

.meetings-tabs {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
  border-bottom: 1px solid #1a1a1a;
}

.tab-btn {
  padding: 0.6em 1.2em;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  cursor: pointer;
  font-size: 0.9rem;
  color: #666;
  transition: all 0.2s;
}

.tab-btn.active {
  color: #1a1a1a;
  border-bottom-color: #1a1a1a;
}

.tab-btn:hover {
  color: #1a1a1a;
}

.meetings-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.meeting-item {
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  padding: 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}

.meeting-info {
  flex: 1;
}

.meeting-info strong {
  display: block;
  margin-bottom: 0.5rem;
  font-size: 1.1rem;
}

.meeting-info p {
  margin: 0.25rem 0;
  color: #666;
  font-size: 0.9rem;
}

.meeting-message {
  margin-top: 0.5rem;
  padding: 0.5rem;
  background: #f5f5f0;
  border-radius: 4px;
  font-style: italic;
}

.meet-link {
  display: inline-block;
  margin-top: 0.5rem;
  padding: 0.4em 0.8em;
  background: #1a1a1a;
  color: #f5f5f0;
  text-decoration: none;
  border-radius: 4px;
  font-size: 0.9rem;
}

.meet-link:hover {
  opacity: 0.9;
}

.meeting-actions {
  display: flex;
  gap: 0.5rem;
}

.meeting-status {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.5rem;
}

.status-badge {
  padding: 0.3em 0.8em;
  border-radius: 4px;
  font-size: 0.85rem;
  text-transform: capitalize;
}

.status-badge.pending {
  background: #fff3cd;
  color: #856404;
  border: 1px solid #ffc107;
}

.status-badge.accepted {
  background: #d4edda;
  color: #155724;
  border: 1px solid #28a745;
}

.status-badge.declined {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #dc3545;
}

.status-badge.cancelled {
  background: #e2e3e5;
  color: #383d41;
  border: 1px solid #6c757d;
}

.button.small {
  padding: 0.4em 0.8em;
  font-size: 0.85rem;
}

.empty-state {
  text-align: center;
  padding: 2rem;
  color: #666;
}

.helper-text {
  color: #555;
  margin-bottom: 1rem;
}

.theme-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1rem;
}

.theme-card {
  border: 1px solid #1a1a1a;
  border-radius: 8px;
  padding: 1rem;
  background: #fafafa;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
}

.theme-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.08);
}

.theme-card.active {
  border-color: #1a1a1a;
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.12);
  background: #ffffff;
}

.theme-top {
  display: flex;
  justify-content: space-between;
  gap: 0.75rem;
  align-items: flex-start;
  margin-bottom: 0.75rem;
}

.theme-top h3 {
  margin: 0.2rem 0;
}

.muted {
  color: #666;
  font-size: 0.9rem;
}

.pill {
  display: inline-flex;
  align-items: center;
  padding: 0.2rem 0.6rem;
  border: 1px solid #1a1a1a;
  border-radius: 999px;
  font-size: 0.8rem;
}

.theme-preview {
  border: 1px solid #1a1a1a;
  border-radius: 6px;
  padding: 0.75rem;
  background: linear-gradient(135deg, #f8f8f8, #ffffff);
}

.theme-preview .preview-hero {
  height: 70px;
  border-radius: 4px;
  background: linear-gradient(120deg, #e0e7ff, #f5f3ff);
  margin-bottom: 0.5rem;
}

.theme-preview .preview-row {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.theme-preview .preview-block {
  height: 32px;
  border-radius: 4px;
  background: #eef2ff;
}

.theme-preview .preview-block.short {
  background: #e0e7ff;
}

.theme-preview .preview-gallery {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.35rem;
}

.theme-preview .preview-tile {
  height: 28px;
  border-radius: 4px;
  background: #d9e8ff;
}

.theme-tags {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
  margin-top: 0.75rem;
}

.meta-tag {
  background: #1a1a1a;
  color: #f5f5f0;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
}

.theme-studio .preview-hero {
  background: linear-gradient(120deg, #ffe8d6, #ffd6a5);
}

.theme-tech .preview-hero {
  background: linear-gradient(120deg, #d1fae5, #a7f3d0);
}

.theme-creator .preview-hero {
  background: linear-gradient(120deg, #fde68a, #fcd34d);
}

.theme-dark {
  background: #0f172a;
  border-color: #0f172a;
}

.theme-dark .preview-hero {
  background: linear-gradient(120deg, #1e293b, #0f172a);
}

.theme-dark .preview-block,
.theme-dark .preview-block.short,
.theme-dark .preview-tile {
  background: #1f2937;
}

@media (max-width: 768px) {
  .nav-content {
    padding: 0 1rem;
  }
  
  .form-section {
    padding: 1rem;
  }
  
  .meeting-item {
    flex-direction: column;
  }
  
  .meeting-status {
    align-items: flex-start;
    width: 100%;
  }
}
</style>


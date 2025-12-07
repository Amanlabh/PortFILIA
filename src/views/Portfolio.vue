<template>
  <div class="portfolio-container">
    <nav class="navbar">
      <div class="nav-content">
        <router-link to="/" class="logo">// PortFILIA</router-link>
        <div class="nav-links">
          <router-link to="/">Home</router-link>
          <router-link v-if="currentUser" to="/edit">Edit Portfolio</router-link>
        </div>
      </div>
    </nav>
    
    <div v-if="loading" class="container">
      <p>Loading...</p>
    </div>
    
    <div v-else-if="profile" class="container portfolio-content">
      <!-- Header Section -->
      <div class="portfolio-header">
        <div v-if="profile.avatar_url" class="avatar">
          <img :src="profile.avatar_url" alt="Avatar" />
        </div>
        <div class="header-info">
          <div class="header-top">
            <div>
              <h1>{{ profile.name || profile.username }}</h1>
              <p v-if="profile.location" class="location">{{ profile.location }}</p>
            </div>
            <div class="header-actions" v-if="currentUser && currentUser.id !== profile.id">
              <button 
                @click="toggleFollow" 
                :class="['follow-btn', { following: isFollowing }]"
                :disabled="followLoading"
              >
                {{ isFollowing ? 'Following' : 'Follow' }}
              </button>
              <button @click="showMeetingModal = true" class="meet-btn">
                Schedule Meet
              </button>
            </div>
          </div>
          <p v-if="profile.bio" class="bio">{{ profile.bio }}</p>
          <div class="stats">
            <div class="stat-item" @click="showFollowersModal = true">
              <strong>{{ followersCount }}</strong>
              <span>Followers</span>
            </div>
            <div class="stat-item">
              <strong>{{ followingCount }}</strong>
              <span>Following</span>
            </div>
          </div>
          <div class="social-links">
            <a v-if="profile.website_url" :href="profile.website_url" target="_blank" class="social-link">
              Website
            </a>
            <a v-if="profile.linkedin_url" :href="profile.linkedin_url" target="_blank" class="social-link">
              LinkedIn
            </a>
            <a v-if="profile.instagram_url" :href="profile.instagram_url" target="_blank" class="social-link">
              Instagram
            </a>
            <a v-if="profile.twitter_url" :href="profile.twitter_url" target="_blank" class="social-link">
              Twitter
            </a>
            <a v-if="profile.github_url" :href="profile.github_url" target="_blank" class="social-link">
              GitHub
            </a>
          </div>
        </div>
      </div>
      
      <!-- Bento Grid Layout -->
      <div class="bento-grid">
        <!-- About Card -->
        <div v-if="profile.about" class="bento-card about-card">
          <h2>// ABOUT</h2>
          <div class="content" v-html="formatText(profile.about)"></div>
        </div>
        
        <!-- Skills Card -->
        <div v-if="profile.skills" class="bento-card skills-card">
          <h2>// SKILLS</h2>
          <div class="skills-list">
            <span v-for="skill in parseList(profile.skills)" :key="skill" class="skill-tag">
              {{ skill }}
            </span>
          </div>
        </div>
        
        <!-- Experience Card -->
        <div v-if="profile.experience" class="bento-card experience-card">
          <h2>// EXPERIENCE</h2>
          <div class="content" v-html="formatText(profile.experience)"></div>
        </div>
        
        <!-- Education Card -->
        <div v-if="profile.education" class="bento-card education-card">
          <h2>// EDUCATION</h2>
          <div class="content" v-html="formatText(profile.education)"></div>
        </div>
        
        <!-- Projects Card -->
        <div v-if="profile.projects" class="bento-card projects-card">
          <h2>// PROJECTS</h2>
          <div class="content" v-html="formatText(profile.projects)"></div>
        </div>
        
        <!-- Photos Card -->
        <div v-if="photos.length > 0" class="bento-card photos-card">
          <h2>// PHOTOS</h2>
          <div class="photo-gallery">
            <div v-for="photo in photos.slice(0, 6)" :key="photo.id" class="photo-item" @click="openPhoto(photo)">
              <img :src="photo.url" :alt="photo.caption || 'Photo'" />
            </div>
          </div>
        </div>
        
        <!-- Blog Posts Card -->
        <div v-if="blogPosts.length > 0" class="bento-card blog-card">
          <h2>// BLOG</h2>
          <div class="blog-list">
            <div v-for="post in blogPosts.slice(0, 3)" :key="post.id" class="blog-item" @click="viewBlog(post.id)">
              <h3>{{ post.title }}</h3>
              <p class="blog-meta">{{ formatDate(post.created_at) }}</p>
              <p class="blog-excerpt">{{ post.excerpt || (post.content.length > 100 ? post.content.substring(0, 100) + '...' : post.content) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div v-else class="container">
      <p>Portfolio not found</p>
    </div>
    
    <!-- Photo Modal -->
    <div v-if="selectedPhoto" class="photo-modal" @click="closePhoto">
      <div class="modal-content" @click.stop>
        <button class="close-btn" @click="closePhoto">×</button>
        <img :src="selectedPhoto.url" :alt="selectedPhoto.caption" />
        <p v-if="selectedPhoto.caption">{{ selectedPhoto.caption }}</p>
      </div>
    </div>
    
    <!-- Followers Modal -->
    <div v-if="showFollowersModal" class="modal-overlay" @click="showFollowersModal = false">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h2>Followers</h2>
          <button class="close-btn" @click="showFollowersModal = false">×</button>
        </div>
        <div class="modal-body">
          <div v-if="followersLoading" class="loading">Loading...</div>
          <div v-else-if="followers.length === 0" class="empty">No followers yet</div>
          <div v-else class="followers-list">
            <div v-for="follower in followers" :key="follower.id" class="follower-item">
              <router-link :to="`/portfolio/${follower.username}`" class="follower-link">
                <img v-if="follower.avatar_url" :src="follower.avatar_url" :alt="follower.name" class="follower-avatar" />
                <div class="follower-info">
                  <strong>{{ follower.name || follower.username }}</strong>
                  <span v-if="follower.bio">{{ follower.bio }}</span>
                </div>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Meeting Request Modal -->
    <div v-if="showMeetingModal" class="modal-overlay" @click="showMeetingModal = false">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h2>Schedule a Meeting</h2>
          <button class="close-btn" @click="showMeetingModal = false">×</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="requestMeeting">
            <div class="form-group">
              <label>Google Meet Link</label>
              <input 
                v-model="meetingForm.google_meet_link" 
                type="url" 
                placeholder="https://meet.google.com/..." 
                required
              />
            </div>
            <div class="form-group">
              <label>Scheduled Time</label>
              <input 
                v-model="meetingForm.scheduled_time" 
                type="datetime-local" 
                required
              />
            </div>
            <div class="form-group">
              <label>Message (optional)</label>
              <textarea 
                v-model="meetingForm.message" 
                rows="3" 
                placeholder="Add a message about the meeting..."
              ></textarea>
            </div>
            <div class="form-actions">
              <button type="submit" class="button primary" :disabled="meetingLoading">
                {{ meetingLoading ? 'Sending...' : 'Send Request' }}
              </button>
              <button type="button" class="button secondary" @click="showMeetingModal = false">
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    
    <!-- Advertisement for non-logged-in users -->
    <div v-if="!currentUser" class="portfolio-ad">
      <div class="ad-content">
        <h3>Create Your Own Portfolio</h3>
        <p>Showcase your work and connect with others</p>
        <router-link to="/login" class="ad-button">Get Started</router-link>
      </div>
    </div>
    
    <!-- Footer -->
    <footer class="portfolio-footer">
      <p>Start Portraying Today</p>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../supabase'

const route = useRoute()
const router = useRouter()
const profile = ref(null)
const photos = ref([])
const blogPosts = ref([])
const loading = ref(true)
const selectedPhoto = ref(null)
const currentUser = ref(null)
const isFollowing = ref(false)
const followLoading = ref(false)
const followersCount = ref(0)
const followingCount = ref(0)
const followers = ref([])
const showFollowersModal = ref(false)
const followersLoading = ref(false)
const showMeetingModal = ref(false)
const meetingLoading = ref(false)
const meetingForm = ref({
  google_meet_link: '',
  scheduled_time: '',
  message: ''
})

const loadPortfolio = async () => {
  try {
    const username = route.params.username
    
    if (!username) {
      loading.value = false
      return
    }
    
    // Get current user
    const { data: { user } } = await supabase.auth.getUser()
    currentUser.value = user
    
    // Get profile
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('username', username)
      .single()
    
    if (profileError) throw profileError
    profile.value = profileData
    
    // Get photos
    const { data: photosData } = await supabase
      .from('photos')
      .select('*')
      .eq('profile_id', profileData.id)
      .order('created_at', { ascending: false })
      .limit(6)
    
    photos.value = photosData || []
    
    // Get blog posts
    const { data: blogData } = await supabase
      .from('blog_posts')
      .select('*')
      .eq('profile_id', profileData.id)
      .order('created_at', { ascending: false })
      .limit(3)
    
    blogPosts.value = blogData || []
    
    // Check if current user is following this profile
    if (user) {
      const { data: followData } = await supabase
        .from('follows')
        .select('id')
        .eq('follower_id', user.id)
        .eq('following_id', profileData.id)
        .single()
      
      isFollowing.value = !!followData
    }
    
    // Get followers count
    const { count: followersCountData } = await supabase
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('following_id', profileData.id)
    
    followersCount.value = followersCountData || 0
    
    // Get following count
    const { count: followingCountData } = await supabase
      .from('follows')
      .select('*', { count: 'exact', head: true })
      .eq('follower_id', profileData.id)
    
    followingCount.value = followingCountData || 0
  } catch (err) {
    console.error('Error loading portfolio:', err)
  } finally {
    loading.value = false
  }
}

const toggleFollow = async () => {
  if (!currentUser.value) {
    router.push('/login')
    return
  }
  
  followLoading.value = true
  try {
    if (isFollowing.value) {
      // Unfollow
      const { error } = await supabase
        .from('follows')
        .delete()
        .eq('follower_id', currentUser.value.id)
        .eq('following_id', profile.value.id)
      
      if (error) throw error
      isFollowing.value = false
      followersCount.value--
    } else {
      // Follow
      const { error } = await supabase
        .from('follows')
        .insert({
          follower_id: currentUser.value.id,
          following_id: profile.value.id
        })
      
      if (error) throw error
      isFollowing.value = true
      followersCount.value++
    }
  } catch (err) {
    console.error('Error toggling follow:', err)
    alert('Error: ' + err.message)
  } finally {
    followLoading.value = false
  }
}

const loadFollowers = async () => {
  followersLoading.value = true
  try {
    const { data } = await supabase
      .from('follows')
      .select(`
        follower_id,
        profiles!follows_follower_id_fkey (
          id,
          username,
          name,
          bio,
          avatar_url
        )
      `)
      .eq('following_id', profile.value.id)
    
    followers.value = (data || []).map(f => f.profiles).filter(Boolean)
  } catch (err) {
    console.error('Error loading followers:', err)
  } finally {
    followersLoading.value = false
  }
}

const requestMeeting = async () => {
  if (!currentUser.value) {
    router.push('/login')
    return
  }
  
  meetingLoading.value = true
  try {
    const { error } = await supabase
      .from('meetings')
      .insert({
        requester_id: currentUser.value.id,
        recipient_id: profile.value.id,
        google_meet_link: meetingForm.value.google_meet_link,
        scheduled_time: meetingForm.value.scheduled_time,
        message: meetingForm.value.message || null,
        status: 'pending'
      })
    
    if (error) throw error
    
    alert('Meeting request sent!')
    showMeetingModal.value = false
    meetingForm.value = {
      google_meet_link: '',
      scheduled_time: '',
      message: ''
    }
  } catch (err) {
    console.error('Error requesting meeting:', err)
    alert('Error: ' + err.message)
  } finally {
    meetingLoading.value = false
  }
}

const formatText = (text) => {
  if (!text) return ''
  return text.replace(/\n/g, '<br>')
}

const parseList = (text) => {
  if (!text) return []
  return text.split(',').map(s => s.trim()).filter(Boolean)
}

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const openPhoto = (photo) => {
  selectedPhoto.value = photo
}

const closePhoto = () => {
  selectedPhoto.value = null
}

const viewBlog = (id) => {
  router.push(`/blog/${id}`)
}

onMounted(() => {
  loadPortfolio()
})

// Watch for followers modal
watch(showFollowersModal, (newVal) => {
  if (newVal && profile.value) {
    loadFollowers()
  }
})
</script>

<style scoped>
.portfolio-container {
  min-height: 100vh;
  background: #f5f5f0;
  position: relative;
  padding-bottom: 60px; /* Space for footer */
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

/* Advertisement Styles */
.portfolio-ad {
  position: fixed;
  bottom: 30px;
  right: 30px;
  background: #1a1a1a;
  color: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 100;
  max-width: 280px;
  animation: slideIn 0.5s ease-out;
}

.portfolio-ad h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.1rem;
  color: #fff;
}

.portfolio-ad p {
  margin: 0 0 1rem 0;
  font-size: 0.9rem;
  opacity: 0.9;
}

.ad-button {
  display: inline-block;
  background: #4a90e2;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  text-decoration: none;
  font-weight: 500;
  transition: background-color 0.2s;
}

.ad-button:hover {
  background: #3a7bc8;
}

/* Footer Styles */
.portfolio-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  width: 100%;
  background: #1a1a1a;
  color: white;
  text-align: center;
  padding: 1rem 0;
  font-size: 1.1rem;
  letter-spacing: 1px;
}

.portfolio-footer p {
  margin: 0;
}

@keyframes slideIn {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.logo {
  font-weight: 600;
  font-size: 1.2rem;
  text-decoration: none;
  color: #1a1a1a;
}

.nav-links {
  display: flex;
  gap: 1.5rem;
}

.nav-links a {
  text-decoration: none;
  color: #1a1a1a;
}

.portfolio-content {
  padding: 3rem 0;
}

.portfolio-header {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 8px;
  padding: 2rem;
  margin-bottom: 2rem;
  display: flex;
  gap: 2rem;
}

.avatar {
  width: 150px;
  height: 150px;
  border-radius: 4px;
  overflow: hidden;
  border: 1px solid #1a1a1a;
  flex-shrink: 0;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.header-info {
  flex: 1;
}

.header-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.header-info h1 {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
}

.location {
  color: #666;
  font-size: 0.9rem;
}

.header-actions {
  display: flex;
  gap: 1rem;
}

.follow-btn, .meet-btn {
  padding: 0.6em 1.2em;
  border: 1px solid #1a1a1a;
  background: #ffffff;
  cursor: pointer;
  font-size: 0.9rem;
  border-radius: 4px;
  transition: all 0.2s;
}

.follow-btn.following {
  background: #1a1a1a;
  color: #f5f5f0;
}

.follow-btn:hover, .meet-btn:hover {
  background: #1a1a1a;
  color: #f5f5f0;
}

.bio {
  font-size: 1.1rem;
  color: #333;
  margin-bottom: 1rem;
  line-height: 1.6;
}

.stats {
  display: flex;
  gap: 2rem;
  margin-bottom: 1rem;
}

.stat-item {
  cursor: pointer;
  display: flex;
  flex-direction: column;
}

.stat-item strong {
  font-size: 1.2rem;
}

.stat-item span {
  font-size: 0.85rem;
  color: #666;
}

.social-links {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.social-link {
  padding: 0.4em 0.8em;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  text-decoration: none;
  font-size: 0.9em;
  color: #1a1a1a;
}

.social-link:hover {
  background: #1a1a1a;
  color: #f5f5f0;
}

/* Bento Grid Layout */
.bento-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
  grid-auto-rows: minmax(200px, auto);
}

.bento-card {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 8px;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
}

.bento-card h2 {
  font-size: 1.2rem;
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #1a1a1a;
}

.about-card {
  grid-column: span 2;
}

.skills-card {
  grid-row: span 1;
}

.skills-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.skill-tag {
  padding: 0.4em 0.8em;
  background: #f5f5f0;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  font-size: 0.85rem;
}

.experience-card, .education-card, .projects-card {
  grid-column: span 1;
}

.content {
  line-height: 1.8;
  color: #333;
  flex: 1;
}

.photos-card {
  grid-column: span 2;
}

.photo-gallery {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 1rem;
}

.photo-item {
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.2s;
  aspect-ratio: 1;
}

.photo-item:hover {
  transform: scale(1.05);
}

.photo-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.blog-card {
  grid-column: span 2;
}

.blog-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.blog-item {
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  padding: 1rem;
  cursor: pointer;
  transition: background 0.2s;
}

.blog-item:hover {
  background: #f5f5f0;
}

.blog-item h3 {
  margin-bottom: 0.5rem;
  font-size: 1.1rem;
}

.blog-meta {
  font-size: 0.85em;
  color: #666;
  margin-bottom: 0.5rem;
}

.blog-excerpt {
  color: #333;
  line-height: 1.6;
  font-size: 0.9rem;
}

/* Modals */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 2rem;
}

.modal {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 8px;
  max-width: 500px;
  width: 100%;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #1a1a1a;
}

.modal-header h2 {
  margin: 0;
  font-size: 1.5rem;
}

.modal-header .close-btn {
  background: transparent;
  border: none;
  font-size: 2rem;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  line-height: 1;
}

.modal-body {
  padding: 1.5rem;
}

.followers-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.follower-item {
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  padding: 1rem;
}

.follower-link {
  display: flex;
  gap: 1rem;
  align-items: center;
  text-decoration: none;
  color: #1a1a1a;
}

.follower-avatar {
  width: 50px;
  height: 50px;
  border-radius: 4px;
  border: 1px solid #1a1a1a;
  object-fit: cover;
}

.follower-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.follower-info strong {
  font-size: 1rem;
}

.follower-info span {
  font-size: 0.85rem;
  color: #666;
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
  padding: 0.6em;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  font-size: 1rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1.5rem;
}

.button {
  padding: 0.6em 1.2em;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.button.primary {
  background: #1a1a1a;
  color: #f5f5f0;
}

.button.secondary {
  background: #ffffff;
  color: #1a1a1a;
}

.button:hover {
  opacity: 0.9;
}

.button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.photo-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 2rem;
}

.photo-modal .modal-content {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
}

.photo-modal .modal-content img {
  max-width: 100%;
  max-height: 80vh;
  object-fit: contain;
}

.photo-modal .close-btn {
  position: absolute;
  top: -2rem;
  right: 0;
  background: transparent;
  border: none;
  color: #f5f5f0;
  font-size: 2rem;
  cursor: pointer;
  padding: 0;
  width: 40px;
  height: 40px;
}

.photo-modal .modal-content p {
  color: #f5f5f0;
  text-align: center;
  margin-top: 1rem;
}

.empty {
  text-align: center;
  color: #666;
  padding: 2rem;
}

.loading {
  text-align: center;
  padding: 2rem;
}

@media (max-width: 768px) {
  .portfolio-header {
    flex-direction: column;
  }
  
  .avatar {
    width: 120px;
    height: 120px;
  }
  
  .header-info h1 {
    font-size: 2rem;
  }
  
  .header-top {
    flex-direction: column;
    gap: 1rem;
  }
  
  .bento-grid {
    grid-template-columns: 1fr;
  }
  
  .about-card,
  .photos-card,
  .blog-card {
    grid-column: span 1;
  }
}
</style>

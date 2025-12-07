<template>
  <div class="home-container">
    <nav class="navbar">
      <div class="nav-content">
        <router-link to="/" class="logo">// PortFILIA</router-link>
        <div class="nav-links">
          <router-link v-if="user" to="/edit">Edit Portfolio</router-link>
          <router-link v-else to="/login">Login</router-link>
        </div>
      </div>
    </nav>
    
    <div class="container">
      <div class="hero">
        <h1>// CREATE YOUR PortFILIA</h1>
        <p>Build your personal portfolio, showcase your work, and share your story.</p>
        <div class="cta-buttons">
          <router-link v-if="user" to="/edit" class="button primary">
            Edit Your Portfolio
          </router-link>
          <router-link v-else to="/login" class="button primary">
            Get Started
          </router-link>
        </div>
        <div class="search-section">
          <h3>// VIEW PortFILIA</h3>
          <div class="search-box">
            <input
              v-model="searchUsername"
              type="text"
              placeholder="Enter username"
              @keyup.enter="viewPortfolio"
            />
            <button @click="viewPortfolio" class="button primary">View</button>
          </div>
        </div>
      </div>
      
      <div class="features">
        <div class="feature-card">
          <h3>// SOCIAL LINKS</h3>
          <p>Connect your LinkedIn, Instagram, Twitter, Pinterest, and GitHub profiles</p>
        </div>
        <div class="feature-card">
          <h3>// PHOTO GALLERY</h3>
          <p>Upload and showcase your photos and projects</p>
        </div>
        <div class="feature-card">
          <h3>// BLOG</h3>
          <p>Share your thoughts and experiences through blog posts</p>
        </div>
      </div>

      <div class="features-container">
        <h2 class="section-title">// CONNECT & COLLABORATE</h2>
        <div class="features-grid">
          <div class="feature-card">
            <h3>📅 Schedule Meets</h3>
            <p>Easily schedule one-on-one meetings with other users through our integrated calendar system. Share your availability and let others book time with you.</p>
          </div>
          <div class="feature-card">
            <h3>👥 Follow Users</h3>
            <p>Stay updated with your favorite creators by following them. Get notified about their latest projects, posts, and updates in your feed.</p>
          </div>
          <div class="feature-card">
            <h3>🔍 Search & Discover</h3>
            <p>Find other professionals and creators using our powerful search. Filter by skills, interests, or industry to connect with like-minded individuals.</p>
          </div>
          <div class="feature-card">
            <h3>🔗 Share Your Profile</h3>
            <p>Share your unique profile link anywhere. Your personal portfolio is always accessible at portfolio-app.com/yourusername</p>
          </div>
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
const user = ref(null)
const searchUsername = ref('')

const viewPortfolio = () => {
  if (searchUsername.value.trim()) {
    router.push(`/portfolio/${searchUsername.value.trim()}`)
  }
}

onMounted(async () => {
  const { data: { session } } = await supabase.auth.getSession()
  user.value = session?.user || null
  
  supabase.auth.onAuthStateChange((_event, session) => {
    user.value = session?.user || null
  })
})
</script>

<style scoped>
.home-container {
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
}

.nav-links a {
  text-decoration: none;
}

.hero {
  text-align: center;
  padding: 4rem 0;
}

.hero h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.hero p {
  font-size: 1.2rem;
  margin-bottom: 2rem;
  color: #333;
}

.cta-buttons {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

.button {
  padding: 0.8em 2em;
  text-decoration: none;
  display: inline-block;
}

.button.primary {
  background: #1a1a1a;
  color: #f5f5f0;
  border: 1px solid #1a1a1a;
}

.button.primary:hover {
  background: #333;
}

.search-section {
  margin-top: 3rem;
  padding: 2rem;
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  max-width: 500px;
  margin-left: auto;
  margin-right: auto;
}

.search-section h3 {
  margin-bottom: 1rem;
  font-size: 1.2rem;
}

.search-box {
  display: flex;
  gap: 0.5rem;
}

.search-box input {
  flex: 1;
}

.features, .features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
  margin: 4rem 0;
}

.features-container {
  margin: 6rem 0;
  padding: 2rem 0;
  border-top: 1px solid #f0f0f0;
  border-bottom: 1px solid #f0f0f0;
}

.section-title {
  text-align: center;
  margin-bottom: 3rem;
  font-size: 2rem;
  color: #333;
  text-transform: uppercase;
  letter-spacing: 2px;
}

.feature-card {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  padding: 2rem;
  border-radius: 4px;
}

.feature-card h3 {
  margin-bottom: 1rem;
  font-size: 1.2rem;
}

.feature-card p {
  color: #333;
  line-height: 1.6;
}

@media (max-width: 768px) {
  .hero h1 {
    font-size: 2rem;
  }
  
  .nav-content {
    padding: 0 1rem;
  }
}
</style>


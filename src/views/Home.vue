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

      <section class="templates-section">
        <div class="templates-header">
          <div>
            <p class="eyebrow">// PICK A STARTER</p>
            <h2>Portfolio Templates</h2>
            <p class="subtitle">Choose a layout style. Preview it, then continue with your account.</p>
          </div>
          <button class="button secondary" @click="openTemplate(templateOptions[0])">Try Minimal</button>
        </div>

        <div class="templates-grid">
          <div
            v-for="template in templateOptions"
            :key="template.id"
            class="template-card"
            @click="openTemplate(template)"
          >
            <div class="template-label">
              <span class="pill">{{ template.category }}</span>
              <span class="pill light">{{ template.duration }}</span>
            </div>
            <h3>{{ template.name }}</h3>
            <p>{{ template.description }}</p>
            <div class="template-preview" :class="template.style">
              <div class="preview-hero"></div>
              <div class="preview-row">
                <div class="preview-block"></div>
                <div class="preview-block short"></div>
              </div>
              <div class="preview-gallery">
                <span v-for="n in 3" :key="n" class="preview-tile"></span>
              </div>
            </div>
            <div class="template-meta">
              <span v-for="tag in template.tags" :key="tag" class="meta-tag">{{ tag }}</span>
            </div>
          </div>
        </div>
      </section>

      <div v-if="showTemplateModal && selectedTemplate" class="template-modal" @click.self="closeTemplateModal">
        <div class="template-modal-card">
          <div class="modal-header">
            <div>
              <p class="eyebrow">// TEMPLATE</p>
              <h3>{{ selectedTemplate.name }}</h3>
              <p class="subtitle">{{ selectedTemplate.description }}</p>
            </div>
            <button class="close-btn" @click="closeTemplateModal">×</button>
          </div>

          <div class="modal-preview">
            <div class="preview-hero"></div>
            <div class="preview-row">
              <div class="preview-block"></div>
              <div class="preview-block short"></div>
            </div>
            <div class="preview-gallery">
              <span v-for="n in 4" :key="n" class="preview-tile large"></span>
            </div>
          </div>

          <div class="modal-footer">
            <div class="footer-meta">
              <span class="pill">{{ selectedTemplate.category }}</span>
              <span class="pill light">{{ selectedTemplate.duration }}</span>
            </div>
            <button class="button primary" :disabled="continuing" @click="continueWithTemplate">
              {{ user ? 'Continue with this template' : 'Continue with Google' }}
            </button>
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
const selectedTemplate = ref(null)
const showTemplateModal = ref(false)
const continuing = ref(false)
const templateOptions = [
  {
    id: 'minimal',
    name: 'Minimal Narrative',
    description: 'Clean typography with generous whitespace and linear storytelling.',
    category: 'Minimal',
    duration: '~5 min setup',
    tags: ['Story first', 'Clean', 'Mono'],
    style: 'style-minimal'
  },
  {
    id: 'studio',
    name: 'Studio Grid',
    description: 'Gallery-forward layout for photographers and designers.',
    category: 'Visual',
    duration: '~7 min setup',
    tags: ['Gallery', 'Bold', 'Grid'],
    style: 'style-studio'
  },
  {
    id: 'tech',
    name: 'Tech Resume',
    description: 'Resume-inspired sections with quick stats and highlighted projects.',
    category: 'Professional',
    duration: '~6 min setup',
    tags: ['Resume', 'Cards', 'Stats'],
    style: 'style-tech'
  },
  {
    id: 'creator',
    name: 'Creator Canvas',
    description: 'Bright hero with layered cards and playful accents.',
    category: 'Creator',
    duration: '~8 min setup',
    tags: ['Color', 'Cards', 'Playful'],
    style: 'style-creator'
  },
  {
    id: 'dark',
    name: 'Dark Showcase',
    description: 'High-contrast dark mode with glowing highlights.',
    category: 'Dark',
    duration: '~6 min setup',
    tags: ['Dark', 'Contrast', 'Glow'],
    style: 'style-dark'
  }
]

const viewPortfolio = () => {
  if (searchUsername.value.trim()) {
    router.push(`/portfolio/${searchUsername.value.trim()}`)
  }
}

const openTemplate = (template) => {
  selectedTemplate.value = template
  showTemplateModal.value = true
}

const closeTemplateModal = () => {
  showTemplateModal.value = false
  continuing.value = false
}

const continueWithTemplate = async () => {
  if (!selectedTemplate.value) return
  continuing.value = true
  localStorage.setItem('selectedTemplate', selectedTemplate.value.id)

  if (user.value) {
    router.push(`/edit?template=${selectedTemplate.value.id}`)
    showTemplateModal.value = false
    continuing.value = false
    return
  }

  try {
    await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback?template=${selectedTemplate.value.id}`
      }
    })
  } catch (err) {
    console.error('Google sign-in failed', err)
    continuing.value = false
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

.templates-section {
  margin: 5rem 0 2rem;
  padding: 2.5rem;
  border: 1px solid #1a1a1a;
  border-radius: 8px;
  background: #ffffff;
}

.templates-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 2rem;
}

.eyebrow {
  letter-spacing: 2px;
  text-transform: uppercase;
  font-size: 0.8rem;
  margin-bottom: 0.5rem;
  color: #666;
}

.templates-header h2 {
  font-size: 2rem;
  margin-bottom: 0.25rem;
}

.subtitle {
  color: #555;
  margin-top: 0.25rem;
}

.templates-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.25rem;
}

.template-card {
  border: 1px solid #1a1a1a;
  border-radius: 8px;
  padding: 1.25rem;
  background: #fafafa;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.template-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.08);
}

.template-card h3 {
  margin: 0.5rem 0 0.25rem;
}

.template-card p {
  color: #555;
  margin-bottom: 1rem;
}

.template-label {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.pill {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.6rem;
  border: 1px solid #1a1a1a;
  border-radius: 999px;
  font-size: 0.8rem;
}

.pill.light {
  background: #f5f5f5;
  border-color: #d6d6d6;
}

.template-preview {
  border: 1px solid #1a1a1a;
  border-radius: 6px;
  padding: 0.75rem;
  background: linear-gradient(135deg, #f8f8f8, #ffffff);
  margin-bottom: 0.75rem;
}

.template-preview .preview-hero {
  height: 90px;
  border-radius: 4px;
  background: linear-gradient(120deg, #e0e7ff, #f5f3ff);
  margin-bottom: 0.6rem;
}

.template-preview .preview-row {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 0.5rem;
  margin-bottom: 0.6rem;
}

.template-preview .preview-block {
  height: 40px;
  border-radius: 4px;
  background: #eef2ff;
}

.template-preview .preview-block.short {
  background: #e0e7ff;
}

.template-preview .preview-gallery {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.4rem;
}

.template-preview .preview-tile {
  height: 34px;
  border-radius: 4px;
  background: #d9e8ff;
}

.template-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.meta-tag {
  background: #1a1a1a;
  color: #f5f5f0;
  padding: 0.25rem 0.55rem;
  border-radius: 4px;
  font-size: 0.8rem;
}

.style-studio .preview-hero {
  background: linear-gradient(120deg, #ffe8d6, #ffd6a5);
}

.style-tech .preview-hero {
  background: linear-gradient(120deg, #d1fae5, #a7f3d0);
}

.style-creator .preview-hero {
  background: linear-gradient(120deg, #fde68a, #fcd34d);
}

.style-dark {
  background: #0f172a;
  border-color: #0f172a;
}

.style-dark .preview-hero {
  background: linear-gradient(120deg, #1e293b, #0f172a);
}

.style-dark .preview-block,
.style-dark .preview-block.short,
.style-dark .preview-tile {
  background: #1f2937;
}

.template-modal {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
  z-index: 999;
}

.template-modal-card {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 10px;
  max-width: 720px;
  width: 100%;
  padding: 1.5rem;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.12);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  align-items: flex-start;
}

.close-btn {
  background: transparent;
  border: none;
  font-size: 1.5rem;
  line-height: 1;
  cursor: pointer;
  padding: 0.25rem 0.5rem;
}

.modal-header h3 {
  margin: 0.2rem 0;
  font-size: 1.6rem;
}

.modal-preview {
  border: 1px solid #1a1a1a;
  border-radius: 8px;
  padding: 1rem;
  margin: 1rem 0 1.25rem;
  background: linear-gradient(135deg, #f8f8f8, #ffffff);
}

.modal-preview .preview-hero {
  height: 150px;
  border-radius: 6px;
  background: linear-gradient(120deg, #e0e7ff, #f5f3ff);
  margin-bottom: 0.75rem;
}

.modal-preview .preview-row {
  display: grid;
  grid-template-columns: 3fr 1fr;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.modal-preview .preview-block {
  height: 70px;
  border-radius: 6px;
  background: #eef2ff;
}

.modal-preview .preview-block.short {
  background: #e0e7ff;
}

.modal-preview .preview-gallery {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 0.5rem;
}

.modal-preview .preview-tile.large {
  height: 60px;
  border-radius: 6px;
  background: #d9e8ff;
}

.modal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.footer-meta {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

@media (max-width: 768px) {
  .hero h1 {
    font-size: 2rem;
  }
  
  .nav-content {
    padding: 0 1rem;
  }

  .templates-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .template-modal-card {
    padding: 1.1rem;
  }
}
</style>


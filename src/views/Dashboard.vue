<template>
  <div class="dashboard-container">
    <nav class="navbar">
      <div class="nav-content">
        <router-link to="/" class="logo">// PortFILIA</router-link>
        <div class="nav-links">
          <router-link v-if="profile?.username" :to="`/portfolio/${profile.username}`">
            View Portfolio
          </router-link>
          <router-link to="/edit">Edit Portfolio</router-link>
          <button @click="handleLogout" class="logout-btn">Logout</button>
        </div>
      </div>
    </nav>

    <div class="container">
      <div v-if="loading" class="loading">
        <p>Loading...</p>
      </div>

      <div v-else class="dashboard-content">
        <h1>// DASHBOARD</h1>

        <div class="grid">
          <section class="card">
            <header>
              <h2>Custom Domain</h2>
              <p class="muted">Connect your own domain for your portfolio.</p>
            </header>
            <div class="form-group">
              <label>Custom Domain (optional)</label>
              <input
                v-model="formData.custom_domain"
                type="url"
                placeholder="https://yourdomain.com"
              />
              <small>
                Portfolio link will use your domain if set.
                Current link:
                <a v-if="portfolioLink" :href="portfolioLink" target="_blank" rel="noopener">
                  {{ portfolioLink }}
                </a>
              </small>
            </div>
            <button class="button primary" :disabled="saving" @click="saveDomainAndTheme">
              {{ saving ? 'Saving...' : 'Save Domain' }}
            </button>
          </section>

          <section class="card">
            <header>
              <h2>Theme</h2>
              <p class="muted">Pick a look for your public portfolio.</p>
            </header>
            <div class="theme-grid">
              <div
                v-for="theme in themeOptions"
                :key="theme.id"
                :class="['theme-card', { active: formData.theme === theme.id }]"
                @click="selectTheme(theme.id)"
              >
                <div class="theme-top">
                  <div>
                    <p class="pill">{{ theme.category }}</p>
                    <h3>{{ theme.name }}</h3>
                    <p class="muted">{{ theme.description }}</p>
                  </div>
                  <button class="button secondary small" type="button">Use</button>
                </div>
                <div class="theme-preview" :class="theme.previewClass">
                  <div class="preview-hero"></div>
                  <div class="preview-row">
                    <span class="preview-block"></span>
                    <span class="preview-block short"></span>
                  </div>
                  <div class="preview-gallery">
                    <span v-for="n in 3" :key="n" class="preview-tile"></span>
                  </div>
                </div>
                <div class="theme-tags">
                  <span v-for="tag in theme.tags" :key="tag" class="meta-tag">{{ tag }}</span>
                </div>
              </div>
            </div>
            <div class="actions">
              <button class="button primary" :disabled="saving" @click="saveDomainAndTheme">
                {{ saving ? 'Saving...' : 'Save Theme' }}
              </button>
            </div>
          </section>
        </div>

        <section class="card">
          <header>
            <h2>Meeting Requests</h2>
            <p class="muted">Manage incoming, outgoing, and accepted meetings.</p>
          </header>

          <div class="meetings-tabs">
            <button 
              @click="meetingsTab = 'incoming'" 
              :class="['tab-btn', { active: meetingsTab === 'incoming' }]"
            >
              Incoming ({{ incomingMeetings.length }})
            </button>
            <button 
              @click="meetingsTab = 'outgoing'" 
              :class="['tab-btn', { active: meetingsTab === 'outgoing' }]"
            >
              Outgoing ({{ outgoingMeetings.length }})
            </button>
            <button 
              @click="meetingsTab = 'accepted'" 
              :class="['tab-btn', { active: meetingsTab === 'accepted' }]"
            >
              Accepted ({{ acceptedMeetings.length }})
            </button>
          </div>

          <!-- Incoming Meetings -->
          <div v-if="meetingsTab === 'incoming'" class="meetings-list">
            <div v-if="incomingMeetings.length === 0" class="empty-state">
              No incoming meeting requests
            </div>
            <div v-for="meeting in incomingMeetings" :key="meeting.id" class="meeting-item">
              <div class="meeting-info">
                <strong>{{ meeting.requester?.name || meeting.requester?.username }}</strong>
                <p>{{ formatDateTime(meeting.scheduled_time) }}</p>
                <p v-if="meeting.message" class="meeting-message">{{ meeting.message }}</p>
                <a v-if="meeting.status === 'accepted'" :href="meeting.google_meet_link" target="_blank" class="meet-link">
                  Join Google Meet →
                </a>
              </div>
              <div v-if="meeting.status === 'pending'" class="meeting-actions">
                <button @click="updateMeetingStatus(meeting.id, 'accepted')" class="button primary small">
                  Accept
                </button>
                <button @click="updateMeetingStatus(meeting.id, 'declined')" class="button secondary small">
                  Decline
                </button>
              </div>
              <div v-else class="meeting-status">
                <span :class="['status-badge', meeting.status]">{{ meeting.status }}</span>
              </div>
            </div>
          </div>

          <!-- Outgoing Meetings -->
          <div v-if="meetingsTab === 'outgoing'" class="meetings-list">
            <div v-if="outgoingMeetings.length === 0" class="empty-state">
              No outgoing meeting requests
            </div>
            <div v-for="meeting in outgoingMeetings" :key="meeting.id" class="meeting-item">
              <div class="meeting-info">
                <strong>{{ meeting.recipient?.name || meeting.recipient?.username }}</strong>
                <p>{{ formatDateTime(meeting.scheduled_time) }}</p>
                <p v-if="meeting.message" class="meeting-message">{{ meeting.message }}</p>
                <a v-if="meeting.status === 'accepted'" :href="meeting.google_meet_link" target="_blank" class="meet-link">
                  Join Google Meet →
                </a>
              </div>
              <div class="meeting-status">
                <span :class="['status-badge', meeting.status]">{{ meeting.status }}</span>
                <button v-if="meeting.status === 'pending'" @click="cancelMeeting(meeting.id)" class="button secondary small">
                  Cancel
                </button>
              </div>
            </div>
          </div>

          <!-- Accepted Meetings -->
          <div v-if="meetingsTab === 'accepted'" class="meetings-list">
            <div v-if="acceptedMeetings.length === 0" class="empty-state">
              No accepted meetings
            </div>
            <div v-for="meeting in acceptedMeetings" :key="meeting.id" class="meeting-item">
              <div class="meeting-info">
                <strong>
                  {{ meeting.requester_id === profile?.id 
                    ? (meeting.recipient?.name || meeting.recipient?.username)
                    : (meeting.requester?.name || meeting.requester?.username)
                  }}
                </strong>
                <p>{{ formatDateTime(meeting.scheduled_time) }}</p>
                <a :href="meeting.google_meet_link" target="_blank" class="meet-link">
                  Join Google Meet →
                </a>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()
const profile = ref(null)
const loading = ref(true)
const saving = ref(false)

const formData = ref({
  custom_domain: '',
  theme: ''
})

const meetingsTab = ref('incoming')
const incomingMeetings = ref([])
const outgoingMeetings = ref([])
const acceptedMeetings = ref([])

const themeOptions = [
  {
    id: 'minimal',
    name: 'Minimal Narrative',
    description: 'Clean typography and linear storytelling.',
    category: 'Minimal',
    tags: ['Clean', 'Mono'],
    previewClass: 'theme-minimal'
  },
  {
    id: 'studio',
    name: 'Studio Grid',
    description: 'Gallery-forward layout for visuals.',
    category: 'Visual',
    tags: ['Gallery', 'Grid'],
    previewClass: 'theme-studio'
  },
  {
    id: 'tech',
    name: 'Tech Resume',
    description: 'Resume-inspired sections and stats.',
    category: 'Professional',
    tags: ['Cards', 'Stats'],
    previewClass: 'theme-tech'
  },
  {
    id: 'creator',
    name: 'Creator Canvas',
    description: 'Playful cards with color pops.',
    category: 'Creator',
    tags: ['Color', 'Cards'],
    previewClass: 'theme-creator'
  },
  {
    id: 'dark',
    name: 'Dark Showcase',
    description: 'High-contrast dark mode.',
    category: 'Dark',
    tags: ['Dark', 'Glow'],
    previewClass: 'theme-dark'
  }
]

const formattedCustomDomain = computed(() => {
  const domain = formData.value.custom_domain?.trim()
  if (!domain) return ''
  return /^https?:\/\//i.test(domain) ? domain.replace(/\/+$/, '') : `https://${domain.replace(/\/+$/, '')}`
})

const portfolioLink = computed(() => {
  const base = `${window.location.origin}/portfolio/${profile.value?.username || 'username'}`
  return formattedCustomDomain.value || base
})

const selectTheme = (id) => {
  formData.value.theme = id
}

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
      formData.value.custom_domain = profileData.custom_domain || ''
      formData.value.theme = profileData.theme || localStorage.getItem('selectedTemplate') || themeOptions[0].id
    } else {
      formData.value.theme = localStorage.getItem('selectedTemplate') || themeOptions[0].id
    }
  } catch (err) {
    console.error('Error loading profile:', err)
  } finally {
    loading.value = false
  }
}

const saveDomainAndTheme = async () => {
  saving.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()
    const sanitizedDomain = formattedCustomDomain.value || null

    const { error } = await supabase
      .from('profiles')
      .upsert({
        id: user.id,
        custom_domain: sanitizedDomain,
        theme: formData.value.theme
      })

    if (error) throw error
    formData.value.custom_domain = sanitizedDomain || ''
    alert('Settings saved!')
  } catch (err) {
    alert('Error saving settings: ' + err.message)
  } finally {
    saving.value = false
  }
}

const loadMeetings = async () => {
  if (!profile.value) return

  try {
    const { data: incomingData } = await supabase
      .from('meetings')
      .select(`
        *,
        requester:profiles!meetings_requester_id_fkey(id, username, name, avatar_url)
      `)
      .eq('recipient_id', profile.value.id)
      .order('created_at', { ascending: false })

    incomingMeetings.value = incomingData || []

    const { data: outgoingData } = await supabase
      .from('meetings')
      .select(`
        *,
        recipient:profiles!meetings_recipient_id_fkey(id, username, name, avatar_url)
      `)
      .eq('requester_id', profile.value.id)
      .order('created_at', { ascending: false })

    outgoingMeetings.value = outgoingData || []

    const { data: acceptedData } = await supabase
      .from('meetings')
      .select(`
        *,
        requester:profiles!meetings_requester_id_fkey(id, username, name, avatar_url),
        recipient:profiles!meetings_recipient_id_fkey(id, username, name, avatar_url)
      `)
      .eq('status', 'accepted')
      .or(`requester_id.eq.${profile.value.id},recipient_id.eq.${profile.value.id}`)
      .order('scheduled_time', { ascending: true })

    acceptedMeetings.value = acceptedData || []
  } catch (err) {
    console.error('Error loading meetings:', err)
  }
}

const updateMeetingStatus = async (meetingId, status) => {
  try {
    const { error } = await supabase
      .from('meetings')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', meetingId)

    if (error) throw error
    await loadMeetings()
  } catch (err) {
    console.error('Error updating meeting:', err)
    alert('Error: ' + err.message)
  }
}

const cancelMeeting = async (meetingId) => {
  if (!confirm('Cancel this meeting request?')) return

  try {
    const { error } = await supabase
      .from('meetings')
      .update({ status: 'cancelled', updated_at: new Date().toISOString() })
      .eq('id', meetingId)

    if (error) throw error
    await loadMeetings()
  } catch (err) {
    console.error('Error cancelling meeting:', err)
    alert('Error: ' + err.message)
  }
}

const formatDateTime = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit'
  })
}

const handleLogout = async () => {
  await supabase.auth.signOut()
  router.push('/')
}

onMounted(async () => {
  await loadProfile()
  await loadMeetings()
})
</script>

<style scoped>
.dashboard-container {
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

.nav-links a,
.nav-links button,
.nav-links router-link {
  text-decoration: none;
}

.logout-btn {
  background: transparent;
  border: 1px solid #1a1a1a;
  color: #1a1a1a;
  padding: 0.5em 1em;
  font-size: 0.9em;
}

.dashboard-content {
  padding: 3rem 0;
}

.dashboard-content h1 {
  margin-bottom: 2rem;
  font-size: 2rem;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.card {
  padding: 1.5rem;
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 6px;
}

.card header {
  margin-bottom: 1rem;
}

.card h2 {
  margin: 0 0 0.4rem 0;
}

.muted {
  color: #666;
  font-size: 0.95rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.form-group input {
  width: 100%;
}

.form-group small {
  display: block;
  margin-top: 0.5rem;
  font-size: 0.85em;
  color: #666;
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

.actions {
  margin-top: 1rem;
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

.button {
  padding: 0.8em 1.5em;
}

.button.primary {
  background: #1a1a1a;
  color: #f5f5f0;
}

.button.secondary {
  background: #ffffff;
  color: #1a1a1a;
  border: 1px solid #1a1a1a;
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

.loading {
  text-align: center;
  padding: 2rem;
}

@media (max-width: 768px) {
  .nav-content {
    padding: 0 1rem;
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


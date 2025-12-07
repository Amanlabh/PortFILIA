<template>
  <div class="blog-container">
    <nav class="navbar">
      <div class="nav-content">
        <router-link to="/" class="logo">// PortFILIA</router-link>
        <div class="nav-links">
          <router-link to="/">Home</router-link>
        </div>
      </div>
    </nav>
    
    <div class="container">
      <div v-if="loading" class="loading">
        <p>Loading...</p>
      </div>
      
      <div v-else-if="post" class="blog-content">
        <div v-if="isEditMode && isOwner" class="blog-editor">
          <input v-model="editData.title" placeholder="Post title" class="title-input" />
          <textarea v-model="editData.content" rows="20" placeholder="Write your blog post..."></textarea>
          <div class="editor-actions">
            <button @click="savePost" class="button primary">Save</button>
            <button @click="cancelEdit" class="button secondary">Cancel</button>
            <button @click="deletePost" class="button secondary">Delete</button>
          </div>
        </div>
        
        <div v-else class="blog-view">
          <div class="blog-header">
            <h1>{{ post.title }}</h1>
            <p class="blog-meta">
              By {{ profile?.name || profile?.username }} • {{ formatDate(post.created_at) }}
            </p>
            <div v-if="isOwner" class="blog-actions">
              <button @click="enableEdit" class="button secondary">Edit</button>
            </div>
          </div>
          <div class="blog-body" v-html="formatContent(post.content)"></div>
          <div class="blog-footer">
            <router-link :to="`/portfolio/${profile?.username}`" class="back-link">
              ← Back to portfolio
            </router-link>
          </div>
        </div>
      </div>
      
      <div v-else class="error">
        <p>Blog post not found</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../supabase'

const route = useRoute()
const router = useRouter()
const post = ref(null)
const profile = ref(null)
const loading = ref(true)
const isEditMode = ref(false)
const isOwner = ref(false)

const editData = ref({
  title: '',
  content: ''
})

const loadBlogPost = async () => {
  try {
    const postId = route.params.id
    const { data: { user } } = await supabase.auth.getUser()
    
    const { data: postData, error: postError } = await supabase
      .from('blog_posts')
      .select('*')
      .eq('id', postId)
      .single()
    
    if (postError) throw postError
    post.value = postData
    
    // Load profile
    const { data: profileData, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', postData.profile_id)
      .single()
    
    if (!profileError) {
      profile.value = profileData
    }
    
    // Check if user is owner
    if (user && user.id === postData.profile_id) {
      isOwner.value = true
    }
    
    // Check if edit mode
    if (route.query.edit === 'true' && isOwner.value) {
      isEditMode.value = true
      editData.value = {
        title: postData.title,
        content: postData.content
      }
    }
  } catch (err) {
    console.error('Error loading blog post:', err)
  } finally {
    loading.value = false
  }
}

const formatContent = (content) => {
  if (!content) return ''
  return content.replace(/\n/g, '<br>')
}

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const enableEdit = () => {
  isEditMode.value = true
  editData.value = {
    title: post.value.title,
    content: post.value.content
  }
}

const cancelEdit = () => {
  isEditMode.value = false
  router.replace({ query: {} })
}

const savePost = async () => {
  if (!editData.value.title || !editData.value.content) {
    alert('Please fill in title and content')
    return
  }
  
  try {
    const { error } = await supabase
      .from('blog_posts')
      .update({
        title: editData.value.title,
        content: editData.value.content,
        excerpt: editData.value.content.length > 150 ? editData.value.content.substring(0, 150) : editData.value.content
      })
      .eq('id', post.value.id)
    
    if (error) throw error
    
    post.value.title = editData.value.title
    post.value.content = editData.value.content
    isEditMode.value = false
    router.replace({ query: {} })
  } catch (err) {
    alert('Error saving post: ' + err.message)
  }
}

const deletePost = async () => {
  if (!confirm('Delete this blog post?')) return
  
  try {
    const { error } = await supabase
      .from('blog_posts')
      .delete()
      .eq('id', post.value.id)
    
    if (error) throw error
    
    router.push(`/portfolio/${profile.value.username}`)
  } catch (err) {
    alert('Error deleting post: ' + err.message)
  }
}

onMounted(() => {
  loadBlogPost()
})
</script>

<style scoped>
.blog-container {
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

.blog-content {
  max-width: 800px;
  margin: 3rem auto;
  padding: 0 2rem;
}

.blog-editor {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  padding: 2rem;
}

.title-input {
  width: 100%;
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 1.5rem;
  padding: 0.8rem;
}

.blog-editor textarea {
  width: 100%;
  margin-bottom: 1.5rem;
  padding: 1rem;
  font-size: 1rem;
  line-height: 1.6;
}

.editor-actions {
  display: flex;
  gap: 1rem;
}

.blog-view {
  background: #ffffff;
  border: 1px solid #1a1a1a;
  border-radius: 4px;
  padding: 3rem;
}

.blog-header {
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid #1a1a1a;
}

.blog-header h1 {
  font-size: 2.5rem;
  margin-bottom: 1rem;
  line-height: 1.2;
}

.blog-meta {
  color: #666;
  font-size: 0.9em;
  margin-bottom: 1rem;
}

.blog-actions {
  margin-top: 1rem;
}

.blog-body {
  line-height: 1.8;
  color: #333;
  font-size: 1.1rem;
  margin-bottom: 2rem;
}

.blog-footer {
  padding-top: 2rem;
  border-top: 1px solid #1a1a1a;
}

.back-link {
  text-decoration: none;
  font-size: 0.9em;
}

.loading,
.error {
  text-align: center;
  padding: 3rem;
}

@media (max-width: 768px) {
  .blog-content {
    padding: 0 1rem;
  }
  
  .blog-view {
    padding: 2rem 1.5rem;
  }
  
  .blog-header h1 {
    font-size: 2rem;
  }
}
</style>


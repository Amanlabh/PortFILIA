import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../supabase'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/Home.vue')
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/Login.vue')
    },
    {
      path: '/auth/callback',
      name: 'auth-callback',
      component: () => import('../views/AuthCallback.vue')
    },
    {
      path: '/portfolio/:username?',
      name: 'portfolio',
      component: () => import('../views/Portfolio.vue'),
      props: true
    },
    {
      path: '/edit',
      name: 'edit',
      component: () => import('../views/EditPortfolio.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/blog/:id?',
      name: 'blog',
      component: () => import('../views/BlogPost.vue'),
      props: true
    }
  ]
})

router.beforeEach(async (to, from, next) => {
  const { data: { session } } = await supabase.auth.getSession()
  
  if (to.meta.requiresAuth && !session) {
    next('/login')
  } else {
    next()
  }
})

export default router

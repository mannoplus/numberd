import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes: [
        {
            path: '/',
            name: 'dashboard',
            component: Dashboard
        },
        {
            path: '/analysis',
            name: 'analysis',
            component: () => import('../views/Analysis.vue')
        },
        {
            path: '/predictions',
            name: 'predictions',
            component: () => import('../views/Predictions.vue')
        },
        {
            path: '/history',
            name: 'history',
            component: () => import('../views/History.vue')
        },
        {
            path: '/picker',
            name: 'picker',
            component: () => import('../views/Picker.vue')
        }
    ]
})

export default router

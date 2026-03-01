<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { LayoutDashboard, BarChart3, Binary, List, Dices, Menu, X } from 'lucide-vue-next'

const route = useRoute()
const { t, locale } = useI18n()

const isMobileMenuOpen = ref(false)

watch(() => route.path, () => {
  isMobileMenuOpen.value = false
})

const navigation = [
  { nameKey: 'nav.dashboard', href: '/', icon: LayoutDashboard },
  { nameKey: 'nav.analysis', href: '/analysis', icon: BarChart3 },
  { nameKey: 'nav.predictions', href: '/predictions', icon: Binary },
  { nameKey: 'nav.history', href: '/history', icon: List },
  { nameKey: 'nav.combinatorial', href: '/picker', icon: Dices },
]

const setLanguage = (lang: string) => {
  locale.value = lang
  localStorage.setItem('numberd-locale', lang)
}
</script>

<template>
  <div class="min-h-screen bg-[#0f0f14] flex flex-col font-sans text-gray-100 relative">
    
    <!-- Mobile Sticky Header -->
    <div class="lg:hidden sticky top-0 z-40 flex h-16 shrink-0 items-center justify-between border-b border-gray-800 bg-[#12121a]/90 backdrop-blur-md px-4 shadow-sm">
      <div class="flex items-center gap-3">
        <div class="h-8 w-8 rounded-lg bg-gradient-to-br from-violet-600 to-fuchsia-500 flex items-center justify-center shadow-[0_0_15px_rgba(124,58,237,0.5)]">
          <span class="text-white font-bold text-lg leading-none">N</span>
        </div>
        <span class="text-xl font-black bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-400">
          NumberD
        </span>
      </div>
      <button 
        type="button" 
        class="flex items-center justify-center w-11 h-11 text-gray-400 hover:text-white rounded-md focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500" 
        @click="isMobileMenuOpen = true"
        aria-label="Open sidebar"
      >
        <Menu class="h-6 w-6" aria-hidden="true" />
      </button>
    </div>

    <!-- Mobile sidebar overlay -->
    <transition
      enter-active-class="transition-opacity ease-linear duration-300"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition-opacity ease-linear duration-300"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div v-show="isMobileMenuOpen" class="fixed inset-0 z-40 bg-black/80 backdrop-blur-sm lg:hidden" @click="isMobileMenuOpen = false"></div>
    </transition>

    <!-- Sidebar Wrapper -->
    <div :class="[
      'fixed inset-y-0 left-0 z-50 flex w-72 flex-col transition-transform duration-300 ease-in-out lg:translate-x-0',
      isMobileMenuOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full'
    ]">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-800 bg-[#12121a] px-6 pb-4">
        <div class="flex h-16 shrink-0 items-center justify-between mt-4">
          <div class="flex items-center gap-3">
            <div class="h-8 w-8 rounded-lg bg-gradient-to-br from-violet-600 to-fuchsia-500 flex items-center justify-center shadow-[0_0_15px_rgba(124,58,237,0.5)]">
              <span class="text-white font-bold text-lg leading-none">N</span>
            </div>
            <span class="text-2xl font-black bg-clip-text text-transparent bg-gradient-to-r from-white to-gray-400">
              NumberD
            </span>
          </div>
          <button 
            type="button" 
            class="lg:hidden flex items-center justify-center w-11 h-11 text-gray-400 hover:text-white rounded-md" 
            @click="isMobileMenuOpen = false"
            aria-label="Close sidebar"
          >
            <X class="h-6 w-6" aria-hidden="true" />
          </button>
        </div>
        <nav class="flex flex-1 flex-col mt-6">
          <ul role="list" class="flex flex-1 flex-col gap-y-7">
            <li>
              <ul role="list" class="-mx-2 space-y-2">
                <li v-for="item in navigation" :key="item.nameKey">
                  <router-link
                    :to="item.href"
                    :class="[
                      route.path === item.href
                        ? 'bg-violet-600/10 text-violet-400 border border-violet-500/20 shadow-[inset_0_0_20px_rgba(124,58,237,0.05)]'
                        : 'text-gray-400 hover:text-white hover:bg-white/5 border border-transparent',
                      'group flex gap-x-3 rounded-xl p-3 text-sm leading-6 font-medium transition-all duration-200'
                    ]"
                  >
                    <component 
                      :is="item.icon" 
                      :class="[
                        route.path === item.href ? 'text-violet-500' : 'text-gray-500 group-hover:text-gray-300',
                        'h-6 w-6 shrink-0 transition-colors duration-200'
                      ]" 
                      aria-hidden="true" 
                    />
                    {{ t(item.nameKey) }}
                  </router-link>
                </li>
              </ul>
            </li>
          </ul>
        </nav>

        <div class="mt-auto pt-6 border-t border-gray-800">
          <div class="flex items-center justify-between w-full bg-black/40 rounded-xl p-1 border border-gray-800">
            <button 
              @click="setLanguage('en')"
              :class="[
                locale === 'en' ? 'bg-gradient-to-r from-violet-600 to-fuchsia-500 text-white shadow-[0_0_10px_rgba(124,58,237,0.3)]' : 'text-gray-400 hover:text-white hover:bg-white/5',
                'flex-1 py-1.5 text-xs font-bold rounded-lg transition-all duration-300'
              ]"
            >
              EN
            </button>
            <button 
              @click="setLanguage('zh-TW')"
              :class="[
                locale === 'zh-TW' ? 'bg-gradient-to-r from-violet-600 to-fuchsia-500 text-white shadow-[0_0_10px_rgba(124,58,237,0.3)]' : 'text-gray-400 hover:text-white hover:bg-white/5',
                'flex-1 py-1.5 text-xs font-bold rounded-lg transition-all duration-300'
              ]"
            >
              中文
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main content Wrapper -->
    <div class="lg:pl-72 flex flex-col min-h-screen w-full transition-all duration-300">
      <main class="flex-grow">
        <router-view v-slot="{ Component }">
          <transition 
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="opacity-0 translate-y-4"
            enter-to-class="opacity-100 translate-y-0"
            leave-active-class="transition duration-200 ease-in"
            leave-from-class="opacity-100 translate-y-0"
            leave-to-class="opacity-0 -translate-y-4"
            mode="out-in"
          >
            <component :is="Component" />
          </transition>
        </router-view>
      </main>

      <footer class="border-t border-gray-800 bg-[#12121a]/80 backdrop-blur-md mt-auto">
        <div class="mx-auto max-w-7xl px-6 py-4 md:flex md:items-center md:justify-between lg:px-8">
          <div class="mt-8 md:order-1 md:mt-0 flex items-center justify-center space-x-2">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <p class="text-center text-xs leading-5 text-gray-500 uppercase tracking-widest font-semibold">
              {{ t('footer.disclaimer') }}
            </p>
          </div>
        </div>
      </footer>
    </div>
  </div>
</template>

<style>
/* Global scrollbar styling for Dark Mode */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}
::-webkit-scrollbar-track {
  background: #0f0f14; 
}
::-webkit-scrollbar-thumb {
  background: #374151; 
  border-radius: 4px;
}
::-webkit-scrollbar-thumb:hover {
  background: #4b5563; 
}
</style>

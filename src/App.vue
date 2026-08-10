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
  <div class="min-h-screen bg-[var(--color-brand-bg)] flex flex-col relative">
    
    <!-- Mobile Sticky Header -->
    <div class="mobile-safe-header lg:hidden sticky top-0 z-40 flex flex-col border-b border-[var(--color-border-subtle)] bg-[var(--color-surface-1)]/95 backdrop-blur-md shadow-sm">
      <div class="flex h-16 shrink-0 items-center justify-between px-4">
        <div class="flex items-center gap-3">
          <!-- Geometric D Logo SVG -->
          <svg class="h-8 w-8 text-[#FFB224]" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M6 4H16C23.732 4 30 10.268 30 18C30 25.732 23.732 32 16 32H6V4Z" stroke="currentColor" stroke-width="3" stroke-linejoin="miter"/>
            <circle cx="16" cy="18" r="4" fill="currentColor"/>
            <line x1="16" y1="4" x2="16" y2="10" stroke="currentColor" stroke-width="2"/>
            <line x1="16" y1="26" x2="16" y2="32" stroke="currentColor" stroke-width="2"/>
          </svg>
          <span class="text-xl font-black tracking-tight text-[var(--color-text-primary)]">
            NumberD
          </span>
        </div>
        <button 
          type="button" 
          class="flex min-h-12 min-w-12 items-center justify-center rounded-sm text-[var(--color-text-secondary)] hover:text-white focus:outline-none focus:ring-1 focus:ring-inset focus:ring-[#FFB224]" 
          @click="isMobileMenuOpen = true"
          aria-label="Open sidebar"
        >
          <Menu class="h-6 w-6" aria-hidden="true" />
        </button>
      </div>
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
      'mobile-sidebar-shell fixed inset-y-0 left-0 z-50 flex w-72 max-w-[100vw] flex-col transition-transform duration-300 ease-in-out lg:translate-x-0',
      isMobileMenuOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full'
    ]">
      <div class="mobile-sidebar-panel flex grow flex-col gap-y-5 overflow-y-auto border-r border-[var(--color-border-subtle)] bg-[var(--color-surface-1)] px-6 pb-4">
        <div class="flex h-16 shrink-0 items-center justify-between mt-4">
          <div class="flex items-center gap-3">
            <!-- Geometric D Logo SVG -->
            <svg class="h-8 w-8 text-[#FFB224]" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M6 4H16C23.732 4 30 10.268 30 18C30 25.732 23.732 32 16 32H6V4Z" stroke="currentColor" stroke-width="3" stroke-linejoin="miter"/>
              <circle cx="16" cy="18" r="4" fill="currentColor"/>
              <line x1="16" y1="4" x2="16" y2="10" stroke="currentColor" stroke-width="2"/>
              <line x1="16" y1="26" x2="16" y2="32" stroke="currentColor" stroke-width="2"/>
            </svg>
            <span class="text-2xl font-black tracking-tight text-[var(--color-text-primary)]">
              NumberD
            </span>
          </div>
          <button 
            type="button" 
            class="lg:hidden flex min-h-12 min-w-12 items-center justify-center rounded-sm text-[var(--color-text-secondary)] hover:text-white" 
            @click="isMobileMenuOpen = false"
            aria-label="Close sidebar"
          >
            <X class="h-6 w-6" aria-hidden="true" />
          </button>
        </div>
        <nav class="flex flex-1 flex-col mt-6">
          <ul role="list" class="flex flex-1 flex-col gap-y-7">
            <li>
              <ul role="list" class="-mx-2 space-y-1">
                <li v-for="item in navigation" :key="item.nameKey">
                  <router-link
                    :to="item.href"
                    :class="[
                      route.path === item.href
                        ? 'bg-[var(--color-surface-2)] text-[#FFB224] border-l-2 border-[#FFB224]'
                        : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-surface-2)] border-l-2 border-transparent',
                      'group flex min-h-10 items-center gap-x-3 px-3 py-2 text-sm leading-6 font-mono transition-all duration-200 uppercase tracking-wide'
                    ]"
                  >
                    <component 
                      :is="item.icon" 
                      :class="[
                        route.path === item.href ? 'text-[#FFB224]' : 'text-[var(--color-text-tertiary)] group-hover:text-[var(--color-text-secondary)]',
                        'h-5 w-5 shrink-0 transition-colors duration-200'
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

        <div class="mt-auto pt-6 border-t border-[var(--color-border-subtle)]">
          <div class="flex items-center justify-between w-full bg-[var(--color-surface-2)] rounded-sm p-1 border border-[var(--color-border-subtle)]">
            <button 
              @click="setLanguage('en')"
              :class="[
                locale === 'en' ? 'bg-[#FFB224] text-black shadow-sm' : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-surface-3)]',
                'flex-1 min-h-9 py-1.5 text-xs font-mono font-bold rounded-sm transition-all duration-300'
              ]"
            >
              EN
            </button>
            <button 
              @click="setLanguage('zh-TW')"
              :class="[
                locale === 'zh-TW' ? 'bg-[#FFB224] text-black shadow-sm' : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-surface-3)]',
                'flex-1 min-h-9 py-1.5 text-xs font-mono font-bold rounded-sm transition-all duration-300'
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
      <main class="mobile-safe-main flex-grow">
        <router-view v-slot="{ Component }">
          <transition 
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="opacity-0 translate-y-2"
            enter-to-class="opacity-100 translate-y-0"
            leave-active-class="transition duration-200 ease-in"
            leave-from-class="opacity-100 translate-y-0"
            leave-to-class="opacity-0 -translate-y-2"
            mode="out-in"
          >
            <component :is="Component" />
          </transition>
        </router-view>
      </main>

      <footer class="mobile-safe-footer border-t border-[var(--color-border-subtle)] bg-[var(--color-surface-1)]/80 backdrop-blur-md mt-auto">
        <div class="mx-auto max-w-7xl px-6 py-4 md:flex md:items-center md:justify-between lg:px-8">
          <div class="flex items-center justify-center space-x-2 w-full md:w-auto md:order-1">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-[var(--color-text-tertiary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <p class="text-center text-xs leading-5 text-[var(--color-text-tertiary)] font-mono tracking-widest uppercase">
              {{ t('footer.disclaimer') }} | 台灣彩券官方數據
            </p>
          </div>
        </div>
      </footer>
    </div>
  </div>
</template>

<style>
@media (max-width: 1023px) {
  .mobile-safe-header {
    top: 0;
    padding-top: env(safe-area-inset-top, 0px);
    padding-left: env(safe-area-inset-left, 0px);
    padding-right: env(safe-area-inset-right, 0px);
  }

  .mobile-sidebar-shell {
    top: 0;
    bottom: 0;
    max-width: calc(100vw - env(safe-area-inset-left, 0px) - env(safe-area-inset-right, 0px));
  }

  .mobile-sidebar-panel {
    padding-top: env(safe-area-inset-top, 0px);
    padding-left: max(1.5rem, env(safe-area-inset-left, 0px));
    padding-right: max(1.5rem, env(safe-area-inset-right, 0px));
    padding-bottom: max(1rem, env(safe-area-inset-bottom, 0px));
  }

  .mobile-safe-main {
    padding-left: env(safe-area-inset-left, 0px);
    padding-right: env(safe-area-inset-right, 0px);
  }

  .mobile-safe-footer {
    padding-bottom: env(safe-area-inset-bottom, 0px);
  }
}
</style>

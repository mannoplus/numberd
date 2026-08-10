<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { formatLocalDate } from '../i18n'
import { fetchTaiwanLotteryApi, getRecentMonths } from '../lib/api'
import { getNextDrawDate, formatCountdown } from '../lib/countdown'

const gameTypes = ref([
  { 
    id: 'super_lotto_638', 
    name: 'Super Lotto 638', 
    pool: '1-38', 
    draws: 6, 
    hasSpecial: true,
    latestDraw: null as any
  },
  { 
    id: 'lotto_649', 
    name: 'Lotto 6/49', 
    pool: '1-49', 
    draws: 6, 
    hasSpecial: true,
    latestDraw: null as any
  },
  { 
    id: 'daily_cash_539', 
    name: 'Daily Cash 539', 
    pool: '1-39', 
    draws: 5, 
    hasSpecial: false,
    latestDraw: null as any
  }
])

const now = ref(new Date())
let timer: number
let pollTimer: number

const fetchData = async () => {
  const months = getRecentMonths(2)
  await Promise.all(gameTypes.value.map(async (game) => {
    const historical = await fetchTaiwanLotteryApi(game.id, months)
    if (historical && historical.length > 0) {
      game.latestDraw = {
        date: historical[0].draw_date,
        numbers: historical[0].numbers,
        special: historical[0].special_number
      }
    }
  }))
}

onMounted(() => {
  // Initial fetch
  fetchData()

  // Timer for 9 PM countdown
  timer = setInterval(() => {
    now.value = new Date()
  }, 1000)

  // Auto-refresh data daily at 9 PM
  const scheduleRefresh = () => {
    const nowLocal = new Date()
    const target = new Date(nowLocal)
    target.setHours(21, 0, 0, 0)
    if (nowLocal.getTime() >= target.getTime()) {
      target.setDate(target.getDate() + 1)
    }
    const delay = target.getTime() - nowLocal.getTime()
    pollTimer = window.setTimeout(() => {
      fetchData().finally(() => {
        scheduleRefresh()
      })
    }, delay)
  }
  scheduleRefresh()
})

onUnmounted(() => {
  clearInterval(timer)
  clearTimeout(pollTimer)
})

const getGameCountdown = (gameId: string) => {
  try {
    const nextDraw = getNextDrawDate(gameId, now.value)
    const diff = nextDraw.getTime() - now.value.getTime()
    return formatCountdown(diff)
  } catch (e) {
    console.error(e)
    return '00:00:00'
  }
}
</script>

<template>
  <div class="px-4 sm:px-6 py-6 sm:py-8 max-w-7xl mx-auto space-y-10">
    <header class="space-y-2">
      <h1 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-[var(--color-text-primary)]">{{ $t('dashboard.title') }}</h1>
      <p class="text-[var(--color-text-secondary)] font-mono text-sm uppercase">{{ $t('dashboard.subtitle') }}</p>
    </header>

    <!-- Games Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="game in gameTypes" :key="game.id" class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] overflow-hidden hover:border-[#FFB224]/50 transition-colors duration-300 relative group">
        <div class="absolute inset-x-0 top-0 h-0.5 bg-[#FFB224] opacity-50 group-hover:opacity-100 transition-opacity"></div>
        <div class="p-6">
          <div class="flex justify-between items-start mb-4">
            <h2 class="text-xl font-bold text-[var(--color-text-primary)]">{{ $t('games.' + game.id) }}</h2>
            <span class="inline-flex items-center px-2 py-0.5 rounded-sm text-xs font-mono font-medium bg-[#FFB224]/10 text-[#FFB224] border border-[#FFB224]/20 uppercase">
              {{ $t('common.live') }}
            </span>
          </div>
          
          <div class="space-y-4">
            <div class="flex justify-between text-sm font-mono border-b border-[var(--color-border-subtle)] pb-2">
              <span class="text-[var(--color-text-tertiary)] uppercase">{{ $t('dashboard.number_pool') }}</span>
              <span class="text-[var(--color-text-primary)]">{{ game.pool }}</span>
            </div>
            <div class="flex justify-between text-sm font-mono border-b border-[var(--color-border-subtle)] pb-2">
              <span class="text-[var(--color-text-tertiary)] uppercase">{{ $t('dashboard.draw_count') }}</span>
              <span class="text-[var(--color-text-primary)]">{{ game.draws }} <span v-if="game.hasSpecial">{{ $t('dashboard.plus_special') }}</span></span>
            </div>
            
            <div class="pt-4">
              <p class="text-xs text-[var(--color-text-tertiary)] mb-2 uppercase tracking-wide font-mono">{{ $t('dashboard.next_draw_countdown') }}</p>
              <div class="text-2xl font-mono text-[#FFB224]">
                {{ getGameCountdown(game.id) }}
              </div>
            </div>
          </div>
        </div>
        
        <div class="bg-[var(--color-surface-2)] p-4 border-t border-[var(--color-border-subtle)] group-hover:bg-[var(--color-accent-glow)]/10 transition-colors min-h-[100px]">
          <div v-if="game.latestDraw">
            <div class="flex justify-between items-center mb-4">
              <span class="text-sm text-[var(--color-text-secondary)] font-mono uppercase">{{ $t('dashboard.latest_draw') }} <span class="text-[var(--color-text-tertiary)] text-xs ml-1">{{ formatLocalDate(game.latestDraw.date, $i18n.locale) }}</span></span>
              <router-link to="/analysis" class="inline-flex min-h-8 items-center rounded-sm px-2 text-xs font-mono font-bold text-[#FFB224] transition-colors hover:bg-white/5 uppercase border border-transparent hover:border-[#FFB224]/30">
                {{ $t('dashboard.view_analysis') }} &rarr;
              </router-link>
            </div>
            <div class="flex flex-wrap gap-2">
              <div 
                v-for="num in game.latestDraw.numbers" 
                :key="num"
                class="w-9 h-9 rounded-sm bg-[var(--color-surface-3)] border border-[var(--color-border-subtle)] flex items-center justify-center text-sm font-mono font-bold text-[var(--color-text-primary)]"
              >
                {{ String(num).padStart(2, '0') }}
              </div>
              <div 
                v-if="game.hasSpecial && game.latestDraw.special"
                class="w-9 h-9 rounded-sm border flex items-center justify-center text-sm font-mono font-bold shadow-[0_0_10px_var(--color-accent-glow)] bg-[#FFB224]/10 border-[#FFB224]/50 text-[#FFB224]"
              >
                {{ String(game.latestDraw.special).padStart(2, '0') }}
              </div>
            </div>
          </div>
          <div v-else class="flex h-full items-center justify-center">
            <span class="text-[var(--color-text-tertiary)] text-sm font-mono uppercase animate-pulse">{{ $t('dashboard.fetching_live') }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- YouTube Live Stream Embed -->
    <div class="space-y-4 pt-6">
      <div class="flex flex-wrap items-center gap-3">
        <div class="bg-[var(--color-hot)]/10 text-[var(--color-hot)] text-xs font-mono font-bold px-3 py-1.5 rounded-sm flex items-center gap-2 border border-[var(--color-hot)]/30 w-max tracking-widest uppercase">
          <div class="w-2 h-2 bg-[var(--color-hot)] rounded-full animate-pulse shadow-[0_0_8px_var(--color-hot)]"></div>
          {{ $t('dashboard.live_event') }}
        </div>
        <h2 class="text-xl font-bold text-[var(--color-text-primary)] tracking-tight">{{ $t('dashboard.official_broadcast') }}</h2>
      </div>

      <div class="w-full relative rounded-2xl overflow-hidden border border-[var(--color-border-subtle)] bg-[var(--color-surface-1)] shadow-[0_10px_40px_-10px_rgba(0,0,0,0.5)] p-4 sm:p-6 transition-all duration-300 hover:border-[#FFB224]/30 hover:shadow-[0_10px_40px_-10px_rgba(255,178,36,0.15)]">
        <div class="absolute inset-0 bg-gradient-to-br from-[#FFB224]/5 to-transparent pointer-events-none opacity-50"></div>
        <div class="aspect-video w-full rounded-xl overflow-hidden border border-[#000000] shadow-inner relative z-10 bg-black">
          <iframe 
            class="w-full h-full" 
            src="https://www.youtube.com/embed/pF507BLtbqU?si=7yZtnBx6UDiIXuve&vq=hd1080&autoplay=1&mute=1&fs=1&playsinline=1" 
            title="YouTube video player" 
            frameborder="0" 
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen" 
            referrerpolicy="strict-origin-when-cross-origin" 
            allowfullscreen
            webkitallowfullscreen
            mozallowfullscreen>
          </iframe>
        </div>
      </div>
    </div>
  </div>
</template>

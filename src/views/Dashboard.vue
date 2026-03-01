<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { formatLocalDate } from '../i18n'
import { fetchTaiwanLotteryApi, getRecentMonths } from '../lib/api'

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

  // Auto-refresh data every 60 seconds
  pollTimer = setInterval(fetchData, 60000)
})

onUnmounted(() => {
  clearInterval(timer)
  clearInterval(pollTimer)
})

const getCountdownTo9PM = () => {
  const target = new Date(now.value)
  target.setHours(21, 0, 0, 0)
  
  // If we passed 9 PM, next target is tomorrow 9 PM
  if (now.value.getTime() > target.getTime()) {
    target.setDate(target.getDate() + 1)
  }
  
  const diff = target.getTime() - now.value.getTime()
  const h = Math.floor((diff / (1000 * 60 * 60)) % 24)
  const m = Math.floor((diff / 1000 / 60) % 60)
  const s = Math.floor((diff / 1000) % 60)
  
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}
</script>

<template>
  <div class="px-4 py-8 max-w-7xl mx-auto space-y-8">
    <header class="space-y-2">
      <h1 class="text-4xl font-extrabold tracking-tight text-white">{{ $t('dashboard.title') }}</h1>
      <p class="text-gray-400">{{ $t('dashboard.subtitle') }}</p>
    </header>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="game in gameTypes" :key="game.id" class="bg-[#1a1a24] rounded-2xl border border-gray-800 overflow-hidden hover:border-violet-500/50 transition-colors duration-300 relative group">
        <div class="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-violet-600 to-fuchsia-500 opacity-75"></div>
        <div class="p-6">
          <div class="flex justify-between items-start mb-4">
            <h2 class="text-xl font-bold text-white">{{ $t('games.' + game.id) }}</h2>
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-violet-600/20 text-violet-400">
              {{ $t('common.live') }}
            </span>
          </div>
          
          <div class="space-y-4">
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">{{ $t('dashboard.number_pool') }}</span>
              <span class="text-white font-medium">{{ game.pool }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">{{ $t('dashboard.draw_count') }}</span>
              <span class="text-white font-medium">{{ game.draws }} <span v-if="game.hasSpecial">{{ $t('dashboard.plus_special') }}</span></span>
            </div>
            
            <div class="pt-4 mt-4 border-t border-gray-800">
              <p class="text-xs text-gray-500 mb-2 uppercase tracking-wide font-semibold">{{ $t('dashboard.next_draw_countdown') }}</p>
              <div class="text-2xl font-mono text-fuchsia-400">
                {{ getCountdownTo9PM() }}
              </div>
            </div>
          </div>
        </div>
        
        <div class="bg-black/20 p-4 border-t border-gray-800 group-hover:bg-violet-900/10 transition-colors min-h-[100px]">
          <div v-if="game.latestDraw">
            <div class="flex justify-between items-center mb-3">
              <span class="text-sm text-gray-400">{{ $t('dashboard.latest_draw') }} <span class="text-gray-500 text-xs">({{ formatLocalDate(game.latestDraw.date, $i18n.locale) }})</span></span>
              <router-link to="/analysis" class="text-xs text-fuchsia-400 hover:text-fuchsia-300 font-medium transition-colors">
                {{ $t('dashboard.view_analysis') }} &rarr;
              </router-link>
            </div>
            <div class="flex flex-wrap gap-2">
              <div 
                v-for="num in game.latestDraw.numbers" 
                :key="num"
                class="w-8 h-8 rounded-full bg-[#2a2a35] border border-gray-700 flex items-center justify-center text-sm font-bold shadow-inner text-gray-200"
              >
                {{ String(num).padStart(2, '0') }}
              </div>
              <div 
                v-if="game.hasSpecial && game.latestDraw.special"
                class="w-8 h-8 rounded-full border flex items-center justify-center text-sm font-bold shadow-[0_0_10px_rgba(217,70,239,0.3)] bg-gradient-to-br from-fuchsia-600 to-violet-700 border-fuchsia-500 text-white"
              >
                {{ String(game.latestDraw.special).padStart(2, '0') }}
              </div>
            </div>
          </div>
          <div v-else class="flex h-full items-center justify-center">
            <span class="text-gray-600 text-sm animate-pulse">{{ $t('dashboard.fetching_live') }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- YouTube Live Stream Embed -->
    <div class="space-y-4">
      <div class="flex items-center gap-3">
        <div class="bg-red-600/90 backdrop-blur-sm text-white text-xs font-bold px-3 py-1.5 rounded-full flex items-center gap-2 shadow-[0_0_15px_rgba(220,38,38,0.5)] border border-red-500/50 w-max">
          <div class="w-2 h-2 bg-white rounded-full animate-pulse"></div>
          {{ $t('dashboard.live_event') }}
        </div>
        <h2 class="text-xl font-bold text-white tracking-tight">{{ $t('dashboard.official_broadcast') }}</h2>
      </div>

      <div class="w-full relative rounded-2xl overflow-hidden border border-gray-800 shadow-2xl bg-[#1a1a24] group">
        <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent pointer-events-none z-10 transition-opacity duration-300 group-hover:opacity-0"></div>
        <div class="aspect-video w-full">
          <iframe 
            class="w-full h-full" 
            src="https://www.youtube.com/embed/pF507BLtbqU?si=7yZtnBx6UDiIXuve&vq=hd1080&autoplay=1&mute=1" 
            title="YouTube video player" 
            frameborder="0" 
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
            referrerpolicy="strict-origin-when-cross-origin" 
            allowfullscreen>
          </iframe>
        </div>
      </div>
    </div>
  </div>
</template>

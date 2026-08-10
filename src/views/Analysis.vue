<script setup lang="ts">
import { ref, onMounted, computed, watch, onUnmounted } from 'vue'
import { fetchTaiwanLotteryApi, getRecentMonths } from '../lib/api'
import { Bar } from 'vue-chartjs'
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js'

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale)

const games = [
  { id: 'super_lotto_638', name: 'Super Lotto 638', pool: 38 },
  { id: 'lotto_649', name: 'Lotto 6/49', pool: 49 },
  { id: 'daily_cash_539', name: 'Daily Cash 539', pool: 39 }
]

const selectedGame = ref(games[0]!.id)
const isLoading = ref(false)
const draws = ref<any[]>([])
const analysisData = ref<any[]>([])
let pollTimer: number | undefined

const fetchDraws = async () => {
  isLoading.value = true
  
  try {
    const months = getRecentMonths(6) // Fetch 6 months of data ~ 50-150 draws
    const data = await fetchTaiwanLotteryApi(selectedGame.value, months)
    
    draws.value = data || []
    
    calculateStats()
  } catch (error) {
    console.error('Error fetching data:', error)
  } finally {
    isLoading.value = false
  }
}

const calculateStats = () => {
  const game = games.find(g => g.id === selectedGame.value)
  if (!game) return

  const poolSize = game.pool
  
  // Initialize stats per number
  const statsMap = new Map()
  for (let i = 1; i <= poolSize; i++) {
    statsMap.set(i, { number: i, count: 0, lastSeen: -1, gap: 0 })
  }
  
  // Tally frequencies and calculate gaps
  // Data is sorted descending (latest first)
  draws.value.forEach((draw, index) => {
    draw.numbers.forEach((num: number) => {
      const st = statsMap.get(num)
      if (st) {
        st.count += 1
        if (st.lastSeen === -1) {
          st.lastSeen = index
          st.gap = index // Gap in draws from the most recent
        }
      }
    })
  })
  
  // Set gap for numbers not drawn
  statsMap.forEach((st) => {
    if (st.lastSeen === -1) st.gap = draws.value.length
  })
  
  analysisData.value = Array.from(statsMap.values()).sort((a, b) => b.count - a.count)
}

watch(selectedGame, () => {
  fetchDraws()
})

onMounted(() => {
  fetchDraws()
  const scheduleRefresh = () => {
    const nowLocal = new Date()
    const target = new Date(nowLocal)
    target.setHours(21, 0, 0, 0)
    if (nowLocal.getTime() >= target.getTime()) {
      target.setDate(target.getDate() + 1)
    }
    const delay = target.getTime() - nowLocal.getTime()
    pollTimer = window.setTimeout(() => {
      // Only refresh silently in the background
      const prevIsLoading = isLoading.value
      isLoading.value = false
      fetchDraws().finally(() => { 
        isLoading.value = prevIsLoading
        scheduleRefresh()
      })
    }, delay)
  }
  scheduleRefresh()
})

onUnmounted(() => {
  if (pollTimer) clearTimeout(pollTimer)
})

const chartData = computed(() => {
  const sorted = [...analysisData.value].sort((a,b) => a.number - b.number)
  return {
    labels: sorted.map(d => d.number),
    datasets: [
      {
        label: 'Draw Frequency',
        backgroundColor: '#FFB224',
        data: sorted.map(d => d.count),
        borderRadius: 2
      }
    ]
  }
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  scales: {
    y: {
      beginAtZero: true,
      grid: { color: 'rgba(255,255,255,0.05)' },
      ticks: { color: '#9ca3af', font: { family: "'JetBrains Mono', monospace" } }
    },
    x: {
      grid: { display: false },
      ticks: { color: '#9ca3af', font: { family: "'JetBrains Mono', monospace" } }
    }
  },
  plugins: {
    legend: { labels: { color: '#fff', font: { family: "'Inter', sans-serif" } } }
  }
}

// Stats computed properties
const hotNumbers = computed(() => analysisData.value.slice(0, 5))
const coldNumbers = computed(() => [...analysisData.value].sort((a,b) => a.count - b.count).slice(0, 5))
const maxGap = computed(() => [...analysisData.value].sort((a,b) => b.gap - a.gap).slice(0, 5))
</script>

<template>
  <div class="px-4 sm:px-6 py-6 sm:py-8 max-w-7xl mx-auto space-y-8 pb-32">
    <header class="space-y-4">
      <div>
        <h1 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-[var(--color-text-primary)] mb-2">{{ $t('analysis.title') }}</h1>
        <p class="text-[var(--color-text-secondary)] font-mono text-sm uppercase tracking-wide">{{ $t('analysis.subtitle') }}</p>
      </div>

      <div class="flex w-full flex-wrap items-center gap-2 rounded-sm border border-[var(--color-border-subtle)] bg-[var(--color-surface-1)] p-2 sm:w-auto sm:gap-4">
        <button 
          v-for="game in games" 
          :key="game.id"
          @click="selectedGame = game.id"
          :class="[
            selectedGame === game.id 
              ? 'bg-[#FFB224] text-black shadow-sm font-bold' 
              : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-surface-2)]',
            'min-h-11 flex-1 px-3 py-2.5 text-sm font-mono uppercase tracking-wide rounded-sm transition-all duration-300 sm:flex-none sm:px-6 border border-transparent'
          ]"
        >
          {{ $t('games.' + game.id) }}
        </button>
      </div>
    </header>

    <div v-if="isLoading" class="flex items-center justify-center p-20">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-[#FFB224]"></div>
    </div>

    <div v-else-if="draws.length === 0" class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] p-8 text-center text-[var(--color-text-secondary)] font-mono uppercase">
      {{ $t('analysis.no_data') }}
    </div>

    <div v-else class="space-y-8 animate-[fadeIn_0.5s_ease-out]">
      <!-- Summary Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-[var(--color-surface-1)] border border-[var(--color-border-subtle)] rounded-sm p-6 relative overflow-hidden group">
          <div class="absolute inset-x-0 top-0 h-0.5 bg-[var(--color-hot)]"></div>
          <h3 class="text-sm font-mono font-semibold text-[var(--color-hot)] uppercase tracking-widest mb-4">{{ $t('analysis.hot_numbers') }}</h3>
          <div class="flex flex-wrap gap-2">
            <div v-for="st in hotNumbers" :key="st.number" class="flex flex-col items-center">
              <div class="w-11 h-11 rounded-sm bg-[var(--color-surface-2)] border border-[var(--color-hot)]/30 flex items-center justify-center font-mono font-bold text-[var(--color-text-primary)] shadow-[inset_0_0_8px_rgba(255,107,107,0.1)]">
                {{ String(st.number).padStart(2, '0') }}
              </div>
              <span class="text-xs text-[var(--color-text-tertiary)] mt-2 font-mono uppercase tracking-wider">{{ st.count }}{{ $t('analysis.times') }}</span>
            </div>
          </div>
        </div>

        <div class="bg-[var(--color-surface-1)] border border-[var(--color-border-subtle)] rounded-sm p-6 relative overflow-hidden group">
          <div class="absolute inset-x-0 top-0 h-0.5 bg-[var(--color-cold)]"></div>
          <h3 class="text-sm font-mono font-semibold text-[var(--color-cold)] uppercase tracking-widest mb-4">{{ $t('analysis.cold_numbers') }}</h3>
          <div class="flex flex-wrap gap-2">
            <div v-for="st in coldNumbers" :key="st.number" class="flex flex-col items-center">
              <div class="w-11 h-11 rounded-sm bg-[var(--color-surface-2)] border border-[var(--color-cold)]/30 flex items-center justify-center font-mono font-bold text-[var(--color-text-primary)] shadow-[inset_0_0_8px_rgba(77,171,247,0.1)]">
                {{ String(st.number).padStart(2, '0') }}
              </div>
              <span class="text-xs text-[var(--color-text-tertiary)] mt-2 font-mono uppercase tracking-wider">{{ st.count }}{{ $t('analysis.times') }}</span>
            </div>
          </div>
        </div>

        <div class="bg-[var(--color-surface-1)] border border-[var(--color-border-subtle)] rounded-sm p-6 relative overflow-hidden group">
          <div class="absolute inset-x-0 top-0 h-0.5 bg-[#FFB224]"></div>
          <h3 class="text-sm font-mono font-semibold text-[#FFB224] uppercase tracking-widest mb-4">{{ $t('analysis.overdue') }}</h3>
          <div class="flex flex-wrap gap-2">
            <div v-for="st in maxGap" :key="st.number" class="flex flex-col items-center">
              <div class="w-11 h-11 rounded-sm bg-[var(--color-surface-2)] border border-[#FFB224]/30 flex items-center justify-center font-mono font-bold text-[var(--color-text-primary)] shadow-[inset_0_0_8px_rgba(255,178,36,0.1)]">
                {{ String(st.number).padStart(2, '0') }}
              </div>
              <span class="text-xs text-[#FFB224]/80 mt-2 font-mono uppercase tracking-wider">{{ st.gap }}{{ $t('analysis.days_ago') }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Chart View -->
      <div class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] p-6 shadow-xl">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-xl font-bold text-[var(--color-text-primary)]">{{ $t('analysis.frequency_dist') }}</h2>
          <span class="text-sm text-[var(--color-text-secondary)] font-mono uppercase tracking-wide">{{ $t('analysis.based_on', { count: draws.length }) }}</span>
        </div>
        <div class="h-80 w-full relative">
          <Bar :data="chartData" :options="chartOptions" />
        </div>
      </div>
      
    </div>
  </div>
</template>

<style>
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>

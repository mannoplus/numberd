<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted } from 'vue'
import { fetchTaiwanLotteryApi, getRecentMonths } from '../lib/api'
import { Layers, Activity, Zap, RefreshCw } from 'lucide-vue-next'

const games = [
  { id: 'super_lotto_638', name: 'Super Lotto 638', pool: 38, count: 6, hasSpecial: true, specialPool: 8 },
  { id: 'lotto_649', name: 'Lotto 6/49', pool: 49, count: 6, hasSpecial: true, specialPool: 49 },
  { id: 'daily_cash_539', name: 'Daily Cash 539', pool: 39, count: 5, hasSpecial: false, specialPool: 0 }
]

const selectedGame = ref(games[0]!.id)
const isLoading = ref(true)
const isGenerating = ref(false)
const history = ref<any[]>([])
let pollTimer: number | undefined

// State for predictions
const predictions = ref<{
  alpha: { numbers: number[], special: number | null, justificationKey: string, riskKey: string, params?: any },
  beta: { numbers: number[], special: number | null, justificationKey: string, riskKey: string, params?: any },
  gamma: { numbers: number[], special: number | null, justificationKey: string, riskKey: string, params?: any }
} | null>(null)

const fetchAndGenerate = async () => {
  isLoading.value = true
  try {
    const months = getRecentMonths(6)
    const data = await fetchTaiwanLotteryApi(selectedGame.value, months)
    history.value = data || []
    generatePredictions()
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

// Fisher-Yates shuffle to pick N random distinct elements
const pickRandom = (arr: number[], n: number) => {
  const shuffled = [...arr].sort(() => 0.5 - Math.random())
  return shuffled.slice(0, n).sort((a,b) => a - b)
}

const generatePredictions = () => {
  isGenerating.value = true
  const game = games.find(g => g.id === selectedGame.value)
  if (!game || history.value.length === 0) return

  setTimeout(() => {
    // 1. Analyze History
    const pool = game.pool
    const count = game.count
    
    const counts = new Map<number, number>()
    for (let i = 1; i <= pool; i++) counts.set(i, 0)

    history.value.forEach(draw => {
      draw.numbers.forEach((num: number) => {
        counts.set(num, (counts.get(num) || 0) + 1)
      })
    })

    const sortedFreq = Array.from(counts.entries()).sort((a, b) => b[1] - a[1])
    const top20Percent = Math.max(1, Math.floor(pool * 0.2))
    
    // Arrays of numbers
    const hot = sortedFreq.slice(0, top20Percent).map(x => x[0])
    const cold = sortedFreq.slice(-top20Percent).map(x => x[0])
    const fullPool = Array.from({ length: pool }, (_, i) => i + 1)
    
    // Middle 50% array
    const midStart = Math.floor(pool * 0.25)
    const midEnd = Math.floor(pool * 0.75)
    const midRange = fullPool.filter(x => x >= midStart && x <= midEnd)

    // Calculate Special Number if needed
    const getSpecial = () => {
      if (!game.hasSpecial) return null
      return Math.floor(Math.random() * game.specialPool) + 1
    }

    // 2. Generate Trios
    // Alpha: Balanced (Mid-range)
    let alphaNums = pickRandom(midRange, count)
    if (alphaNums.length < count) alphaNums = pickRandom(fullPool, count)

    // Beta: Momentum (Hot)
    let betaNums = pickRandom(hot, count)
    if (betaNums.length < count) {
      const remaining = pickRandom(fullPool.filter(n => !betaNums.includes(n)), count - betaNums.length)
      betaNums = [...betaNums, ...remaining].sort((a,b) => a - b)
    }

    // Gamma: Chaos (Cold)
    let gammaNums = pickRandom(cold, count)
    if (gammaNums.length < count) {
       const remaining = pickRandom(fullPool.filter(n => !gammaNums.includes(n)), count - gammaNums.length)
       gammaNums = [...gammaNums, ...remaining].sort((a,b) => a - b)
    }

    const expectedMean = (pool + 1) / 2

    predictions.value = {
      alpha: {
        numbers: alphaNums,
        special: getSpecial(),
        justificationKey: 'predictions.alpha_justification',
        riskKey: 'predictions.alpha_risk',
        params: { mean: expectedMean.toFixed(2) }
      },
      beta: {
        numbers: betaNums,
        special: getSpecial(),
        justificationKey: 'predictions.beta_justification',
        riskKey: 'predictions.beta_risk',
        params: { history: history.value.length }
      },
      gamma: {
        numbers: gammaNums,
        special: getSpecial(),
        justificationKey: 'predictions.gamma_justification',
        riskKey: 'predictions.gamma_risk'
      }
    }
    isGenerating.value = false
  }, 600) // Synthetic delay for UI feel
}

watch(selectedGame, () => {
  fetchAndGenerate()
})

onMounted(() => {
  fetchAndGenerate()
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
      fetchAndGenerate().finally(() => { 
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
</script>

<template>
  <div class="px-4 py-8 max-w-7xl mx-auto space-y-8 pb-32">
    <header class="space-y-4">
      <div>
        <h1 class="text-4xl font-extrabold tracking-tight text-white mb-2">{{ $t('predictions.title') }}</h1>
        <p class="text-gray-400">{{ $t('predictions.subtitle') }}</p>
      </div>

      <div class="flex flex-wrap items-center gap-4 bg-[#1a1a24] p-2 rounded-xl border border-gray-800 w-max">
        <button 
          v-for="game in games" 
          :key="game.id"
          @click="selectedGame = game.id"
          :class="[
            selectedGame === game.id 
              ? 'bg-gradient-to-r from-violet-600 to-fuchsia-500 text-white shadow-lg' 
              : 'text-gray-400 hover:text-white hover:bg-white/5',
            'px-6 py-2 rounded-lg font-medium transition-all duration-300'
          ]"
        >
          {{ $t('games.' + game.id) }}
        </button>
      </div>
    </header>

    <div v-if="isLoading" class="flex items-center justify-center p-20">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-fuchsia-500"></div>
    </div>
    
    <div v-else-if="history.length === 0" class="bg-[#1a1a24] rounded-2xl border border-gray-800 p-8 text-center text-gray-400">
      {{ $t('predictions.no_data') }}
    </div>

    <div v-else class="space-y-8">
      <div class="flex justify-end">
        <button 
          @click="generatePredictions" 
          :disabled="isGenerating"
          class="flex items-center gap-2 bg-white/5 hover:bg-white/10 text-white px-4 py-2 rounded-lg transition-colors border border-gray-700 disabled:opacity-50"
        >
          <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': isGenerating }" />
          {{ $t('predictions.run_monte_carlo') }}
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6" :class="{ 'opacity-50 transition-opacity': isGenerating }">
        
        <!-- Alpha Card -->
        <div class="bg-[#1a1a24] rounded-2xl border border-gray-800 p-8 relative overflow-hidden group hover:border-violet-500/50 transition-all duration-300">
          <div class="absolute inset-0 bg-gradient-to-b from-blue-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
          <div class="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-blue-600 to-violet-500"></div>
          
          <div class="relative">
             <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-blue-500/20 flex items-center justify-center text-blue-400">
                  <Layers class="w-5 h-5" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-white">{{ $t('predictions.alpha') }}</h3>
                  <span class="text-xs font-semibold text-blue-400 uppercase tracking-wider">{{ $t('predictions.alpha_tag') }}</span>
                </div>
             </div>

             <div v-if="predictions?.alpha" class="space-y-6">
                <div class="flex flex-wrap gap-2">
                  <div v-for="num in predictions.alpha.numbers" :key="num" class="w-10 h-10 flex items-center justify-center rounded-full bg-black/40 border border-gray-700 text-white font-bold shadow-inner">
                    {{ String(num).padStart(2, '0') }}
                  </div>
                  <div v-if="predictions.alpha.special" class="w-10 h-10 flex items-center justify-center rounded-full bg-blue-900/40 border-2 border-blue-500 text-blue-100 font-bold shadow-[0_0_15px_rgba(59,130,246,0.3)]">
                    {{ String(predictions.alpha.special).padStart(2, '0') }}
                  </div>
                </div>

                <div class="space-y-4 pt-4 border-t border-gray-800/50">
                   <div>
                     <p class="text-xs text-gray-500 uppercase font-bold mb-1">{{ $t('predictions.math_engine') }}</p>
                     <p class="text-sm text-gray-300 leading-relaxed">{{ $t(predictions.alpha.justificationKey, predictions.alpha.params || {}) }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-gray-500 uppercase font-bold mb-1">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-medium text-blue-400">{{ $t(predictions.alpha.riskKey) }}</p>
                   </div>
                </div>
             </div>
          </div>
        </div>

        <!-- Beta Card -->
        <div class="bg-[#1a1a24] rounded-2xl border border-gray-800 p-8 relative overflow-hidden group hover:border-red-500/50 transition-all duration-300 scale-100 lg:scale-105 z-10 shadow-2xl">
          <div class="absolute inset-0 bg-gradient-to-b from-red-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
          <div class="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-red-600 to-orange-500"></div>
          
          <div class="relative">
             <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-red-500/20 flex items-center justify-center text-red-400">
                  <Activity class="w-5 h-5" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-white">{{ $t('predictions.beta') }}</h3>
                  <span class="text-xs font-semibold text-red-400 flex items-center gap-1 uppercase tracking-wider">{{ $t('predictions.beta_tag') }}</span>
                </div>
             </div>

             <div v-if="predictions?.beta" class="space-y-6">
                <div class="flex flex-wrap gap-2">
                  <div v-for="num in predictions.beta.numbers" :key="num" class="w-10 h-10 flex items-center justify-center rounded-full bg-black/40 border border-gray-700 text-white font-bold shadow-inner">
                    {{ String(num).padStart(2, '0') }}
                  </div>
                  <div v-if="predictions.beta.special" class="w-10 h-10 flex items-center justify-center rounded-full bg-red-900/40 border-2 border-red-500 text-red-100 font-bold shadow-[0_0_15px_rgba(239,68,68,0.3)]">
                    {{ String(predictions.beta.special).padStart(2, '0') }}
                  </div>
                </div>

                <div class="space-y-4 pt-4 border-t border-gray-800/50">
                   <div>
                     <p class="text-xs text-gray-500 uppercase font-bold mb-1">{{ $t('predictions.math_engine') }}</p>
                     <p class="text-sm text-gray-300 leading-relaxed">{{ $t(predictions.beta.justificationKey, predictions.beta.params || {}) }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-gray-500 uppercase font-bold mb-1">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-medium text-red-400">{{ $t(predictions.beta.riskKey) }}</p>
                   </div>
                </div>
             </div>
          </div>
        </div>

        <!-- Gamma Card -->
        <div class="bg-[#1a1a24] rounded-2xl border border-gray-800 p-8 relative overflow-hidden group hover:border-emerald-500/50 transition-all duration-300">
          <div class="absolute inset-0 bg-gradient-to-b from-emerald-500/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
          <div class="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-emerald-600 to-teal-500"></div>
          
          <div class="relative">
             <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 rounded-lg bg-emerald-500/20 flex items-center justify-center text-emerald-400">
                  <Zap class="w-5 h-5" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-white">{{ $t('predictions.gamma') }}</h3>
                  <span class="text-xs font-semibold text-emerald-400 uppercase tracking-wider">{{ $t('predictions.gamma_tag') }}</span>
                </div>
             </div>

             <div v-if="predictions?.gamma" class="space-y-6">
                <div class="flex flex-wrap gap-2">
                  <div v-for="num in predictions.gamma.numbers" :key="num" class="w-10 h-10 flex items-center justify-center rounded-full bg-black/40 border border-gray-700 text-white font-bold shadow-inner">
                    {{ String(num).padStart(2, '0') }}
                  </div>
                  <div v-if="predictions.gamma.special" class="w-10 h-10 flex items-center justify-center rounded-full bg-emerald-900/40 border-2 border-emerald-500 text-emerald-100 font-bold shadow-[0_0_15px_rgba(16,185,129,0.3)]">
                    {{ String(predictions.gamma.special).padStart(2, '0') }}
                  </div>
                </div>

                <div class="space-y-4 pt-4 border-t border-gray-800/50">
                   <div>
                     <p class="text-xs text-gray-500 uppercase font-bold mb-1">{{ $t('predictions.math_engine') }}</p>
                     <p class="text-sm text-gray-300 leading-relaxed">{{ $t(predictions.gamma.justificationKey, predictions.gamma.params || {}) }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-gray-500 uppercase font-bold mb-1">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-medium text-emerald-400">{{ $t(predictions.gamma.riskKey) }}</p>
                   </div>
                </div>
             </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

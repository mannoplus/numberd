<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted } from 'vue'
import { fetchTaiwanLotteryApi, getRecentMonths } from '../lib/api'
import { Layers, Activity, Zap, RefreshCw, Info } from 'lucide-vue-next'
import type { EngineResult } from '../lib/engine'
import PredictionWorker from '../lib/prediction.worker?worker'

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
const predictions = ref<EngineResult | null>(null)

const fetchAndGenerate = async () => {
  isLoading.value = true
  try {
    const months = getRecentMonths(12) // Ensure enough data for bi-weekly games to hit 50 draws
    const data = await fetchTaiwanLotteryApi(selectedGame.value, months)
    history.value = data || []
    generatePredictions()
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

// Utility removed to worker

const generatePredictions = () => {
  if (isGenerating.value) return
  isGenerating.value = true
  
  const game = games.find(g => g.id === selectedGame.value)
  if (!game || history.value.length === 0) {
    isGenerating.value = false
    return
  }

  // Use the Web Worker for the heavy math logic
  const worker = new PredictionWorker()
  
  worker.onmessage = (e) => {
    if (e.data.success) {
      predictions.value = e.data.result
    } else {
      console.error("Prediction Engine Error:", e.data.error)
    }
    isGenerating.value = false
    worker.terminate()
  }

  worker.onerror = (e) => {
    console.error("Web Worker Error:", e)
    isGenerating.value = false
    worker.terminate()
  }

  // Pass history and wait for results (at least 600ms delay for UI feel)
  const startTime = Date.now()
  
  setTimeout(() => {
    worker.postMessage({ gameId: game.id, draws: history.value })
  }, Math.max(0, 600 - (Date.now() - startTime)))
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
  <div class="px-4 sm:px-6 py-6 sm:py-8 max-w-7xl mx-auto space-y-8 pb-32">
    <header class="space-y-4">
      <div>
        <h1 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-[var(--color-text-primary)] mb-2">{{ $t('predictions.title') }}</h1>
        <p class="text-[var(--color-text-secondary)] font-mono text-sm uppercase tracking-wide">{{ $t('predictions.subtitle') }}</p>
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
    
    <div v-else-if="history.length === 0" class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] p-8 text-center text-[var(--color-text-secondary)] font-mono uppercase">
      {{ $t('predictions.no_data') }}
    </div>

    <div v-else class="space-y-8">
      <div class="flex justify-end">
        <button 
          @click="generatePredictions" 
          :disabled="isGenerating"
          class="flex min-h-11 items-center gap-2 rounded-sm border border-[var(--color-border-focus)] bg-[var(--color-surface-2)] px-4 py-2.5 text-[var(--color-text-primary)] font-mono text-sm uppercase tracking-wide transition-colors hover:bg-[var(--color-surface-3)] hover:border-[#FFB224]/50 hover:text-[#FFB224] disabled:opacity-50"
        >
          <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': isGenerating }" />
          {{ $t('predictions.run_monte_carlo') }}
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6" :class="{ 'opacity-50 transition-opacity': isGenerating }">
        
        <!-- Alpha Card -->
        <div class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] p-6 sm:p-8 relative overflow-hidden group hover:border-[#FFB224]/30 transition-all duration-300">
          <div class="absolute inset-0 bg-gradient-to-b from-[#FFB224]/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
          <div class="absolute top-0 inset-x-0 h-0.5 bg-[var(--color-border-subtle)] group-hover:bg-[#FFB224] transition-colors"></div>
          
          <div class="relative">
             <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 rounded-sm bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] flex items-center justify-center text-[var(--color-text-secondary)] group-hover:text-[#FFB224] transition-colors">
                  <Layers class="w-5 h-5" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-[var(--color-text-primary)] group-hover:text-[#FFB224] transition-colors">{{ $t('predictions.alpha') }}</h3>
                  <span class="text-xs font-mono font-semibold text-[var(--color-text-tertiary)] uppercase tracking-wider group-hover:text-[#FFB224]/70 transition-colors">{{ $t('predictions.alpha_tag') }}</span>
                </div>
             </div>

             <div v-if="predictions?.alpha" class="space-y-6">
                <div class="flex flex-wrap gap-2">
                  <div v-for="num in predictions.alpha.numbers" :key="num" class="w-10 h-10 flex items-center justify-center rounded-sm bg-[var(--color-surface-3)] border border-[var(--color-border-subtle)] text-[var(--color-text-primary)] font-mono font-bold">
                    {{ String(num).padStart(2, '0') }}
                  </div>
                  <div v-if="predictions.alpha.special" class="w-10 h-10 flex items-center justify-center rounded-sm bg-[var(--color-accent-glow)] border border-[#FFB224]/50 text-[#FFB224] font-mono font-bold shadow-[0_0_10px_var(--color-accent-glow)]">
                    {{ String(predictions.alpha.special).padStart(2, '0') }}
                  </div>
                </div>

                <div class="space-y-4 pt-4 border-t border-[var(--color-border-subtle)]">
                   <div>
                     <p class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide mb-2">{{ $t('predictions.math_engine') }}</p>
                     <p class="text-sm text-[var(--color-text-secondary)] leading-relaxed">{{ predictions.alpha.narrative || predictions.alpha.justification }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide mb-2">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-mono font-medium text-[var(--color-text-primary)]">{{ predictions.alpha.riskProfile }}</p>
                   </div>
                </div>
             </div>
          </div>
        </div>

        <!-- Beta Card -->
        <div class="bg-[var(--color-surface-1)] rounded-sm border border-[#FFB224]/30 p-6 sm:p-8 relative overflow-hidden group hover:border-[#FFB224]/80 transition-all duration-300 scale-100 lg:scale-105 z-10 shadow-2xl">
          <div class="absolute inset-0 bg-gradient-to-b from-[#FFB224]/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
          <div class="absolute top-0 inset-x-0 h-0.5 bg-[#FFB224]"></div>
          
          <div class="relative">
             <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 rounded-sm bg-[#FFB224]/10 border border-[#FFB224]/30 flex items-center justify-center text-[#FFB224]">
                  <Activity class="w-5 h-5" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-[#FFB224]">{{ $t('predictions.beta') }}</h3>
                  <span class="text-xs font-mono font-semibold text-[#FFB224]/70 flex items-center gap-1 uppercase tracking-wider">{{ $t('predictions.beta_tag') }}</span>
                </div>
             </div>

             <div v-if="predictions?.beta" class="space-y-6">
                <div class="flex flex-wrap gap-2">
                  <div v-for="num in predictions.beta.numbers" :key="num" class="w-10 h-10 flex items-center justify-center rounded-sm bg-[var(--color-surface-3)] border border-[#FFB224]/30 text-[var(--color-text-primary)] font-mono font-bold">
                    {{ String(num).padStart(2, '0') }}
                  </div>
                  <div v-if="predictions.beta.special" class="w-10 h-10 flex items-center justify-center rounded-sm bg-[var(--color-accent-glow)] border border-[#FFB224]/80 text-[#FFB224] font-mono font-bold shadow-[0_0_15px_var(--color-accent-glow)]">
                    {{ String(predictions.beta.special).padStart(2, '0') }}
                  </div>
                </div>

                <div class="space-y-4 pt-4 border-t border-[var(--color-border-subtle)]">
                   <div>
                     <p class="text-xs text-[#FFB224]/60 uppercase font-mono tracking-wide mb-2">{{ $t('predictions.math_engine') }}</p>
                     <p class="text-sm text-[var(--color-text-primary)] leading-relaxed">{{ predictions.beta.narrative || predictions.beta.justification }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-[#FFB224]/60 uppercase font-mono tracking-wide mb-2">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-mono font-medium text-[#FFB224]">{{ predictions.beta.riskProfile }}</p>
                   </div>
                </div>
             </div>
          </div>
        </div>

        <!-- Gamma Card -->
        <div class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] p-6 sm:p-8 relative overflow-hidden group hover:border-[#FFB224]/30 transition-all duration-300">
          <div class="absolute inset-0 bg-gradient-to-b from-[#FFB224]/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
          <div class="absolute top-0 inset-x-0 h-0.5 bg-[var(--color-border-subtle)] group-hover:bg-[#FFB224] transition-colors"></div>
          
          <div class="relative">
             <div class="flex items-center gap-3 mb-6">
                <div class="w-10 h-10 rounded-sm bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] flex items-center justify-center text-[var(--color-text-secondary)] group-hover:text-[#FFB224] transition-colors">
                  <Zap class="w-5 h-5" />
                </div>
                <div>
                  <h3 class="text-xl font-bold text-[var(--color-text-primary)] group-hover:text-[#FFB224] transition-colors">{{ $t('predictions.gamma') }}</h3>
                  <span class="text-xs font-mono font-semibold text-[var(--color-text-tertiary)] uppercase tracking-wider group-hover:text-[#FFB224]/70 transition-colors">{{ $t('predictions.gamma_tag') }}</span>
                </div>
             </div>

             <div v-if="predictions?.gamma" class="space-y-6">
                <div class="flex flex-wrap gap-2">
                  <div v-for="num in predictions.gamma.numbers" :key="num" class="w-10 h-10 flex items-center justify-center rounded-sm bg-[var(--color-surface-3)] border border-[var(--color-border-subtle)] text-[var(--color-text-primary)] font-mono font-bold">
                    {{ String(num).padStart(2, '0') }}
                  </div>
                  <div v-if="predictions.gamma.special" class="w-10 h-10 flex items-center justify-center rounded-sm bg-[var(--color-accent-glow)] border border-[#FFB224]/50 text-[#FFB224] font-mono font-bold shadow-[0_0_10px_var(--color-accent-glow)]">
                    {{ String(predictions.gamma.special).padStart(2, '0') }}
                  </div>
                </div>

                <div class="space-y-4 pt-4 border-t border-[var(--color-border-subtle)]">
                   <div>
                     <p class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide mb-2">{{ $t('predictions.math_engine') }}</p>
                     <p class="text-sm text-[var(--color-text-secondary)] leading-relaxed">{{ predictions.gamma.narrative || predictions.gamma.justification }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide mb-2">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-mono font-medium text-[var(--color-text-primary)]">{{ predictions.gamma.riskProfile }}</p>
                   </div>
                </div>
             </div>
          </div>
        </div>

      </div>

      <!-- Metrics Breakdown & Disclaimer -->
      <div v-if="predictions?.metrics" class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] p-6 mt-8 flex flex-col md:flex-row gap-6 justify-between items-start md:items-center">
        <div class="flex flex-wrap gap-6">
           <div class="flex flex-col">
             <span class="text-[var(--color-text-tertiary)] text-xs font-mono uppercase tracking-widest mb-1">Target Mean Sum</span>
             <span class="text-[var(--color-text-primary)] font-mono text-xl">{{ predictions.metrics.targetSum }}</span>
           </div>
           <div class="flex flex-col">
             <span class="text-[var(--color-text-tertiary)] text-xs font-mono uppercase tracking-widest mb-1">Poisson Repeat %</span>
             <span class="text-[var(--color-text-primary)] font-mono text-xl">{{ predictions.metrics.repeatProbability.toFixed(1) }}%</span>
           </div>
           <div class="flex flex-col">
             <span class="text-[var(--color-text-tertiary)] text-xs font-mono uppercase tracking-widest mb-1">Hot / Cold Ratio</span>
             <span class="text-[var(--color-text-primary)] font-mono text-xl">{{ predictions.metrics.hotCount }} / {{ predictions.metrics.coldCount }}</span>
           </div>
        </div>
        <div class="flex items-start gap-3 max-w-sm text-[var(--color-text-secondary)]">
          <Info class="w-4 h-4 mt-0.5 shrink-0" />
          <p class="text-xs leading-relaxed">
            Lottery draws are independent random events. These predictions are generated purely for statistical reference and entertainment based on the last 50 draws (as of {{ history[0]?.draw_date }}). They do not guarantee any outcomes.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

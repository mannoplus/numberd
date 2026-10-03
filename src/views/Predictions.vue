<script setup lang="ts">
import { ref, watch, onUnmounted } from 'vue'
import { Layers, Activity, Zap, RefreshCw, Info, AlertCircle, X } from 'lucide-vue-next'
import type { GameId, EngineResult } from '../lib/engine'
import { getPredictions } from '../lib/predictionService'
import { readPredictionCache, writePredictionCache } from '../lib/predictionCache'

const games = [
  { id: 'super_lotto_638', name: 'Super Lotto 638', pool: 38, count: 6, hasSpecial: true, specialPool: 8 },
  { id: 'lotto_649', name: 'Lotto 6/49', pool: 49, count: 6, hasSpecial: true, specialPool: 49 },
  { id: 'daily_cash_539', name: 'Daily Cash 539', pool: 39, count: 5, hasSpecial: false, specialPool: 0 }
]

const selectedGame = ref<string>(games[0]!.id)
const isLoading = ref<boolean>(false)
const isGenerating = ref<boolean>(false)
const predictions = ref<EngineResult | null>(null)
const inFlightRequests = ref<Record<string, boolean>>({})
const errorMessage = ref<string | null>(null)
let errorTimeout: number | undefined

// Hydrate game from localStorage cache (no spinners, no API calls)
const hydrateGame = (gameId: string) => {
  errorMessage.value = null
  const cached = readPredictionCache(gameId)
  predictions.value = cached

  // Check if target game has an in-flight request pending
  const inFlight = !!inFlightRequests.value[gameId]
  isLoading.value = inFlight
  isGenerating.value = inFlight
}

// Initial synchronous hydration on page load
hydrateGame(selectedGame.value)

// Switching between game tabs: purely inspects localStorage, never triggers network requests
watch(selectedGame, (newGameId) => {
  hydrateGame(newGameId)
})

const onRunSimulation = async () => {
  const targetGameId = selectedGame.value
  if (inFlightRequests.value[targetGameId]) return

  inFlightRequests.value[targetGameId] = true
  isLoading.value = true
  isGenerating.value = true
  errorMessage.value = null

  try {
    const result = await getPredictions(targetGameId as GameId, [])
    if (!result) {
      throw new Error('Simulation failed to return results')
    }

    // Persist result into target game's cache key upon resolution
    writePredictionCache(targetGameId, result)

    // Only render results on the active view if the user is still on targetGameId
    if (selectedGame.value === targetGameId) {
      predictions.value = result
    }
  } catch (err: any) {
    console.error('[Predictions] Error generating predictions:', err)
    if (selectedGame.value === targetGameId) {
      errorMessage.value = err?.message || 'Simulation request failed. Please try again.'
      if (errorTimeout) clearTimeout(errorTimeout)
      errorTimeout = window.setTimeout(() => {
        errorMessage.value = null
      }, 5000)
    }
    // Preserves previously displayed cached data; does not clear localStorage keys
  } finally {
    inFlightRequests.value[targetGameId] = false
    if (selectedGame.value === targetGameId) {
      isLoading.value = false
      isGenerating.value = false
    }
  }
}

onUnmounted(() => {
  if (errorTimeout) clearTimeout(errorTimeout)
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

    <!-- Non-blocking Error Toast / Banner -->
    <div 
      v-if="errorMessage" 
      class="flex items-center justify-between p-4 bg-red-950/40 border border-red-500/50 rounded-sm text-red-200 text-sm font-mono"
    >
      <div class="flex items-center gap-3">
        <AlertCircle class="w-4 h-4 text-red-400 shrink-0" />
        <span>{{ errorMessage }}</span>
      </div>
      <button 
        @click="errorMessage = null" 
        class="text-red-400 hover:text-red-200 p-1 rounded transition-colors"
        aria-label="Dismiss error"
      >
        <X class="w-4 h-4" />
      </button>
    </div>

    <!-- Active Loading State (No previous predictions yet) -->
    <div v-if="!predictions && (isLoading || isGenerating)" class="flex flex-col items-center justify-center p-20 gap-4">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-[#FFB224]"></div>
      <p class="text-sm font-mono text-[var(--color-text-secondary)] uppercase tracking-wider">Generating predictions...</p>
    </div>

    <!-- Idle State: No Predictions Generated Yet -->
    <div 
      v-else-if="!predictions" 
      class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] p-12 text-center flex flex-col items-center justify-center gap-6"
    >
      <div class="space-y-2 max-w-md">
        <p class="text-[var(--color-text-secondary)] font-mono text-sm tracking-wide">
          {{ $t('predictions.idle_message') }}
        </p>
      </div>
      <button 
        @click="onRunSimulation" 
        :disabled="isGenerating || isLoading"
        class="flex min-h-11 items-center gap-2 rounded-sm border border-[var(--color-border-focus)] bg-[var(--color-surface-2)] px-6 py-2.5 text-[var(--color-text-primary)] font-mono text-sm uppercase tracking-wide transition-colors hover:bg-[var(--color-surface-3)] hover:border-[#FFB224]/50 hover:text-[#FFB224] disabled:opacity-50 shrink-0"
      >
        <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': isGenerating || isLoading }" />
        {{ $t('predictions.run_monte_carlo') }}
      </button>
    </div>

    <!-- Populated State: Display Predictions -->
    <div v-else class="space-y-8">
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div v-if="predictions?.summary" class="flex-1 text-sm font-mono text-[var(--color-text-secondary)] bg-[var(--color-surface-1)] border border-[var(--color-border-subtle)] px-4 py-2.5 rounded-sm flex items-center gap-3">
          <span class="w-2 h-2 rounded-full bg-[#FFB224] animate-pulse shrink-0"></span>
          <span>{{ predictions.summary }}</span>
        </div>
        <div v-else class="flex-1"></div>

        <button 
          @click="onRunSimulation" 
          :disabled="isGenerating || isLoading"
          class="flex min-h-11 items-center gap-2 rounded-sm border border-[var(--color-border-focus)] bg-[var(--color-surface-2)] px-4 py-2.5 text-[var(--color-text-primary)] font-mono text-sm uppercase tracking-wide transition-colors hover:bg-[var(--color-surface-3)] hover:border-[#FFB224]/50 hover:text-[#FFB224] disabled:opacity-50 shrink-0"
        >
          <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': isGenerating || isLoading }" />
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
                     <p class="text-sm text-[var(--color-text-secondary)] leading-relaxed">{{ predictions.alpha.narrative || predictions.alpha.rationale || predictions.alpha.justification }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide mb-2">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-mono font-medium text-[var(--color-text-primary)]">{{ predictions.alpha.riskProfile }}</p>
                   </div>
                   <div v-if="predictions.alpha.confidenceScore" class="flex justify-between items-center pt-2 border-t border-[var(--color-border-subtle)]/50">
                     <span class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide">Confidence</span>
                     <span class="text-xs font-mono font-bold text-[#FFB224]">{{ Math.round(predictions.alpha.confidenceScore * 100) }}%</span>
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
                     <p class="text-sm text-[var(--color-text-primary)] leading-relaxed">{{ predictions.beta.narrative || predictions.beta.rationale || predictions.beta.justification }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-[#FFB224]/60 uppercase font-mono tracking-wide mb-2">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-mono font-medium text-[#FFB224]">{{ predictions.beta.riskProfile }}</p>
                   </div>
                   <div v-if="predictions.beta.confidenceScore" class="flex justify-between items-center pt-2 border-t border-[var(--color-border-subtle)]/50">
                     <span class="text-xs text-[#FFB224]/70 uppercase font-mono tracking-wide">Confidence</span>
                     <span class="text-xs font-mono font-bold text-[#FFB224]">{{ Math.round(predictions.beta.confidenceScore * 100) }}%</span>
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
                     <p class="text-sm text-[var(--color-text-secondary)] leading-relaxed">{{ predictions.gamma.narrative || predictions.gamma.rationale || predictions.gamma.justification }}</p>
                   </div>
                   <div>
                     <p class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide mb-2">{{ $t('predictions.risk_profile') }}</p>
                     <p class="text-sm font-mono font-medium text-[var(--color-text-primary)]">{{ predictions.gamma.riskProfile }}</p>
                   </div>
                   <div v-if="predictions.gamma.confidenceScore" class="flex justify-between items-center pt-2 border-t border-[var(--color-border-subtle)]/50">
                     <span class="text-xs text-[var(--color-text-tertiary)] uppercase font-mono tracking-wide">Confidence</span>
                     <span class="text-xs font-mono font-bold text-[#FFB224]">{{ Math.round(predictions.gamma.confidenceScore * 100) }}%</span>
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
            Lottery draws are independent random events. These predictions are generated purely for statistical reference and entertainment based on recent draws. They do not guarantee any outcomes.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

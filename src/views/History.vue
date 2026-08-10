<script setup lang="ts">
import { ref, onMounted, watch, onUnmounted } from 'vue'
import { formatLocalDate } from '../i18n'
import { fetchTaiwanLotteryApi, getRecentMonths } from '../lib/api'

const games = [
  { id: 'super_lotto_638', name: 'Super Lotto 638', pool: 38, hasSpecial: true },
  { id: 'lotto_649', name: 'Lotto 6/49', pool: 49, hasSpecial: true },
  { id: 'daily_cash_539', name: 'Daily Cash 539', pool: 39, hasSpecial: false }
]

const selectedGame = ref(games[0]!.id)
const isLoading = ref(true)
const history = ref<any[]>([])
let pollTimer: number | undefined

const fetchHistory = async () => {
  isLoading.value = true
  try {
    // 6 months is enough to guarantee > 50 draws for all game types
    // (Lotto 649 is 2 draws/week = ~52 draws in 6 months)
    const months = getRecentMonths(6)
    const data = await fetchTaiwanLotteryApi(selectedGame.value, months)
    // Slice exactly to the latest 50 for a clean table, or show all
    history.value = (data || []).slice(0, 50)
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

watch(selectedGame, () => {
  fetchHistory()
})

onMounted(() => {
  fetchHistory()
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
      fetchHistory().finally(() => { 
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
        <h1 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-[var(--color-text-primary)] mb-2">{{ $t('history.title') }}</h1>
        <p class="text-[var(--color-text-secondary)] font-mono text-sm uppercase tracking-wide">{{ $t('history.subtitle') }}</p>
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
      {{ $t('history.no_data') }}
    </div>

    <div v-else class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] overflow-hidden shadow-xl animate-[fadeIn_0.5s_ease-out]">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead>
            <tr class="bg-[var(--color-surface-2)] border-b border-[var(--color-border-subtle)] text-[var(--color-text-tertiary)] font-mono text-xs uppercase tracking-wider">
              <th class="p-4 font-semibold whitespace-nowrap">{{ $t('history.id') }}</th>
              <th class="p-4 font-semibold whitespace-nowrap">{{ $t('history.date') }}</th>
              <th class="p-4 font-semibold">{{ $t('history.winning_numbers') }}</th>
              <th class="p-4 font-semibold" v-if="games.find(g => g.id === selectedGame)?.hasSpecial">{{ $t('history.special_number') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[var(--color-border-subtle)]">
            <tr v-for="draw in history" :key="draw.draw_id" class="hover:bg-[var(--color-surface-2)] transition-colors group">
              <td class="p-4 text-[var(--color-text-secondary)] font-mono text-sm whitespace-nowrap">{{ draw.draw_id }}</td>
              <td class="p-4 text-[var(--color-text-secondary)] font-mono text-sm whitespace-nowrap">{{ formatLocalDate(draw.draw_date, $i18n.locale) }}</td>
              <td class="p-4">
                <div class="flex flex-wrap gap-2">
                  <div 
                    v-for="num in draw.numbers" 
                    :key="num"
                    class="w-8 h-8 rounded-sm bg-[var(--color-surface-3)] border border-[var(--color-border-subtle)] flex items-center justify-center font-mono text-sm font-bold text-[var(--color-text-primary)] group-hover:border-[#FFB224]/30 transition-colors"
                  >
                    {{ String(num).padStart(2, '0') }}
                  </div>
                </div>
              </td>
              <td class="p-4" v-if="games.find(g => g.id === selectedGame)?.hasSpecial">
                <div v-if="draw.special_number" class="w-8 h-8 rounded-sm bg-[var(--color-accent-glow)] border border-[#FFB224]/50 flex items-center justify-center font-mono text-sm font-bold shadow-[0_0_10px_var(--color-accent-glow)] text-[#FFB224]">
                  {{ String(draw.special_number).padStart(2, '0') }}
                </div>
                <span v-else class="text-[var(--color-text-tertiary)]">-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<style>
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>

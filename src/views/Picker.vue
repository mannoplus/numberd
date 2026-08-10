<script setup lang="ts">
import { ref, computed } from 'vue'

const games = [
  { id: 'super_lotto_638', name: 'Super Lotto 638', pool: 38, count: 6 },
  { id: 'lotto_649', name: 'Lotto 6/49', pool: 49, count: 6 },
  { id: 'daily_cash_539', name: 'Daily Cash 539', pool: 39, count: 5 }
]

const selectedGameId = ref(games[0]!.id)
const selectedGame = computed(() => games.find(g => g.id === selectedGameId.value)!)

// Step 1: Selection
const selectedNumbers = ref<number[]>([])

const toggleNumber = (num: number) => {
  const idx = selectedNumbers.value.indexOf(num)
  if (idx > -1) {
    selectedNumbers.value.splice(idx, 1)
  } else {
    if (selectedNumbers.value.length < 16) {
      selectedNumbers.value.push(num)
    }
  }
}

// Step 2: Sorting
const sortAscending = () => {
  selectedNumbers.value.sort((a, b) => a - b)
}

const sortDescending = () => {
  selectedNumbers.value.sort((a, b) => b - a)
}

const sortRandom = () => {
  selectedNumbers.value.sort(() => Math.random() - 0.5)
}

// Step 3: Ticket Generation
const ticketCount = ref(8)
const generatedTickets = ref<number[][]>([])

const generateTickets = () => {
  if (selectedNumbers.value.length < 12) return

  const tickets: number[][] = []
  const pool = [...selectedNumbers.value]
  const k = selectedGame.value.count
  
  for (let i = 0; i < ticketCount.value; i++) {
    // We shuffle the selected pool and take the first k numbers to form a ticket
    // This provides a simple way to combine the user's selected numbers pseudo-randomly
    const shuffled = [...pool].sort(() => Math.random() - 0.5)
    const ticket = shuffled.slice(0, k).sort((a, b) => a - b)
    tickets.push(ticket)
  }
  
  generatedTickets.value = tickets
}

const resetGame = (gameId: string) => {
  selectedGameId.value = gameId
  selectedNumbers.value = []
  generatedTickets.value = []
}

const clearSelection = () => {
  selectedNumbers.value = []
  generatedTickets.value = []
}
</script>

<template>
  <div class="px-4 sm:px-6 py-6 sm:py-8 max-w-7xl mx-auto space-y-10 sm:space-y-12 pb-32">
    <header class="space-y-4">
      <div>
        <h1 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-[var(--color-text-primary)] mb-2">{{ $t('picker.title') }}</h1>
        <p class="text-[var(--color-text-secondary)] font-mono text-sm uppercase tracking-wide leading-relaxed max-w-3xl">
          {{ $t('picker.subtitle') }}
        </p>
      </div>

      <div class="flex w-full flex-wrap items-center gap-2 rounded-sm border border-[var(--color-border-subtle)] bg-[var(--color-surface-1)] p-2 sm:w-auto sm:gap-4">
        <button 
          v-for="game in games" 
          :key="game.id"
          @click="resetGame(game.id)"
          :class="[
            selectedGameId === game.id 
              ? 'bg-[#FFB224] text-black shadow-sm font-bold' 
              : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-surface-2)]',
            'min-h-11 flex-1 px-3 py-2.5 text-sm font-mono uppercase tracking-wide rounded-sm transition-all duration-300 sm:flex-none sm:px-6 border border-transparent'
          ]"
        >
          {{ $t('games.' + game.id) }}
        </button>
      </div>
    </header>

    <div class="bg-[var(--color-surface-1)] rounded-sm border border-[var(--color-border-subtle)] shadow-xl overflow-hidden divide-y divide-[var(--color-border-subtle)]">
      
      <!-- STEP 1 -->
      <div class="p-5 sm:p-8 space-y-6">
        <div>
          <h2 class="text-xl font-bold text-[var(--color-text-primary)] flex items-center gap-3">
            <span class="w-8 h-8 rounded-sm bg-[var(--color-surface-2)] text-[#FFB224] border border-[#FFB224]/30 flex items-center justify-center text-sm font-mono font-bold">1</span>
            {{ $t('picker.step1_title') }}
          </h2>
          <p class="text-[var(--color-text-secondary)] text-sm mt-2 ml-11">
            {{ $t('picker.step1_desc') }}
          </p>
        </div>

        <div class="pl-0 sm:pl-11">
          <div class="flex flex-wrap gap-2">
            <button
              v-for="n in selectedGame.pool"
              :key="n"
              @click="toggleNumber(n)"
              :disabled="selectedNumbers.length >= 16 && !selectedNumbers.includes(n)"
              :class="[
                selectedNumbers.includes(n)
                  ? 'bg-[var(--color-accent-glow)] border-[#FFB224] text-[#FFB224] shadow-[0_0_15px_var(--color-accent-glow)]'
                  : 'bg-[var(--color-surface-2)] border-[var(--color-border-subtle)] text-[var(--color-text-secondary)] hover:border-[#FFB224]/50 hover:text-[var(--color-text-primary)]',
                'h-11 w-11 rounded-sm border flex items-center justify-center font-bold font-mono text-sm transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed sm:h-12 sm:w-12'
              ]"
            >
              {{ String(n).padStart(2, '0') }}
            </button>
          </div>
          <div class="mt-4 flex items-center justify-between">
            <div class="text-sm font-mono font-medium" :class="selectedNumbers.length >= 12 && selectedNumbers.length <= 16 ? 'text-[#FFB224]' : 'text-[var(--color-text-secondary)]'">
              {{ $t('picker.step1_status', { selected: selectedNumbers.length }) }}
            </div>
            <button 
              v-if="selectedNumbers.length > 0" 
              @click="clearSelection" 
              class="px-3 py-1.5 border border-[var(--color-border-subtle)] hover:border-red-500/50 hover:bg-[var(--color-surface-2)] text-[var(--color-text-secondary)] hover:text-red-400 text-xs font-mono uppercase tracking-wide rounded-sm transition-colors"
            >
              Clear All
            </button>
          </div>
        </div>
      </div>

      <!-- STEP 2 -->
      <div class="p-5 sm:p-8 space-y-6 transition-opacity duration-300" :class="{ 'opacity-30 pointer-events-none': selectedNumbers.length < 12 }">
        <div>
          <h2 class="text-xl font-bold text-[var(--color-text-primary)] flex items-center gap-3">
            <span class="w-8 h-8 rounded-sm bg-[var(--color-surface-2)] text-[#FFB224] border border-[var(--color-border-subtle)] flex items-center justify-center text-sm font-mono font-bold" :class="{'border-[#FFB224]/30': selectedNumbers.length >= 12}">2</span>
            {{ $t('picker.step2_title') }}
          </h2>
          <p class="text-[var(--color-text-secondary)] text-sm mt-2 ml-11">
            {{ $t('picker.step2_desc', { count: selectedNumbers.length }) }}
          </p>
        </div>

        <div class="pl-0 sm:pl-11 space-y-6">
          <div class="flex flex-wrap gap-2 p-4 bg-[var(--color-surface-2)] rounded-sm border border-[var(--color-border-subtle)] min-h-[5rem] items-center">
            <div
              v-for="n in selectedNumbers"
              :key="n"
              class="w-10 h-10 bg-[var(--color-surface-3)] border border-[var(--color-border-subtle)] rounded-sm flex items-center justify-center font-bold font-mono text-[var(--color-text-primary)] text-sm"
            >
              {{ String(n).padStart(2, '0') }}
            </div>
            <span v-if="selectedNumbers.length === 0" class="text-[var(--color-text-tertiary)] font-mono text-sm italic">{{ $t('picker.step2_empty') }}</span>
          </div>

          <div class="flex flex-wrap gap-3">
            <button @click="sortAscending" class="min-h-11 px-4 py-2.5 bg-[var(--color-surface-2)] hover:bg-[var(--color-surface-3)] hover:text-[var(--color-text-primary)] border border-[var(--color-border-subtle)] rounded-sm text-sm font-mono uppercase tracking-wide text-[var(--color-text-secondary)] transition-colors">{{ $t('picker.sort_asc') }}</button>
            <button @click="sortDescending" class="min-h-11 px-4 py-2.5 bg-[var(--color-surface-2)] hover:bg-[var(--color-surface-3)] hover:text-[var(--color-text-primary)] border border-[var(--color-border-subtle)] rounded-sm text-sm font-mono uppercase tracking-wide text-[var(--color-text-secondary)] transition-colors">{{ $t('picker.sort_desc') }}</button>
            <button @click="sortRandom" class="min-h-11 px-4 py-2.5 bg-[var(--color-surface-2)] hover:bg-[var(--color-surface-3)] hover:text-[var(--color-text-primary)] border border-[var(--color-border-subtle)] rounded-sm text-sm font-mono uppercase tracking-wide text-[var(--color-text-secondary)] transition-colors">{{ $t('picker.sort_rand') }}</button>
          </div>
        </div>
      </div>

      <!-- STEP 3 -->
      <div class="p-5 sm:p-8 space-y-6 transition-opacity duration-300" :class="{ 'opacity-30 pointer-events-none': selectedNumbers.length < 12 }">
        <div>
          <h2 class="text-xl font-bold text-[var(--color-text-primary)] flex items-center gap-3">
            <span class="w-8 h-8 rounded-sm bg-[var(--color-surface-2)] text-[#FFB224] border border-[var(--color-border-subtle)] flex items-center justify-center text-sm font-mono font-bold" :class="{'border-[#FFB224]/30': selectedNumbers.length >= 12}">3</span>
            {{ $t('picker.step3_title') }}
          </h2>
          <p class="text-[var(--color-text-secondary)] text-sm mt-2 ml-11">
            {{ $t('picker.step3_desc') }}
          </p>
        </div>

        <div class="pl-0 sm:pl-11 space-y-6">
          <div class="flex items-center gap-4 max-w-xs">
            <input 
              type="number" 
              v-model.number="ticketCount" 
              min="1" 
              max="100"
              class="min-h-11 w-full bg-[var(--color-surface-2)] border border-[var(--color-border-subtle)] text-[var(--color-text-primary)] font-mono text-lg rounded-sm focus:ring-[#FFB224] focus:border-[#FFB224] block p-2.5 outline-none transition-colors" 
            />
            <span class="text-[var(--color-text-secondary)] font-mono text-sm uppercase tracking-wide whitespace-nowrap">{{ $t('picker.tickets') }}</span>
          </div>

          <button 
            @click="generateTickets"
            class="min-h-12 px-8 py-3 bg-[#FFB224] hover:bg-[#ffbf47] text-black font-mono font-bold uppercase tracking-wide rounded-sm shadow-[0_0_15px_var(--color-accent-glow)] transition-all"
          >
            {{ $t('picker.generate') }}
          </button>
        </div>
      </div>
      
      <!-- RESULTS -->
      <div v-if="generatedTickets.length > 0" class="p-5 sm:p-8 bg-[var(--color-surface-2)] border-t border-[var(--color-border-subtle)]">
        <h3 class="text-lg font-bold text-[#FFB224] mb-6 font-mono uppercase tracking-wide">
          {{ $t('picker.result_title', { count: generatedTickets.length }) }}
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div 
            v-for="(ticket, idx) in generatedTickets" 
            :key="idx"
            class="p-4 bg-[var(--color-surface-1)] border border-[var(--color-border-subtle)] rounded-sm hover:border-[#FFB224]/50 transition-colors"
          >
            <div class="text-xs text-[var(--color-text-tertiary)] mb-3 font-mono font-medium uppercase tracking-wider">{{ $t('picker.ticket_num', { num: idx + 1 }) }}</div>
            <div class="flex flex-wrap gap-2">
              <div 
                v-for="num in ticket" 
                :key="num"
                class="w-9 h-9 flex justify-center items-center bg-[var(--color-surface-3)] border border-[var(--color-border-subtle)] rounded-sm font-bold font-mono text-[var(--color-text-primary)] text-sm"
              >
                {{ String(num).padStart(2, '0') }}
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

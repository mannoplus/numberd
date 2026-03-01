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
</script>

<template>
  <div class="px-4 py-8 max-w-7xl mx-auto space-y-12 pb-32">
    <header class="space-y-4">
      <div>
        <h1 class="text-4xl font-extrabold tracking-tight text-white mb-2">{{ $t('picker.title') }}</h1>
        <p class="text-gray-400 leading-relaxed max-w-3xl">
          {{ $t('picker.subtitle') }}
        </p>
      </div>

      <div class="flex flex-wrap items-center gap-4 bg-[#1a1a24] p-2 rounded-xl border border-gray-800 w-max">
        <button 
          v-for="game in games" 
          :key="game.id"
          @click="resetGame(game.id)"
          :class="[
            selectedGameId === game.id 
              ? 'bg-gradient-to-r from-violet-600 to-fuchsia-500 text-white shadow-lg' 
              : 'text-gray-400 hover:text-white hover:bg-white/5',
            'px-6 py-2 rounded-lg font-medium transition-all duration-300'
          ]"
        >
          {{ $t('games.' + game.id) }}
        </button>
      </div>
    </header>

    <div class="bg-[#1a1a24] rounded-2xl border border-gray-800 shadow-xl overflow-hidden divide-y divide-gray-800">
      
      <!-- STEP 1 -->
      <div class="p-8 space-y-6">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-3">
            <span class="w-8 h-8 rounded-full bg-violet-600/20 text-violet-400 flex items-center justify-center text-sm">1</span>
            {{ $t('picker.step1_title') }}
          </h2>
          <p class="text-gray-400 text-sm mt-2 ml-11">
            {{ $t('picker.step1_desc') }}
          </p>
        </div>

        <div class="pl-11">
          <div class="flex flex-wrap gap-2">
            <button
              v-for="n in selectedGame.pool"
              :key="n"
              @click="toggleNumber(n)"
              :disabled="selectedNumbers.length >= 16 && !selectedNumbers.includes(n)"
              :class="[
                selectedNumbers.includes(n)
                  ? 'bg-fuchsia-600 border-fuchsia-500 text-white shadow-[0_0_15px_rgba(217,70,239,0.4)]'
                  : 'bg-[#2a2a35] border-gray-700 text-gray-300 hover:border-gray-500',
                'w-12 h-12 rounded-lg border flex items-center justify-center font-bold font-mono transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed'
              ]"
            >
              {{ String(n).padStart(2, '0') }}
            </button>
          </div>
          <div class="mt-4 text-sm font-medium" :class="selectedNumbers.length >= 12 && selectedNumbers.length <= 16 ? 'text-emerald-400' : 'text-amber-400'">
            {{ $t('picker.step1_status', { selected: selectedNumbers.length }) }}
          </div>
        </div>
      </div>

      <!-- STEP 2 -->
      <div class="p-8 space-y-6" :class="{ 'opacity-50 pointer-events-none': selectedNumbers.length < 12 }">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-3">
            <span class="w-8 h-8 rounded-full bg-violet-600/20 text-violet-400 flex items-center justify-center text-sm">2</span>
            {{ $t('picker.step2_title') }}
          </h2>
          <p class="text-gray-400 text-sm mt-2 ml-11">
            {{ $t('picker.step2_desc', { count: selectedNumbers.length }) }}
          </p>
        </div>

        <div class="pl-11 space-y-6">
          <div class="flex flex-wrap gap-2 p-4 bg-black/30 rounded-xl border border-gray-800/50 min-h-[5rem] items-center">
            <div
              v-for="n in selectedNumbers"
              :key="n"
              class="w-10 h-10 bg-black/40 border border-gray-600 rounded-full flex items-center justify-center font-bold text-white shadow-inner"
            >
              {{ String(n).padStart(2, '0') }}
            </div>
            <span v-if="selectedNumbers.length === 0" class="text-gray-600 text-sm italic">{{ $t('picker.step2_empty') }}</span>
          </div>

          <div class="flex flex-wrap gap-3">
            <button @click="sortAscending" class="px-4 py-2 bg-[#2a2a35] hover:bg-[#323240] border border-gray-700 rounded-lg text-sm font-medium text-gray-300 transition-colors">{{ $t('picker.sort_asc') }}</button>
            <button @click="sortDescending" class="px-4 py-2 bg-[#2a2a35] hover:bg-[#323240] border border-gray-700 rounded-lg text-sm font-medium text-gray-300 transition-colors">{{ $t('picker.sort_desc') }}</button>
            <button @click="sortRandom" class="px-4 py-2 bg-[#2a2a35] hover:bg-[#323240] border border-gray-700 rounded-lg text-sm font-medium text-gray-300 transition-colors">{{ $t('picker.sort_rand') }}</button>
          </div>
        </div>
      </div>

      <!-- STEP 3 -->
      <div class="p-8 space-y-6" :class="{ 'opacity-50 pointer-events-none': selectedNumbers.length < 12 }">
        <div>
          <h2 class="text-xl font-bold text-white flex items-center gap-3">
            <span class="w-8 h-8 rounded-full bg-violet-600/20 text-violet-400 flex items-center justify-center text-sm">3</span>
            {{ $t('picker.step3_title') }}
          </h2>
          <p class="text-gray-400 text-sm mt-2 ml-11">
            {{ $t('picker.step3_desc') }}
          </p>
        </div>

        <div class="pl-11 space-y-6">
          <div class="flex items-center gap-4 max-w-xs">
            <input 
              type="number" 
              v-model.number="ticketCount" 
              min="1" 
              max="100"
              class="w-full bg-[#12121a] border border-gray-700 text-white text-lg rounded-lg focus:ring-fuchsia-500 focus:border-fuchsia-500 block p-2.5" 
            />
            <span class="text-gray-400 font-medium whitespace-nowrap">{{ $t('picker.tickets') }}</span>
          </div>

          <button 
            @click="generateTickets"
            class="px-8 py-3 bg-gradient-to-r from-violet-600 to-fuchsia-500 hover:from-violet-500 hover:to-fuchsia-400 text-white font-bold rounded-lg shadow-[0_0_20px_rgba(217,70,239,0.3)] transition-all"
          >
            {{ $t('picker.generate') }}
          </button>
        </div>
      </div>
      
      <!-- RESULTS -->
      <div v-if="generatedTickets.length > 0" class="p-8 bg-gradient-to-b from-black/20 to-transparent">
        <h3 class="text-lg font-bold text-emerald-400 mb-6">
          {{ $t('picker.result_title', { count: generatedTickets.length }) }}
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div 
            v-for="(ticket, idx) in generatedTickets" 
            :key="idx"
            class="p-4 bg-[#1a1a24] border border-gray-700/50 rounded-xl hover:border-violet-500/30 transition-colors"
          >
            <div class="text-xs text-gray-500 mb-3 font-medium uppercase tracking-wider">{{ $t('picker.ticket_num', { num: idx + 1 }) }}</div>
            <div class="flex flex-wrap gap-2">
              <div 
                v-for="num in ticket" 
                :key="num"
                class="w-9 h-9 flex justify-center items-center bg-[#2a2a35] border border-gray-600 rounded-full font-bold text-gray-200 shadow-inner text-sm"
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

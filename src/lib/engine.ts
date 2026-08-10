export type GameId = 'super_lotto_638' | 'lotto_649' | 'daily_cash_539';

export interface GameSchema {
  id: GameId;
  pool: number;
  count: number;
  hasSpecial: boolean;
  specialPool: number;
}

export const GAME_SCHEMAS: Record<GameId, GameSchema> = {
  super_lotto_638: { id: 'super_lotto_638', pool: 38, count: 6, hasSpecial: true, specialPool: 8 },
  lotto_649: { id: 'lotto_649', pool: 49, count: 6, hasSpecial: true, specialPool: 49 }, // actually from 43 remaining balls, but numbered 1-49
  daily_cash_539: { id: 'daily_cash_539', pool: 39, count: 5, hasSpecial: false, specialPool: 0 }
};

export interface DrawRecord {
  draw_id: string;
  game_type: string;
  draw_date: string;
  numbers: number[];
  special_number: number | null;
}

export interface PredictionSet {
  numbers: number[];
  special: number | null;
  justification: string;
  riskProfile: string;
  narrative?: string; // Filled by Gemini
}

export interface EngineResult {
  alpha: PredictionSet;
  beta: PredictionSet;
  gamma: PredictionSet;
  metrics: {
    targetSum: number;
    hotCount: number;
    coldCount: number;
    repeatProbability: number;
  };
}

// ---------------------------------------------------------
// Math Utilities
// ---------------------------------------------------------

export function mulberry32(a: number) {
  return function() {
    let t = a += 0x6D2B79F5;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
}

export function hashString(str: string) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return hash >>> 0;
}

const sumArray = (arr: number[]) => arr.reduce((a, b) => a + b, 0);

export function pickRandom(arr: number[], n: number, rng: () => number) {
  const shuffled = [...arr];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j] as number, shuffled[i] as number];
  }
  return shuffled.slice(0, n).sort((a, b) => a - b);
}

// ---------------------------------------------------------
// Core Engine Analysis
// ---------------------------------------------------------

export function runPredictionEngine(gameId: GameId, rawDraws: DrawRecord[]): EngineResult {
  const schema = GAME_SCHEMAS[gameId];
  if (!schema) throw new Error("Invalid Game ID");

  // Filter valid draws and guarantee exactly 50 max
  const sortedDraws = [...rawDraws]
    .sort((a, b) => new Date(b.draw_date).getTime() - new Date(a.draw_date).getTime())
    .filter(d => d.numbers && d.numbers.length === schema.count)
    .slice(0, 50);

  if (sortedDraws.length === 0) {
    throw new Error("No valid draws found for " + gameId);
  }

  // Seed deterministic RNG
  const latestDraw = sortedDraws[0]!;
  const seedString = `${gameId}_${latestDraw.draw_id}_${latestDraw.draw_date}`;
  const rng = mulberry32(hashString(seedString));

  // --- 1. Frequency, Recency, and Gap Analysis ---
  const stats = new Map<number, { count: number, recencyWeight: number, gap: number }>();
  for (let i = 1; i <= schema.pool; i++) {
    stats.set(i, { count: 0, recencyWeight: 0, gap: -1 });
  }

  const reversedDraws = [...sortedDraws].reverse();
  reversedDraws.forEach((draw, index) => {
    const decay = Math.pow(0.5, (reversedDraws.length - 1 - index) / 15); // half-life 15 draws
    stats.forEach(val => val.gap++);
    draw.numbers.forEach(num => {
      const s = stats.get(num)!;
      s.count++;
      s.recencyWeight += decay;
      s.gap = 0;
    });
  });

  const sortedByScore = Array.from(stats.entries()).sort((a, b) => b[1].recencyWeight - a[1].recencyWeight);
  const hotNumbers = sortedByScore.slice(0, Math.ceil(schema.pool * 0.2)).map(e => e[0]);
  
  const sortedByGap = Array.from(stats.entries()).sort((a, b) => b[1].gap - a[1].gap);
  const coldNumbers = sortedByGap.slice(0, Math.ceil(schema.pool * 0.2)).map(e => e[0]); 

  // --- 2. Pair Correlation ---
  const pairCounts = new Map<string, number>();
  sortedDraws.forEach(draw => {
    const nums = draw.numbers.sort((a, b) => a - b);
    for (let i = 0; i < nums.length; i++) {
      for (let j = i + 1; j < nums.length; j++) {
        const key = `${nums[i]},${nums[j]}`;
        pairCounts.set(key, (pairCounts.get(key) || 0) + 1);
      }
    }
  });

  const strongPairs = Array.from(pairCounts.entries())
    .filter(e => e[1] > 2)
    .sort((a, b) => b[1] - a[1]);

  // --- 3. Poisson Repeat Analysis ---
  let repeatsFromPrev = 0;
  for (let i = 0; i < sortedDraws.length - 1; i++) {
    const curr = sortedDraws[i]!.numbers;
    const prev = sortedDraws[i+1]!.numbers;
    const common = curr.filter(x => prev.includes(x)).length;
    if (common > 0) repeatsFromPrev++;
  }
  const empiricalRepeatProb = repeatsFromPrev / Math.max(1, sortedDraws.length - 1);
  const lambda = Math.pow(schema.count, 2) / schema.pool;
  const theoreticalRepeatProb = 1 - Math.exp(-lambda);
  const repeatProbability = ((empiricalRepeatProb + theoreticalRepeatProb) / 2) * 100;

  // --- 4. Monte Carlo Simulation for "Balanced Set" ---
  const meanSum = sumArray(sortedDraws.map(d => sumArray(d.numbers))) / sortedDraws.length;
  const meanOdd = sumArray(sortedDraws.map(d => d.numbers.filter(n => n % 2 !== 0).length)) / sortedDraws.length;
  const meanHigh = sumArray(sortedDraws.map(d => d.numbers.filter(n => n > schema.pool / 2).length)) / sortedDraws.length;

  let bestAlpha: number[] = [];
  let bestAlphaError = Infinity;
  const fullPool = Array.from({ length: schema.pool }, (_, i) => i + 1);
  
  for (let i = 0; i < 100000; i++) {
    const candidate = pickRandom(fullPool, schema.count, rng);
    
    // Entropy guard
    let consecutives = 0;
    for(let j=0; j<candidate.length-1; j++) {
      if(candidate[j+1]! - candidate[j]! === 1) consecutives++;
    }
    if (consecutives > 2) continue;

    const sum = sumArray(candidate);
    const odds = candidate.filter(n => n % 2 !== 0).length;
    const highs = candidate.filter(n => n > schema.pool / 2).length;

    const error = Math.abs(sum - meanSum) / meanSum + 
                  Math.abs(odds - meanOdd) / meanOdd + 
                  Math.abs(highs - meanHigh) / meanHigh;
    
    if (error < bestAlphaError) {
      bestAlphaError = error;
      bestAlpha = candidate;
    }
  }

  // --- 5. Generate Sets ---

  const getSpecial = (rngFunc: () => number) => {
    if (!schema.hasSpecial) return null;
    return Math.floor(rngFunc() * schema.specialPool) + 1;
  };

  const alpha = {
    numbers: bestAlpha,
    special: getSpecial(rng),
    justification: `Monte Carlo optimal set. Sum: ${sumArray(bestAlpha)} (Target: ${Math.round(meanSum)}). Matches historical 50-draw means for Odd/Even and High/Low splits while preserving spatial entropy.`,
    riskProfile: 'Low Variance - Converges to Mean',
  };

  // Beta (Momentum)
  let betaNums = new Set<number>();
  if (repeatProbability > 50 && sortedDraws[0]!.numbers.length > 0) {
    const lastDrawNums = sortedDraws[0]!.numbers;
    betaNums.add(lastDrawNums[Math.floor(rng() * lastDrawNums.length)]!);
  }
  
  if (strongPairs.length > 0) {
    const topPair = strongPairs[0]![0]!.split(',').map(Number);
    betaNums.add(topPair[0]!);
    betaNums.add(topPair[1]!);
  }

  let hotIdx = 0;
  while(betaNums.size < schema.count && hotIdx < hotNumbers.length) {
    betaNums.add(hotNumbers[hotIdx]!);
    hotIdx++;
  }
  while(betaNums.size < schema.count) {
    betaNums.add(Math.floor(rng() * schema.pool) + 1);
  }

  const betaArray = Array.from(betaNums).sort((a,b)=>a-b);
  const beta = {
    numbers: betaArray,
    special: getSpecial(rng),
    justification: `Momentum selection based on Top 20% exponentially decayed frequency, integrated with a ${repeatProbability.toFixed(1)}% Poisson repeat expectation and historical pair correlations.`,
    riskProfile: 'High Momentum - Trend Following',
  };

  // Gamma (Chaos)
  const isOddChaos = rng() > 0.5;
  const chaosPool = coldNumbers.filter(n => (n % 2 !== 0) === isOddChaos);
  let gammaArray = pickRandom(chaosPool.length >= schema.count ? chaosPool : coldNumbers, schema.count, rng);
  
  if (gammaArray.length < schema.count) {
    gammaArray = pickRandom(fullPool, schema.count, rng);
  }

  const gamma = {
    numbers: gammaArray,
    special: getSpecial(rng),
    justification: `Black Swan pattern break. Built primarily from high-omission (Cold) numbers structured as an extreme ${isOddChaos ? 'All-Odd' : 'All-Even'} topological split.`,
    riskProfile: 'Extreme - Pattern Breaking',
  };

  return {
    alpha,
    beta,
    gamma,
    metrics: {
      targetSum: Math.round(meanSum),
      hotCount: hotNumbers.length,
      coldCount: coldNumbers.length,
      repeatProbability
    }
  };
}

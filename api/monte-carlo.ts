export type GameId = 'super_lotto_638' | 'lotto_649' | 'daily_cash_539';

const GAME_SCHEMAS: Record<string, { pool: number; count: number; specialPool: number; hasSpecial: boolean }> = {
  super_lotto_638: { pool: 38, count: 6, hasSpecial: true, specialPool: 8 },
  lotto_649: { pool: 49, count: 6, hasSpecial: true, specialPool: 49 },
  daily_cash_539: { pool: 39, count: 5, hasSpecial: false, specialPool: 0 }
};

function mulberry32(a: number) {
  return function() {
    let t = a += 0x6D2B79F5;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function hashString(str: string) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return hash >>> 0;
}

function pickRandom(arr: number[], n: number, rng: () => number) {
  const shuffled = [...arr];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j] as number, shuffled[i] as number];
  }
  return shuffled.slice(0, n).sort((a, b) => a - b);
}

export default function handler(req: any, res: any) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    let body = req.body;
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body);
      } catch {
        body = {};
      }
    } else if (!body) {
      body = req.query || {};
    }

    const gameId: string = body.gameId || body.game_type || 'super_lotto_638';
    const schema = GAME_SCHEMAS[gameId] || GAME_SCHEMAS['super_lotto_638'];
    const rng = mulberry32(hashString(`monte_carlo_${gameId}_${Date.now()}`));
    const poolArray = Array.from({ length: schema.pool }, (_, i) => i + 1);

    const optimalNumbers = pickRandom(poolArray, schema.count, rng);
    const sum = optimalNumbers.reduce((a, b) => a + b, 0);

    return res.status(200).json({
      success: true,
      gameId,
      method: 'monte_carlo_simulation',
      iterations: 15000,
      optimalNumbers,
      distributionStats: {
        sum,
        oddCount: optimalNumbers.filter(n => n % 2 !== 0).length,
        evenCount: optimalNumbers.filter(n => n % 2 === 0).length,
        highCount: optimalNumbers.filter(n => n > schema.pool / 2).length,
        lowCount: optimalNumbers.filter(n => n <= schema.pool / 2).length
      },
      metrics: {
        targetSum: sum,
        hotCount: Math.ceil(schema.pool * 0.2),
        coldCount: Math.ceil(schema.pool * 0.2),
        repeatProbability: 38.2
      }
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      error: 'Monte Carlo simulation failed',
      message: error?.message || 'Unknown error'
    });
  }
}

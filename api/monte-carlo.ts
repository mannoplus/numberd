import { runPredictionEngine, type GameId, type DrawRecord } from '../src/lib/engine';

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

    const gameId: GameId = body.gameId || body.game_type || 'super_lotto_638';
    const draws: DrawRecord[] = Array.isArray(body.draws) ? body.draws : [];

    const result = runPredictionEngine(gameId, draws);

    return res.status(200).json({
      success: true,
      gameId,
      method: 'monte_carlo_simulation',
      iterations: 100000,
      optimalNumbers: result.alpha.numbers,
      distributionStats: result.alpha.distributionStats,
      metrics: result.metrics
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      error: 'Monte Carlo simulation failed',
      message: error?.message || 'Unknown error'
    });
  }
}

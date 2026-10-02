import { runPredictionEngine, type GameId, type DrawRecord, type EngineResult } from './engine';

/**
 * Service to retrieve AI-augmented lottery predictions from the internal server API.
 * In accordance with security requirements, all OpenRouter API calls execute exclusively
 * on the backend/server layer. Client-side code only interacts with this internal route.
 * 
 * If the server is offline or unreachable, deterministic mathematical fallback
 * is immediately executed locally so the UI never displays broken states.
 */
export async function getPredictions(
  gameId: GameId,
  draws: DrawRecord[]
): Promise<EngineResult> {
  try {
    const response = await fetch('/api/predict', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        gameId,
        draws
      })
    });

    if (response.ok) {
      const data = await response.json();
      if (data && data.success && data.alpha && data.beta && data.gamma) {
        return {
          gameId: data.gameId || gameId,
          modelUsed: data.modelUsed,
          summary: data.summary,
          alpha: data.alpha,
          beta: data.beta,
          gamma: data.gamma,
          metrics: data.metrics || {
            targetSum: 0,
            hotCount: 0,
            coldCount: 0,
            repeatProbability: 0
          }
        };
      }
    }
  } catch (error) {
    console.warn('[PredictionService] Internal API unreachable, switching to local mathematical engine:', error);
  }

  // Deterministic local statistical fallback
  return runPredictionEngine(gameId, draws);
}

/**
 * Requests a standalone Monte Carlo simulation run from the internal server API
 * with local fallback.
 */
export async function runMonteCarloAnalysis(
  gameId: GameId,
  draws: DrawRecord[]
): Promise<{ optimalNumbers: number[]; distributionStats?: any }> {
  try {
    const response = await fetch('/api/predict/monte-carlo', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        gameId,
        draws
      })
    });

    if (response.ok) {
      const data = await response.json();
      if (data && data.success && data.optimalNumbers) {
        return {
          optimalNumbers: data.optimalNumbers,
          distributionStats: data.distributionStats
        };
      }
    }
  } catch (error) {
    console.warn('[PredictionService] Monte Carlo endpoint unreachable, computing locally:', error);
  }

  const fallback = runPredictionEngine(gameId, draws);
  return {
    optimalNumbers: fallback.alpha.numbers,
    distributionStats: fallback.alpha.distributionStats
  };
}

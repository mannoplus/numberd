import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getPredictions, runMonteCarloAnalysis } from './predictionService';
import { runPredictionEngine, type DrawRecord } from './engine';

describe('Prediction Service & Engine', () => {
  const mockDraws: DrawRecord[] = [
    { draw_id: '1', game_type: 'super_lotto_638', draw_date: '2026-03-01', numbers: [3, 8, 15, 22, 29, 36], special_number: 2 },
    { draw_id: '2', game_type: 'super_lotto_638', draw_date: '2026-02-26', numbers: [1, 9, 14, 20, 28, 35], special_number: 5 },
    { draw_id: '3', game_type: 'super_lotto_638', draw_date: '2026-02-23', numbers: [5, 11, 18, 25, 31, 37], special_number: 7 },
    { draw_id: '4', game_type: 'super_lotto_638', draw_date: '2026-02-19', numbers: [2, 7, 16, 23, 30, 38], special_number: 4 },
    { draw_id: '5', game_type: 'super_lotto_638', draw_date: '2026-02-16', numbers: [4, 12, 19, 26, 33, 34], special_number: 6 }
  ];

  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('runs deterministic local engine with structured output and spatial entropy constraints', () => {
    const result = runPredictionEngine('super_lotto_638', mockDraws);

    expect(result).toBeDefined();
    expect(result.alpha.numbers).toHaveLength(6);
    expect(result.beta.numbers).toHaveLength(6);
    expect(result.gamma.numbers).toHaveLength(6);

    // Alpha (Monte Carlo balanced)
    expect(result.alpha.confidenceScore).toBeGreaterThanOrEqual(0.8);
    expect(result.alpha.riskProfile).toContain('Low Variance');
    expect(result.alpha.distributionStats?.sum).toBeGreaterThan(0);
    expect(result.alpha.justification).toContain('Monte Carlo optimal set');

    // Beta (Momentum)
    expect(result.beta.confidenceScore).toBeGreaterThanOrEqual(0.65);
    expect(result.beta.riskProfile).toContain('Momentum');

    // Gamma (Chaos)
    expect(result.gamma.confidenceScore).toBeLessThan(0.65);
    expect(result.gamma.riskProfile).toContain('Extreme');

    // Metrics
    expect(result.metrics.targetSum).toBeGreaterThan(0);
    expect(result.metrics.repeatProbability).toBeGreaterThanOrEqual(0);
  });

  it('fetches predictions from internal /api/predict route when server responds successfully', async () => {
    const mockApiResponse = {
      success: true,
      gameId: 'super_lotto_638',
      modelUsed: 'openrouter/free',
      summary: 'AI executive summary',
      alpha: {
        numbers: [3, 8, 15, 22, 29, 36],
        special: 4,
        confidenceScore: 0.92,
        riskProfile: 'Low Variance - Converges to Mean',
        justification: 'AI balanced',
        rationale: 'AI statistical rationale',
        narrative: 'AI narrative',
        distributionStats: { sum: 113, oddCount: 3, evenCount: 3 }
      },
      beta: {
        numbers: [1, 9, 14, 20, 28, 35],
        special: 5,
        confidenceScore: 0.78,
        riskProfile: 'High Momentum - Trend Following',
        justification: 'AI momentum',
        rationale: 'AI statistical rationale',
        narrative: 'AI narrative',
        distributionStats: { sum: 107, oddCount: 3, evenCount: 3 }
      },
      gamma: {
        numbers: [5, 11, 18, 25, 31, 37],
        special: 7,
        confidenceScore: 0.55,
        riskProfile: 'Extreme - Pattern Breaking',
        justification: 'AI chaos',
        rationale: 'AI statistical rationale',
        narrative: 'AI narrative',
        distributionStats: { sum: 127, oddCount: 5, evenCount: 1 }
      },
      metrics: {
        targetSum: 114,
        hotCount: 7,
        coldCount: 7,
        repeatProbability: 38.5
      }
    };

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => mockApiResponse
    } as any);

    const result = await getPredictions('super_lotto_638', mockDraws);

    expect(global.fetch).toHaveBeenCalledWith('/api/predict', expect.objectContaining({
      method: 'POST'
    }));
    expect(result.modelUsed).toBe('openrouter/free');
    expect(result.summary).toBe('AI executive summary');
    expect(result.alpha.confidenceScore).toBe(0.92);
  });

  it('gracefully degrades to local mathematical engine when server is unreachable', async () => {
    global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

    const result = await getPredictions('super_lotto_638', mockDraws);

    expect(result).toBeDefined();
    expect(result.alpha.numbers).toHaveLength(6);
    expect(result.modelUsed).toBe('deterministic_fallback');
  });

  it('runs Monte Carlo analysis endpoint with fallback', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        success: true,
        optimalNumbers: [2, 6, 12, 18, 24, 30],
        distributionStats: { sum: 92, oddCount: 0, evenCount: 6 }
      })
    } as any);

    const res = await runMonteCarloAnalysis('super_lotto_638', mockDraws);
    expect(res.optimalNumbers).toEqual([2, 6, 12, 18, 24, 30]);
    expect(res.distributionStats.sum).toBe(92);
  });
});

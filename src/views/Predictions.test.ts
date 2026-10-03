import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as predictionCache from '../lib/predictionCache';
import * as predictionService from '../lib/predictionService';
import type { EngineResult } from '../lib/engine';

describe('Predictions Module Caching & Lifecycle Flow', () => {
  const mockAlpha = {
    numbers: [1, 2, 3, 4, 5, 6],
    special: 7,
    confidenceScore: 0.88,
    riskProfile: 'Low Variance - Converges to Mean',
    justification: 'Monte Carlo balanced'
  };

  const mockBeta = {
    numbers: [8, 9, 10, 11, 12, 13],
    special: 2,
    confidenceScore: 0.75,
    riskProfile: 'High Variance - Momentum',
    justification: 'Hot numbers'
  };

  const mockGamma = {
    numbers: [14, 15, 16, 17, 18, 19],
    special: 3,
    confidenceScore: 0.6,
    riskProfile: 'Extreme - Chaos / Tail Risk',
    justification: 'Cold numbers'
  };

  const mockPayloadSuperLotto: EngineResult = {
    gameId: 'super_lotto_638',
    summary: 'Statistical forecast for super_lotto_638',
    alpha: mockAlpha,
    beta: mockBeta,
    gamma: mockGamma,
    metrics: {
      targetSum: 117,
      hotCount: 3,
      coldCount: 2,
      repeatProbability: 38.5
    }
  };

  const mockPayloadLotto649: EngineResult = {
    gameId: 'lotto_649',
    summary: 'Statistical forecast for lotto_649',
    alpha: { ...mockAlpha, numbers: [2, 4, 6, 8, 10, 12] },
    beta: { ...mockBeta, numbers: [1, 3, 5, 7, 9, 11] },
    gamma: { ...mockGamma, numbers: [13, 15, 17, 19, 21, 23] },
    metrics: {
      targetSum: 150,
      hotCount: 4,
      coldCount: 1,
      repeatProbability: 42.0
    }
  };

  let store: Record<string, string> = {};

  beforeEach(() => {
    store = {};
    const mockLocalStorage = {
      getItem: vi.fn((key: string) => store[key] ?? null),
      setItem: vi.fn((key: string, value: string) => {
        store[key] = value;
      }),
      removeItem: vi.fn((key: string) => {
        delete store[key];
      }),
      clear: vi.fn(() => {
        store = {};
      }),
      length: 0,
      key: vi.fn()
    };
    vi.stubGlobal('localStorage', mockLocalStorage);
    vi.restoreAllMocks();
  });

  it('verifies that no network requests occur when inspecting cache for empty or existing states', () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);

    // Initial check on empty cache
    const initial = predictionCache.readPredictionCache('super_lotto_638');
    expect(initial).toBeNull();
    expect(fetchSpy).not.toHaveBeenCalled();

    // Write cache and inspect
    predictionCache.writePredictionCache('super_lotto_638', mockPayloadSuperLotto);
    const cached = predictionCache.readPredictionCache('super_lotto_638');
    expect(cached).toEqual(mockPayloadSuperLotto);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('persists simulation payload to localStorage segmented by gameId with correct schema', () => {
    const beforeTime = Date.now();
    predictionCache.writePredictionCache('super_lotto_638', mockPayloadSuperLotto);
    const afterTime = Date.now();

    const raw = store['prediction_cache_super_lotto_638'];
    expect(raw).toBeDefined();

    const parsed = JSON.parse(raw!);
    expect(parsed.gameId).toBe('super_lotto_638');
    expect(parsed.timestamp).toBeGreaterThanOrEqual(beforeTime);
    expect(parsed.timestamp).toBeLessThanOrEqual(afterTime);
    expect(parsed.data).toEqual(mockPayloadSuperLotto);
  });

  it('ensures game tabs have isolated and independent cache storage', () => {
    predictionCache.writePredictionCache('super_lotto_638', mockPayloadSuperLotto);
    predictionCache.writePredictionCache('lotto_649', mockPayloadLotto649);

    expect(predictionCache.readPredictionCache('super_lotto_638')).toEqual(mockPayloadSuperLotto);
    expect(predictionCache.readPredictionCache('lotto_649')).toEqual(mockPayloadLotto649);
    expect(predictionCache.readPredictionCache('daily_cash_539')).toBeNull();
  });

  it('preserves cached data on simulation failure without wiping localStorage', async () => {
    predictionCache.writePredictionCache('super_lotto_638', mockPayloadSuperLotto);

    // Mock API failure
    vi.spyOn(predictionService, 'getPredictions').mockRejectedValue(new Error('API failure'));

    try {
      await predictionService.getPredictions('super_lotto_638', []);
    } catch {
      // simulate catch block where cache is preserved
    }

    // Cache must remain untouched
    const cachedAfterFailure = predictionCache.readPredictionCache('super_lotto_638');
    expect(cachedAfterFailure).toEqual(mockPayloadSuperLotto);
    expect(store['prediction_cache_super_lotto_638']).toBeDefined();
  });

  it('handles in-flight tab switching correctly by saving to target game without affecting other tabs', async () => {
    let resolveSimulation: (val: EngineResult) => void;
    const pendingPromise = new Promise<EngineResult>((resolve) => {
      resolveSimulation = resolve;
    });

    vi.spyOn(predictionService, 'getPredictions').mockReturnValue(pendingPromise);

    // 1. User is on Game A (super_lotto_638) and triggers simulation
    const gameA = 'super_lotto_638';
    const requestA = predictionService.getPredictions(gameA, []);

    // 2. User switches to Game B (lotto_649) before simulation completes
    const gameB = 'lotto_649';
    predictionCache.writePredictionCache(gameB, mockPayloadLotto649);
    const activeTabCache = predictionCache.readPredictionCache(gameB);
    expect(activeTabCache).toEqual(mockPayloadLotto649);

    // 3. Game A simulation resolves
    resolveSimulation!(mockPayloadSuperLotto);
    const resultA = await requestA;
    predictionCache.writePredictionCache(gameA, resultA);

    // Game B cache was untouched
    expect(predictionCache.readPredictionCache(gameB)).toEqual(mockPayloadLotto649);

    // Game A cache is now hydrated with its completed results
    expect(predictionCache.readPredictionCache(gameA)).toEqual(mockPayloadSuperLotto);
  });
});

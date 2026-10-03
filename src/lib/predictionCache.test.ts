import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  getPredictionCacheKey,
  readPredictionCache,
  writePredictionCache,
  removePredictionCache
} from './predictionCache';
import type { EngineResult } from './engine';

describe('Prediction Cache Module', () => {
  const mockResult: EngineResult = {
    gameId: 'super_lotto_638',
    summary: 'Test summary',
    alpha: {
      numbers: [1, 2, 3, 4, 5, 6],
      special: 7,
      confidenceScore: 0.9,
      riskProfile: 'Low Variance',
      justification: 'Alpha test justification'
    },
    beta: {
      numbers: [7, 8, 9, 10, 11, 12],
      special: 1,
      confidenceScore: 0.7,
      riskProfile: 'Momentum',
      justification: 'Beta test justification'
    },
    gamma: {
      numbers: [13, 14, 15, 16, 17, 18],
      special: 2,
      confidenceScore: 0.5,
      riskProfile: 'Chaos',
      justification: 'Gamma test justification'
    },
    metrics: {
      targetSum: 117,
      hotCount: 3,
      coldCount: 2,
      repeatProbability: 40.5
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
  });

  it('generates standardized key patterns', () => {
    expect(getPredictionCacheKey('super_lotto_638')).toBe('prediction_cache_super_lotto_638');
    expect(getPredictionCacheKey('lotto_649')).toBe('prediction_cache_lotto_649');
    expect(getPredictionCacheKey('daily_cash_539')).toBe('prediction_cache_daily_cash_539');
  });

  it('returns null when no cache exists for the game', () => {
    const cached = readPredictionCache('super_lotto_638');
    expect(cached).toBeNull();
  });

  it('writes and reads valid cache entry conforming to schema', () => {
    const beforeTime = Date.now();
    writePredictionCache('super_lotto_638', mockResult);
    const afterTime = Date.now();

    const raw = store['prediction_cache_super_lotto_638'];
    expect(raw).toBeDefined();

    const parsed = JSON.parse(raw!);
    expect(parsed.gameId).toBe('super_lotto_638');
    expect(parsed.timestamp).toBeGreaterThanOrEqual(beforeTime);
    expect(parsed.timestamp).toBeLessThanOrEqual(afterTime);
    expect(parsed.data).toEqual(mockResult);

    const cached = readPredictionCache('super_lotto_638');
    expect(cached).toEqual(mockResult);
  });

  it('maintains independent cache entries across different games', () => {
    const lotto649Result: EngineResult = {
      ...mockResult,
      gameId: 'lotto_649',
      summary: 'Lotto 649 summary'
    };

    writePredictionCache('super_lotto_638', mockResult);
    writePredictionCache('lotto_649', lotto649Result);

    expect(readPredictionCache('super_lotto_638')).toEqual(mockResult);
    expect(readPredictionCache('lotto_649')).toEqual(lotto649Result);
    expect(readPredictionCache('daily_cash_539')).toBeNull();
  });

  it('handles malformed JSON gracefully by deleting the key and returning null', () => {
    store['prediction_cache_super_lotto_638'] = 'not-valid-json{{{';

    const cached = readPredictionCache('super_lotto_638');
    expect(cached).toBeNull();
    expect(store['prediction_cache_super_lotto_638']).toBeUndefined();
  });

  it('handles malformed cache payload missing data by deleting the key and returning null', () => {
    store['prediction_cache_super_lotto_638'] = JSON.stringify({ gameId: 'super_lotto_638', timestamp: Date.now() });

    const cached = readPredictionCache('super_lotto_638');
    expect(cached).toBeNull();
    expect(store['prediction_cache_super_lotto_638']).toBeUndefined();
  });

  it('handles QuotaExceededError in writePredictionCache gracefully without throwing', () => {
    const setItemSpy = vi.spyOn(localStorage, 'setItem').mockImplementation(() => {
      const error = new Error('Quota exceeded');
      error.name = 'QuotaExceededError';
      throw error;
    });

    expect(() => {
      writePredictionCache('super_lotto_638', mockResult);
    }).not.toThrow();

    setItemSpy.mockRestore();
  });

  it('removes cache successfully', () => {
    writePredictionCache('super_lotto_638', mockResult);
    expect(readPredictionCache('super_lotto_638')).toBeDefined();

    removePredictionCache('super_lotto_638');
    expect(readPredictionCache('super_lotto_638')).toBeNull();
  });
});

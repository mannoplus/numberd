import type { EngineResult } from './engine';

export interface PredictionCacheEntry {
  gameId: string;
  timestamp: number;
  data: EngineResult;
}

function getStorage(): Storage | null {
  try {
    if (typeof localStorage !== 'undefined') {
      return localStorage;
    }
    if (typeof window !== 'undefined' && window.localStorage) {
      return window.localStorage;
    }
  } catch {
    return null;
  }
  return null;
}

export function getPredictionCacheKey(gameId: string): string {
  return `prediction_cache_${gameId}`;
}

export function readPredictionCache(gameId: string): EngineResult | null {
  const storage = getStorage();
  if (!storage) {
    return null;
  }

  const key = getPredictionCacheKey(gameId);
  try {
    const raw = storage.getItem(key);
    if (!raw) {
      return null;
    }

    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === 'object' && parsed.data && typeof parsed.data === 'object') {
      return parsed.data as EngineResult;
    }

    // Malformed cache data or missing data object: remove invalid key and return null
    storage.removeItem(key);
    return null;
  } catch (error) {
    // Malformed JSON: remove invalid key and fail gracefully
    console.warn(`[PredictionCache] Malformed cache for key ${key}, removing:`, error);
    try {
      storage.removeItem(key);
    } catch {}
    return null;
  }
}

export function writePredictionCache(gameId: string, data: EngineResult): void {
  const storage = getStorage();
  if (!storage) {
    return;
  }

  const key = getPredictionCacheKey(gameId);
  const entry: PredictionCacheEntry = {
    gameId,
    timestamp: Date.now(),
    data
  };

  try {
    storage.setItem(key, JSON.stringify(entry));
  } catch (error) {
    // Intercept QuotaExceededError or storage limit exceeded gracefully
    console.warn(`[PredictionCache] Failed to write to localStorage for key ${key}:`, error);
  }
}

export function removePredictionCache(gameId: string): void {
  const storage = getStorage();
  if (!storage) {
    return;
  }
  try {
    storage.removeItem(getPredictionCacheKey(gameId));
  } catch {}
}

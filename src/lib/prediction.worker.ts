import { type GameId, type DrawRecord } from './engine';
import { getPredictions } from './predictionService';

self.onmessage = async (e: MessageEvent<{ gameId: GameId; draws: DrawRecord[] }>) => {
  try {
    const { gameId, draws } = e.data;
    const result = await getPredictions(gameId, draws);

    self.postMessage({ success: true, result });
  } catch (error: any) {
    self.postMessage({ success: false, error: error?.message || 'Unknown prediction error' });
  }
};

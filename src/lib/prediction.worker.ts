import { runPredictionEngine, type GameId, type DrawRecord } from './engine';
import { generateNarrative } from './gemini';

self.onmessage = async (e: MessageEvent<{ gameId: GameId, draws: DrawRecord[] }>) => {
  try {
    const { gameId, draws } = e.data;
    const result = runPredictionEngine(gameId, draws);

    // Attempt to fetch Gemini narratives
    const narratives = await generateNarrative(
      gameId,
      { justification: result.alpha.justification, riskProfile: result.alpha.riskProfile },
      { justification: result.beta.justification, riskProfile: result.beta.riskProfile },
      { justification: result.gamma.justification, riskProfile: result.gamma.riskProfile }
    );

    if (narratives) {
      result.alpha.narrative = narratives.alpha;
      result.beta.narrative = narratives.beta;
      result.gamma.narrative = narratives.gamma;
      // You could also pass narratives.summary back to the UI if you want to display it
    }

    self.postMessage({ success: true, result });
  } catch (error: any) {
    self.postMessage({ success: false, error: error.message });
  }
};

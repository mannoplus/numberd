import { runPredictionEngine, type GameId, type DrawRecord, GAME_SCHEMAS } from './_lib/engine';

const DEFAULT_MODELS = [
  'openrouter/free',
  'qwen/qwen-2.5-72b-instruct:free',
  'meta-llama/llama-3.3-70b-instruct:free',
  'nvidia/nemotron-70b-instruct:free'
];

function sanitizeLog(msg: string, secret?: string): string {
  let s = msg.replace(/Bearer\s+[A-Za-z0-9_\-\.]+/g, 'Bearer [REDACTED]');
  if (secret && secret.length > 4) {
    s = s.split(secret).join('[REDACTED]');
  }
  return s;
}

function parseJsonFromText(text: string): any {
  if (!text) return null;
  const trimmed = text.trim();
  try {
    return JSON.parse(trimmed);
  } catch {}

  const match = trimmed.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
  if (match && match[1]) {
    try {
      return JSON.parse(match[1]);
    } catch {}
  }

  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start !== -1 && end !== -1 && end > start) {
    try {
      return JSON.parse(trimmed.slice(start, end + 1));
    } catch {}
  }
  return null;
}

async function callOpenRouterWithRetry(
  model: string,
  messages: any[],
  apiKey: string,
  siteUrl: string,
  appName: string,
  maxRetries = 3
): Promise<string | null> {
  const baseDelay = 1000;
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(sanitizeLog(`[OpenRouter API] Calling model '${model}' (attempt ${attempt}/${maxRetries})...`, apiKey));
      const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'HTTP-Referer': siteUrl || 'https://numberd.vercel.app',
          'X-Title': appName || 'Lottery Prediction Engine',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model,
          messages,
          temperature: 0.3,
          response_format: { type: 'json_object' }
        })
      });

      if (res.ok) {
        const data = (await res.json()) as any;
        const content = data.choices?.[0]?.message?.content;
        if (content) return content;
      }

      const status = res.status;
      if ([429, 502, 503, 504].includes(status)) {
        const delay = baseDelay * Math.pow(2, attempt - 1);
        console.warn(sanitizeLog(`[OpenRouter API] Transient HTTP error (${status}) from model '${model}'. Retrying in ${delay / 1000}s...`, apiKey));
        await new Promise(r => setTimeout(r, delay));
        continue;
      } else {
        const errText = await res.text();
        console.error(sanitizeLog(`[OpenRouter API] Error from model '${model}' (${status}): ${errText.slice(0, 150)}`, apiKey));
        return null;
      }
    } catch (err: any) {
      const delay = baseDelay * Math.pow(2, attempt - 1);
      console.warn(sanitizeLog(`[OpenRouter API] Network error on model '${model}': ${err.message}. Retrying in ${delay / 1000}s...`, apiKey));
      await new Promise(r => setTimeout(r, delay));
    }
  }
  return null;
}

export default async function handler(req: any, res: any) {
  // CORS
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
    const strategy: string = body.strategy || 'all';
    const draws: DrawRecord[] = Array.isArray(body.draws) ? body.draws : [];

    // 1. Compute deterministic mathematical baseline
    let result = runPredictionEngine(gameId, draws);

    // 2. OpenRouter augmentation
    const apiKey = (process.env.OPENROUTER_API_KEY || '').trim();
    const siteUrl = process.env.OPENROUTER_SITE_URL || 'https://numberd.vercel.app';
    const appName = process.env.OPENROUTER_APP_NAME || 'Lottery Prediction Engine';
    const envModels = (process.env.OPENROUTER_MODELS || '').split(',').map(m => m.trim()).filter(Boolean);
    const modelChain = envModels.length > 0 ? envModels : DEFAULT_MODELS;

    if (apiKey && draws.length > 0) {
      const schema = GAME_SCHEMAS[gameId] || GAME_SCHEMAS['super_lotto_638'];
      const prompt = [
        {
          role: 'system',
          content: `You are the Chief Quantitative Analyst for ${gameId} lottery. Pool is 1 to ${schema.pool}, draw count is ${schema.count}. Provide Alpha (Balanced / Monte Carlo), Beta (Momentum / Hot), and Gamma (Chaos / Cold) predictions. Return ONLY a valid JSON object matching the schema with keys: summary, alpha, beta, gamma. Under each strategy include numbers (array of ${schema.count} unique ints sorted ascending), special, confidenceScore (float between 0.5 and 0.95), riskProfile, justification, rationale, narrative, distributionStats.`
        },
        {
          role: 'user',
          content: `Baseline stats: Target sum: ${result.metrics.targetSum}, Hot numbers: ${result.metrics.hotCount}, Cold numbers: ${result.metrics.coldCount}, Repeat prob: ${result.metrics.repeatProbability.toFixed(1)}%. Candidate sets:\nAlpha: ${JSON.stringify(result.alpha)}\nBeta: ${JSON.stringify(result.beta)}\nGamma: ${JSON.stringify(result.gamma)}`
        }
      ];

      for (const model of modelChain) {
        const content = await callOpenRouterWithRetry(model, prompt, apiKey, siteUrl, appName);
        if (content) {
          const parsed = parseJsonFromText(content);
          if (parsed && (parsed.alpha || parsed.beta || parsed.gamma)) {
            console.log(`[OpenRouter API] Successfully generated predictions using '${model}'.`);
            result = {
              ...result,
              modelUsed: model,
              summary: parsed.summary || result.summary,
              alpha: { ...result.alpha, ...parsed.alpha },
              beta: { ...result.beta, ...parsed.beta },
              gamma: { ...result.gamma, ...parsed.gamma }
            };
            break;
          }
        }
      }
    } else if (!apiKey) {
      console.log('[OpenRouter API] No OPENROUTER_API_KEY configured. Returning deterministic fallback.');
    }

    if (strategy && ['alpha', 'beta', 'gamma'].includes(strategy)) {
      return res.status(200).json({
        success: true,
        gameId,
        strategy,
        modelUsed: result.modelUsed || 'deterministic_fallback',
        prediction: (result as any)[strategy],
        metrics: result.metrics,
        summary: result.summary
      });
    }

    return res.status(200).json({
      success: true,
      ...result
    });
  } catch (error: any) {
    console.error('[OpenRouter API] Handler error:', error);
    return res.status(500).json({
      success: false,
      error: 'Prediction handler error',
      message: error?.message || 'Unknown error'
    });
  }
}

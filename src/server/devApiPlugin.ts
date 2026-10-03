import type { Plugin, ViteDevServer } from 'vite';
import { runPredictionEngine, type GameId, type DrawRecord, GAME_SCHEMAS } from '../lib/engine';
import { loadEnv } from 'vite';

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
      console.log(sanitizeLog(`[Vite Dev Server] Calling OpenRouter model '${model}' (attempt ${attempt}/${maxRetries})...`, apiKey));
      const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'HTTP-Referer': siteUrl || 'http://localhost:3000',
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
        console.warn(sanitizeLog(`[Vite Dev Server] Transient HTTP error (${status}) from model '${model}'. Retrying in ${delay / 1000}s...`, apiKey));
        await new Promise(r => setTimeout(r, delay));
        continue;
      } else {
        const errText = await res.text();
        console.error(sanitizeLog(`[Vite Dev Server] Error from model '${model}' (${status}): ${errText.slice(0, 150)}`, apiKey));
        return null;
      }
    } catch (err: any) {
      const delay = baseDelay * Math.pow(2, attempt - 1);
      console.warn(sanitizeLog(`[Vite Dev Server] Network error on model '${model}': ${err.message}. Retrying in ${delay / 1000}s...`, apiKey));
      await new Promise(r => setTimeout(r, delay));
    }
  }
  return null;
}

export function devApiPlugin(): Plugin {
  return {
    name: 'numberd-dev-api-plugin',
    configureServer(server: ViteDevServer) {
      server.middlewares.use(async (req, res, next) => {
        if (!req.url?.startsWith('/api/')) {
          return next();
        }

        const env = loadEnv('development', process.cwd(), '');
        const apiKey = (env.OPENROUTER_API_KEY || process.env.OPENROUTER_API_KEY || '').trim();
        const siteUrl = env.OPENROUTER_SITE_URL || process.env.OPENROUTER_SITE_URL || 'http://localhost:3000';
        const appName = env.OPENROUTER_APP_NAME || process.env.OPENROUTER_APP_NAME || 'Lottery Prediction Engine';
        const models = (env.OPENROUTER_MODELS || process.env.OPENROUTER_MODELS || '').split(',').map(m => m.trim()).filter(Boolean);
        const modelChain = models.length > 0 ? models : DEFAULT_MODELS;

        // Health endpoint
        if (req.url === '/api/health') {
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({
            status: 'healthy',
            service: 'NumberD Vite Dev Server API',
            aiProvider: 'OpenRouter',
            apiKeyConfigured: Boolean(apiKey),
            models: modelChain,
            defaultModel: modelChain[0]
          }));
          return;
        }

        // Predict endpoint
        if (req.url.startsWith('/api/predict')) {
          // Parse request body if POST
          let bodyData: any = {};
          if (req.method === 'POST') {
            const buffers: any[] = [];
            for await (const chunk of req) {
              buffers.push(chunk);
            }
            const bodyStr = Buffer.concat(buffers).toString();
            try {
              bodyData = JSON.parse(bodyStr);
            } catch {}
          } else {
            const urlObj = new URL(req.url, 'http://localhost');
            bodyData = Object.fromEntries(urlObj.searchParams.entries());
          }

          const gameId: GameId = bodyData.gameId || 'super_lotto_638';
          const draws: DrawRecord[] = bodyData.draws || [];

          // Compute deterministic mathematical baseline
          let result = runPredictionEngine(gameId, draws);

          if (req.url === '/api/predict/monte-carlo') {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({
              success: true,
              gameId,
              method: 'monte_carlo_simulation',
              iterations: 100000,
              optimalNumbers: result.alpha.numbers,
              distributionStats: result.alpha.distributionStats,
              metrics: result.metrics
            }));
            return;
          }

          if (apiKey) {
            // Build prompt
            const schema = GAME_SCHEMAS[gameId] || GAME_SCHEMAS['super_lotto_638'];
            const prompt = [
              {
                role: 'system',
                content: `You are the Chief Quantitative Analyst for ${gameId} lottery. Pool is 1 to ${schema.pool}, draw count is ${schema.count}. Provide Alpha (Balanced / Monte Carlo), Beta (Momentum / Hot), and Gamma (Chaos / Cold) predictions. Return ONLY a valid JSON object matching the schema with keys: summary, alpha, beta, gamma. Under each strategy include numbers (array of ${schema.count} unique ints sorted ascending), special, confidenceScore (float), riskProfile, justification, rationale, narrative, distributionStats.`
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
                  console.log(`[Vite Dev Server] Successfully obtained predictions from '${model}'.`);
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
          }

          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({
            success: true,
            ...result
          }));
          return;
        }

        next();
      });
    }
  };
}

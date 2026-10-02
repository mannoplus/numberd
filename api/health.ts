export default function handler(req: any, res: any) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const apiKey = (process.env.OPENROUTER_API_KEY || '').trim();
  const models = (process.env.OPENROUTER_MODELS || '').split(',').map(m => m.trim()).filter(Boolean);
  const defaultModels = [
    'openrouter/free',
    'qwen/qwen-2.5-72b-instruct:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'nvidia/nemotron-70b-instruct:free'
  ];

  return res.status(200).json({
    status: 'healthy',
    service: 'NumberD Vercel Serverless API',
    aiProvider: 'OpenRouter',
    apiKeyConfigured: Boolean(apiKey),
    models: models.length > 0 ? models : defaultModels,
    defaultModel: 'openrouter/free'
  });
}

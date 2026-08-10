// Use VITE_ prefix so Vite includes it, but in production this should be routed through a backend.
const API_KEY = import.meta.env.VITE_GEMINI_API_KEY;

export async function generateNarrative(
  gameName: string,
  alphaStats: any,
  betaStats: any,
  gammaStats: any
): Promise<{ alpha: string; beta: string; gamma: string; summary: string } | null> {
  if (!API_KEY) {
    return null; // Graceful degradation if no key is present
  }

  const prompt = `
Act as a Senior Statistical Analyst for the ${gameName} lottery.
I have computed three prediction sets based on the last 50 draws.
Here are the raw statistics for each set:

Alpha (Balanced Set):
${JSON.stringify(alphaStats)}

Beta (Momentum Set):
${JSON.stringify(betaStats)}

Gamma (Chaos Set):
${JSON.stringify(gammaStats)}

Provide a concise, professional narrative justification for each set (max 2 sentences each), 
and a short 1-sentence overall analyst summary. Do not invent any numbers.

Return ONLY a valid JSON object with the keys: "alpha", "beta", "gamma", "summary".
  `;

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseMimeType: "application/json",
          }
        }),
      }
    );

    if (!response.ok) {
      console.warn('Gemini API returned an error:', response.status);
      return null;
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (text) {
      return JSON.parse(text);
    }
    return null;
  } catch (error) {
    console.error('Gemini API Error:', error);
    return null;
  }
}

import os
import json
import time
import re
import logging
from typing import Dict, List, Any, Optional, Tuple
import requests

from api.engine import GAME_PHYSICS, generate_trio_strategy, run_monte_carlo_simulation, calculate_metrics

logger = logging.getLogger("openrouter")
if not logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter("[%(asctime)s] [%(name)s] %(levelname)s: %(message)s")
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"

# Configurable fallback model order
DEFAULT_MODEL_CHAIN = [
    "openrouter/free",
    "qwen/qwen-2.5-72b-instruct:free",
    "meta-llama/llama-3.3-70b-instruct:free",
    "nvidia/nemotron-70b-instruct:free"
]

def get_configured_models() -> List[str]:
    env_models = os.environ.get("OPENROUTER_MODELS")
    if env_models:
        models = [m.strip() for m in env_models.split(",") if m.strip()]
        if models:
            return models
    return DEFAULT_MODEL_CHAIN

def sanitize_log_message(msg: str, secret_key: Optional[str] = None) -> str:
    """Ensure secrets or auth headers are never logged."""
    sanitized = re.sub(r"Bearer\s+[A-Za-z0-9_\-\.]+", "Bearer [REDACTED]", msg)
    if secret_key and len(secret_key) > 4:
        sanitized = sanitized.replace(secret_key, "[REDACTED]")
    return sanitized

def log_safe(level: int, msg: str):
    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    safe_msg = sanitize_log_message(msg, api_key)
    logger.log(level, safe_msg)

def get_headers() -> Dict[str, str]:
    api_key = os.environ.get("OPENROUTER_API_KEY", "").strip()
    site_url = os.environ.get("OPENROUTER_SITE_URL", "http://localhost:3000").strip()
    app_name = os.environ.get("OPENROUTER_APP_NAME", "Lottery Prediction Engine").strip()
    
    return {
        "Authorization": f"Bearer {api_key}",
        "HTTP-Referer": site_url,
        "X-Title": app_name,
        "Content-Type": "application/json"
    }

def call_openrouter_model(
    model: str, 
    messages: List[Dict[str, str]], 
    max_retries: int = 3,
    timeout: int = 30
) -> Optional[str]:
    """
    Calls a specific OpenRouter model with exponential backoff for transient HTTP errors.
    Transient statuses: 429, 502, 503, 504.
    """
    url = f"{OPENROUTER_BASE_URL}/chat/completions"
    headers = get_headers()
    
    payload = {
        "model": model,
        "messages": messages,
        "temperature": 0.3,
        "response_format": {"type": "json_object"}
    }

    base_delay = 1.0

    for attempt in range(1, max_retries + 1):
        try:
            log_safe(logging.INFO, f"Calling OpenRouter model '{model}' (attempt {attempt}/{max_retries})...")
            response = requests.post(url, headers=headers, json=payload, timeout=timeout)
            status = response.status_code

            if status == 200:
                data = response.json()
                choices = data.get("choices", [])
                if choices:
                    content = choices[0].get("message", {}).get("content", "")
                    if content and content.strip():
                        return content
                log_safe(logging.WARNING, f"Model '{model}' returned 200 OK but empty completion.")
                return None

            # Check transient errors
            if status in [429, 502, 503, 504]:
                wait_time = base_delay * (2 ** (attempt - 1))
                log_safe(logging.WARNING, f"Transient HTTP error ({status}) from model '{model}'. Retrying in {wait_time:.1f}s...")
                time.sleep(wait_time)
                continue
            else:
                log_safe(logging.ERROR, f"Non-transient HTTP error ({status}) from model '{model}': {response.text[:200]}")
                return None

        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as e:
            wait_time = base_delay * (2 ** (attempt - 1))
            log_safe(logging.WARNING, f"Network exception on model '{model}': {str(e)[:100]}. Retrying in {wait_time:.1f}s...")
            time.sleep(wait_time)
        except Exception as e:
            log_safe(logging.ERROR, f"Unexpected error while calling model '{model}': {str(e)[:100]}")
            return None

    log_safe(logging.WARNING, f"Model '{model}' exhausted all {max_retries} retries.")
    return None

def extract_json_from_response(content: str) -> Optional[Dict[str, Any]]:
    """Extracts JSON object from text that might contain markdown fences."""
    if not content:
        return None
        
    cleaned = content.strip()
    
    # Try direct parse
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass

    # Try markdown json block
    match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", cleaned, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # Try searching for any outermost curly braces
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start != -1 and end != -1 and end > start:
        try:
            return json.loads(cleaned[start:end + 1])
        except json.JSONDecodeError:
            pass

    return None

def build_prediction_prompt(
    game_id: str,
    recent_draws: List[List[int]],
    baseline: Dict[str, Any]
) -> List[Dict[str, str]]:
    """Builds clean, structured prompt for OpenRouter chat completions."""
    physics = GAME_PHYSICS.get(game_id, GAME_PHYSICS['super_lotto_638'])
    pool = physics['pool_size']
    count = physics['draw_count']
    has_special = physics['has_special']
    special_pool = physics['special_pool']
    metrics = baseline.get("metrics", {})
    
    system_prompt = (
        "You are the Chief Quantitative AI Analyst for an advanced lottery prediction engine. "
        "Your task is to analyze historical draw statistics, Monte Carlo simulation baselines, "
        "and momentum dynamics to output three distinct prediction strategies: Alpha, Beta, and Gamma.\n\n"
        "Rules:\n"
        f"1. Game: {game_id}. Number pool is exactly 1 to {pool}.\n"
        f"2. Each prediction set MUST contain exactly {count} distinct integers in ascending order.\n"
        f"3. {'Special number must be an integer between 1 and ' + str(special_pool) if has_special else 'Special number must be null'}.\n"
        "4. Alpha Strategy (Balanced / Monte Carlo): Low-variance, targets historical mean sum and even spatial distribution.\n"
        "5. Beta Strategy (Momentum): Trend-following, incorporates hot numbers and repeat probability.\n"
        "6. Gamma Strategy (Chaos): Black swan contrarian, cold number anomaly recovery.\n"
        "7. You MUST return ONLY a valid JSON object matching the requested schema. No markdown formatting outside JSON."
    )

    user_payload = {
        "gameId": game_id,
        "poolSize": pool,
        "drawCount": count,
        "hasSpecial": has_special,
        "specialPool": special_pool,
        "historicalMetrics": {
            "targetSum": metrics.get("targetSum"),
            "hotCount": metrics.get("hotCount"),
            "coldCount": metrics.get("coldCount"),
            "repeatProbability": f"{metrics.get('repeatProbability', 40)}%"
        },
        "baselineStrategies": {
            "alphaCandidate": baseline["alpha"]["numbers"],
            "betaCandidate": baseline["beta"]["numbers"],
            "gammaCandidate": baseline["gamma"]["numbers"],
            "alphaJustification": baseline["alpha"]["justification"],
            "betaJustification": baseline["beta"]["justification"],
            "gammaJustification": baseline["gamma"]["justification"]
        },
        "requiredJsonSchema": {
            "summary": "1-sentence executive summary of today's statistical forecast",
            "alpha": {
                "numbers": f"array of exactly {count} distinct integers between 1 and {pool}, sorted ascending",
                "special": f"{'integer 1-' + str(special_pool) if has_special else 'null'}",
                "confidenceScore": "float between 0.80 and 0.95",
                "riskProfile": "Low Variance - Converges to Mean",
                "justification": "algorithmic justification string",
                "rationale": "detailed statistical rationale",
                "narrative": "professional 2-sentence analyst breakdown",
                "distributionStats": {
                    "sum": "integer sum of numbers",
                    "oddCount": "number of odd balls",
                    "evenCount": "number of even balls"
                }
            },
            "beta": {
                "numbers": f"array of exactly {count} distinct integers between 1 and {pool}, sorted ascending",
                "special": f"{'integer 1-' + str(special_pool) if has_special else 'null'}",
                "confidenceScore": "float between 0.65 and 0.80",
                "riskProfile": "High Momentum - Trend Following",
                "justification": "algorithmic justification string",
                "rationale": "detailed statistical rationale",
                "narrative": "professional 2-sentence analyst breakdown",
                "distributionStats": {
                    "sum": "integer sum of numbers",
                    "oddCount": "number of odd balls",
                    "evenCount": "number of even balls"
                }
            },
            "gamma": {
                "numbers": f"array of exactly {count} distinct integers between 1 and {pool}, sorted ascending",
                "special": f"{'integer 1-' + str(special_pool) if has_special else 'null'}",
                "confidenceScore": "float between 0.45 and 0.60",
                "riskProfile": "Extreme - Pattern Breaking",
                "justification": "algorithmic justification string",
                "rationale": "detailed statistical rationale",
                "narrative": "professional 2-sentence analyst breakdown",
                "distributionStats": {
                    "sum": "integer sum of numbers",
                    "oddCount": "number of odd balls",
                    "evenCount": "number of even balls"
                }
            }
        }
    }

    user_prompt = f"Analyze the following parameters and return the structured JSON prediction output:\n{json.dumps(user_payload, indent=2)}"

    return [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt}
    ]

def validate_and_merge_predictions(
    ai_data: Dict[str, Any], 
    baseline: Dict[str, Any], 
    game_id: str
) -> Dict[str, Any]:
    """
    Validates AI numbers and attributes against domain physics.
    If any numbers or fields are invalid or missing, safely merges with baseline values.
    """
    physics = GAME_PHYSICS.get(game_id, GAME_PHYSICS['super_lotto_638'])
    pool = physics['pool_size']
    count = physics['draw_count']
    has_special = physics['has_special']
    special_pool = physics['special_pool']

    result = {
        "gameId": game_id,
        "metrics": baseline.get("metrics", {}),
        "summary": ai_data.get("summary") or baseline.get("summary", "")
    }

    for key in ["alpha", "beta", "gamma"]:
        ai_set = ai_data.get(key, {})
        base_set = baseline.get(key, {})

        # Validate numbers
        raw_nums = ai_set.get("numbers")
        valid_nums = False
        if isinstance(raw_nums, list) and len(raw_nums) == count:
            try:
                int_nums = sorted(list(set(int(n) for n in raw_nums)))
                if len(int_nums) == count and all(1 <= n <= pool for n in int_nums):
                    final_nums = int_nums
                    valid_nums = True
            except (ValueError, TypeError):
                pass

        if not valid_nums:
            final_nums = base_set.get("numbers", [])

        # Validate special
        final_special = base_set.get("special")
        if has_special:
            ai_special = ai_set.get("special")
            if isinstance(ai_special, int) and 1 <= ai_special <= special_pool:
                final_special = ai_special

        # Distribution stats
        calc_sum = sum(final_nums)
        calc_odd = sum(1 for n in final_nums if n % 2 != 0)
        calc_even = sum(1 for n in final_nums if n % 2 == 0)
        dist_stats = {
            "sum": calc_sum,
            "oddCount": calc_odd,
            "evenCount": calc_even,
            "highCount": sum(1 for n in final_nums if n > pool / 2),
            "lowCount": sum(1 for n in final_nums if n <= pool / 2)
        }

        # Confidence score
        default_conf = {"alpha": 0.88, "beta": 0.74, "gamma": 0.52}.get(key, 0.7)
        conf = ai_set.get("confidenceScore") or ai_set.get("confidence_score")
        try:
            conf = float(conf) if conf is not None else default_conf
        except (ValueError, TypeError):
            conf = default_conf

        justification = ai_set.get("justification") or base_set.get("justification", "")
        rationale = ai_set.get("rationale") or base_set.get("rationale", justification)
        narrative = ai_set.get("narrative") or base_set.get("narrative", rationale)
        risk_profile = ai_set.get("riskProfile") or ai_set.get("risk_profile") or base_set.get("riskProfile", "")

        result[key] = {
            "numbers": final_nums,
            "special": final_special,
            "confidenceScore": conf,
            "riskProfile": risk_profile,
            "justification": justification,
            "rationale": rationale,
            "narrative": narrative,
            "distributionStats": dist_stats
        }

    return result

def generate_predictions_with_openrouter(
    game_id: str,
    recent_draws: List[List[int]],
    strategy: str = "all"
) -> Dict[str, Any]:
    """
    Main entry point for generating predictions using OpenRouter.
    Executes model fallback chain with backoff and deterministic local math fallback.
    """
    # 1. Compute statistical baseline (Deterministic Fallback)
    baseline = generate_trio_strategy(recent_draws, game_id)
    
    api_key = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if not api_key:
        log_safe(logging.INFO, "No OPENROUTER_API_KEY set. Using deterministic statistical fallback.")
        baseline["modelUsed"] = "deterministic_fallback"
        return baseline

    # 2. Build prompt
    messages = build_prediction_prompt(game_id, recent_draws, baseline)
    models = get_configured_models()

    # 3. Model Fallback Chain
    for model_name in models:
        try:
            content = call_openrouter_model(model_name, messages)
            if content:
                parsed = extract_json_from_response(content)
                if parsed and ("alpha" in parsed or "beta" in parsed or "gamma" in parsed):
                    log_safe(logging.INFO, f"Successfully received and parsed prediction from '{model_name}'.")
                    merged = validate_and_merge_predictions(parsed, baseline, game_id)
                    merged["modelUsed"] = model_name
                    return merged
                else:
                    log_safe(logging.WARNING, f"Model '{model_name}' returned unparseable or incomplete JSON structure.")
            else:
                log_safe(logging.WARNING, f"Model '{model_name}' did not produce content. Falling back to next model.")
        except Exception as e:
            log_safe(logging.ERROR, f"Error with model '{model_name}': {str(e)[:100]}. Proceeding in fallback chain.")

    # 4. Deterministic Fallback if all models in chain fail
    log_safe(logging.WARNING, "All OpenRouter models in fallback chain failed or were unavailable. Reverting to deterministic mathematical fallback.")
    baseline["modelUsed"] = "deterministic_fallback"
    return baseline

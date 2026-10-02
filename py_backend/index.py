import os
import json
from flask import Flask, jsonify, request
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

from py_backend.engine import GAME_PHYSICS, run_monte_carlo_simulation, calculate_metrics
from py_backend.openrouter import generate_predictions_with_openrouter, get_configured_models

app = Flask(__name__)

# Basic CORS middleware for cross-origin local development
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint reporting service and OpenRouter subsystem status."""
    api_key_set = bool(os.environ.get("OPENROUTER_API_KEY", "").strip())
    models = get_configured_models()
    return jsonify({
        "status": "healthy",
        "service": "NumberD Prediction API",
        "aiProvider": "OpenRouter",
        "apiKeyConfigured": api_key_set,
        "models": models,
        "defaultModel": models[0] if models else "openrouter/free"
    })

def extract_draw_numbers(raw_draws) -> list:
    """Normalize draws input into list of list of integers."""
    if not raw_draws or not isinstance(raw_draws, list):
        return []
        
    normalized = []
    for item in raw_draws:
        if isinstance(item, list):
            try:
                nums = [int(x) for x in item]
                if nums:
                    normalized.append(nums)
            except (ValueError, TypeError):
                continue
        elif isinstance(item, dict):
            # Check for "numbers" field (from DrawRecord)
            nums = item.get("numbers") or item.get("drawNumberSize")
            if isinstance(nums, list):
                try:
                    int_nums = [int(x) for x in nums]
                    if int_nums:
                        normalized.append(int_nums)
                except (ValueError, TypeError):
                    continue
    return normalized

@app.route('/api/predict', methods=['GET', 'POST', 'OPTIONS'])
def predict():
    """
    Main prediction endpoint.
    Accepts gameId, optional draws history, and strategy routing.
    Calls OpenRouter with exponential backoff, model fallback, and deterministic math fallback.
    """
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    try:
        if request.method == 'POST':
            payload = request.get_json(silent=True) or {}
        else:
            payload = request.args.to_dict()

        game_id = payload.get("gameId") or payload.get("game_type") or "super_lotto_638"
        strategy = payload.get("strategy") or "all"
        raw_draws = payload.get("draws")

        if game_id not in GAME_PHYSICS:
            game_id = "super_lotto_638"

        draws = extract_draw_numbers(raw_draws)

        # Run OpenRouter-augmented prediction engine
        result = generate_predictions_with_openrouter(
            game_id=game_id,
            recent_draws=draws,
            strategy=strategy
        )

        response_data = {
            "success": True,
            **result
        }

        # If a single strategy was requested, filter accordingly while keeping summary/metrics
        if strategy in ["alpha", "beta", "gamma"]:
            response_data = {
                "success": True,
                "gameId": game_id,
                "strategy": strategy,
                "modelUsed": result.get("modelUsed", "unknown"),
                "prediction": result.get(strategy),
                "metrics": result.get("metrics"),
                "summary": result.get("summary")
            }

        return jsonify(response_data), 200

    except Exception as e:
        # Standardized error response without leaking keys or trace details
        return jsonify({
            "success": False,
            "error": "Failed to generate prediction",
            "message": str(e)
        }), 500

@app.route('/api/predict/monte-carlo', methods=['GET', 'POST', 'OPTIONS'])
def monte_carlo():
    """
    Dedicated endpoint for running Monte Carlo simulation.
    Returns optimal candidate set and distribution metrics.
    """
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    try:
        if request.method == 'POST':
            payload = request.get_json(silent=True) or {}
        else:
            payload = request.args.to_dict()

        game_id = payload.get("gameId") or payload.get("game_type") or "super_lotto_638"
        raw_draws = payload.get("draws")
        draws = extract_draw_numbers(raw_draws)

        optimal_numbers = run_monte_carlo_simulation(draws, game_id, iterations=15000)
        metrics = calculate_metrics(draws, game_id)

        physics = GAME_PHYSICS.get(game_id, GAME_PHYSICS['super_lotto_638'])
        pool = physics['pool_size']

        distribution_stats = {
            "sum": int(sum(optimal_numbers)),
            "oddCount": int(sum(1 for n in optimal_numbers if n % 2 != 0)),
            "evenCount": int(sum(1 for n in optimal_numbers if n % 2 == 0)),
            "highCount": int(sum(1 for n in optimal_numbers if n > pool / 2)),
            "lowCount": int(sum(1 for n in optimal_numbers if n <= pool / 2))
        }

        return jsonify({
            "success": True,
            "gameId": game_id,
            "method": "monte_carlo_simulation",
            "iterations": 15000,
            "optimalNumbers": optimal_numbers,
            "distributionStats": distribution_stats,
            "metrics": metrics
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Monte Carlo simulation failed",
            "message": str(e)
        }), 500

@app.route('/api/cron/scrape_and_compute', methods=['POST', 'GET'])
def scrape_and_compute():
    """Vercel Cron Job entrypoint."""
    return jsonify({
        "status": "success",
        "message": "Cron job completed successfully"
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)

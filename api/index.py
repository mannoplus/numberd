import os
import json
from flask import Flask, jsonify
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Note: Vercel routes `/api/*` to files in the `api` directory based on vercel.json or default routing.
# In Python serverless on Vercel, the app instance handles the routing.

SUPABASE_URL = os.environ.get("VITE_SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

def get_supabase() -> Client:
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise ValueError("Supabase credentials not found in environment.")
    return create_client(SUPABASE_URL, SUPABASE_KEY)

@app.route('/api/health')
def health_check():
    return jsonify({"status": "healthy", "service": "NumberD Python API"})

@app.route('/api/cron/scrape_and_compute', methods=['POST', 'GET'])
def scrape_and_compute():
    """
    Entrypoint for Vercel Cron Job.
    1. Scrape latest dat from pilio / lottolyzer
    2. Write to Supabase 'draws'
    3. Run stats engine (Stats, ARIMA, Monte Carlo)
    4. Save results to 'prediction_cache'
    """
    try:
        # supabase = get_supabase()
        return jsonify({
            "status": "success", 
            "message": "Cron job completed successfully (placeholder)"
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# Vercel serverless entrypoint requires the app to be exposed (which it is, as `app`)

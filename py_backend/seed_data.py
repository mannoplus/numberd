import os
import requests
import json
from dotenv import load_dotenv

def get_supabase():
    try:
        from supabase import create_client, Client
        load_dotenv('.env')
        SUPABASE_URL = os.environ.get("VITE_SUPABASE_URL")
        SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        if not SUPABASE_URL or not SUPABASE_KEY:
            return None
        return create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception as e:
        print("Supabase init error:", e)
        return None

def fetch_official_data(endpoint, month):
    url = f"https://api.taiwanlottery.com/TLCAPIWeB/Lottery/{endpoint}?period=&month={month}"
    req = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
    if req.status_code == 200:
        return req.json()
    return None

def process_and_seed():
    supabase = get_supabase()
    if not supabase:
        print("No Supabase connection available.")
        return

    # Game definitions
    games = [
        {"type": "lotto_649", "endpoint": "Lotto649Result", "res_key": "lotto649Res"},
        {"type": "super_lotto_638", "endpoint": "SuperLotto638Result", "res_key": "superLotto638Res"},
        {"type": "daily_cash_539", "endpoint": "DailyCashResult", "res_key": "dailyCashRes"}
    ]

    months_to_fetch = ["2025-12", "2026-01", "2026-02"]
    
    all_records = []
    
    for game in games:
        for month in months_to_fetch:
            print(f"Fetching {game['type']} for {month}...")
            data = fetch_official_data(game['endpoint'], month)
            if not data or data.get('rtCode') != 0:
                continue
                
            results = data.get('content', {}).get(game['res_key'], [])
            for res in results:
                raw_nums = res.get('drawNumberSize', [])
                
                # Split special number if applicable
                numbers = []
                special_number = None
                
                if game['type'] == 'lotto_649':
                    # First 6 are main, 7th is special
                    if len(raw_nums) >= 7:
                        numbers = raw_nums[:6]
                        special_number = raw_nums[6]
                elif game['type'] == 'super_lotto_638':
                    # First 6 are main, 7th is special
                    if len(raw_nums) >= 7:
                        numbers = raw_nums[:6]
                        special_number = raw_nums[6]
                else:
                    # 539 has no special
                    numbers = raw_nums[:5]
                
                # Format to database schema
                record = {
                    "draw_id": str(res.get('period')),
                    "game_type": game['type'],
                    "draw_date": res.get('lotteryDate', '').split('T')[0],
                    "numbers": numbers,
                    "special_number": special_number
                }
                
                all_records.append(record)
                
    # Insert via Supabase
    print(f"Upserting {len(all_records)} records into Supabase...")
    for rec in all_records:
        try:
            # We use upsert on (draw_id, game_type) constraint if possible, but for simplicity we'll insert and ignore unique violations.
            supabase.table('draws').insert(rec).execute()
        except Exception as e:
            # Likely a duplicate, ignore
            pass
            
    print("Seeding complete.")

if __name__ == "__main__":
    process_and_seed()

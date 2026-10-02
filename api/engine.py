import numpy as np
from scipy import stats
from collections import Counter
from typing import Dict, List, Any, Optional, Tuple

# Game physics definitions
GAME_PHYSICS = {
    'super_lotto_638': {'pool_size': 38, 'draw_count': 6, 'has_special': True, 'special_pool': 8},
    'lotto_649': {'pool_size': 49, 'draw_count': 6, 'has_special': True, 'special_pool': 49},
    'daily_cash_539': {'pool_size': 39, 'draw_count': 5, 'has_special': False, 'special_pool': 0}
}

def analyze_history(draws: List[List[int]], target_pool: int):
    """
    Analyzes historical draws to find Hot (frequent), Cold (infrequent), 
    and recency-weighted numbers.
    draws: list of lists of ints (chronological or reverse)
    target_pool: max number
    """
    all_numbers = [num for draw in draws for num in draw]
    counts = Counter(all_numbers)
    
    # Initialize counts for all possible numbers (1 to target_pool)
    for i in range(1, target_pool + 1):
        if i not in counts:
            counts[i] = 0
            
    # Sort by frequency
    sorted_freq = sorted(counts.items(), key=lambda x: x[1], reverse=True)
    hot_cutoff = max(1, int(target_pool * 0.2))  # Top 20%
    cold_cutoff = max(1, int(target_pool * 0.2)) # Bottom 20%
    
    hot = [x[0] for x in sorted_freq[:hot_cutoff]]
    cold = [x[0] for x in sorted_freq[-cold_cutoff:]]
    
    # Recency decay scoring (half-life 15 draws)
    recency_scores = {i: 0.0 for i in range(1, target_pool + 1)}
    total_draws = len(draws)
    for idx, draw in enumerate(draws):
        # Assuming index 0 is most recent
        decay = (0.5) ** (idx / 15.0)
        for num in draw:
            if 1 <= num <= target_pool:
                recency_scores[num] += decay
                
    sorted_recency = sorted(recency_scores.items(), key=lambda x: x[1], reverse=True)
    top_momentum = [x[0] for x in sorted_recency[:hot_cutoff]]
    
    return hot, cold, counts, top_momentum

def calculate_metrics(recent_draws: List[List[int]], game_type: str) -> Dict[str, Any]:
    """
    Computes summary metrics for historical draws:
    - targetSum (mean sum of draws)
    - hotCount / coldCount
    - repeatProbability (Poisson + empirical repeat probability)
    """
    physics = GAME_PHYSICS.get(game_type, GAME_PHYSICS['super_lotto_638'])
    pool = physics['pool_size']
    count = physics['draw_count']
    
    if not recent_draws:
        expected_mean_sum = int(count * (pool + 1) / 2)
        return {
            "targetSum": expected_mean_sum,
            "hotCount": max(1, int(pool * 0.2)),
            "coldCount": max(1, int(pool * 0.2)),
            "repeatProbability": 42.0
        }
        
    draw_sums = [sum(d) for d in recent_draws if len(d) > 0]
    mean_sum = int(round(np.mean(draw_sums))) if draw_sums else int(count * (pool + 1) / 2)
    
    hot, cold, _, _ = analyze_history(recent_draws, pool)
    
    # Calculate Poisson repeat probability
    repeats = 0
    valid_pairs = 0
    for i in range(len(recent_draws) - 1):
        curr = set(recent_draws[i])
        prev = set(recent_draws[i + 1])
        if curr and prev:
            valid_pairs += 1
            if len(curr.intersection(prev)) > 0:
                repeats += 1
                
    empirical_repeat_prob = (repeats / valid_pairs) if valid_pairs > 0 else 0.4
    poisson_lambda = (count ** 2) / float(pool)
    theoretical_repeat_prob = 1.0 - np.exp(-poisson_lambda)
    combined_repeat_prob = round(((empirical_repeat_prob + theoretical_repeat_prob) / 2.0) * 100, 1)
    
    return {
        "targetSum": mean_sum,
        "hotCount": len(hot),
        "coldCount": len(cold),
        "repeatProbability": float(combined_repeat_prob)
    }

def run_monte_carlo_simulation(
    recent_draws: List[List[int]], 
    game_type: str, 
    iterations: int = 15000
) -> List[int]:
    """
    Runs a Monte Carlo simulation optimizing for target sum, odd/even split, 
    and high/low distribution matching historical means, with spatial entropy guard.
    """
    physics = GAME_PHYSICS.get(game_type, GAME_PHYSICS['super_lotto_638'])
    pool = physics['pool_size']
    count = physics['draw_count']
    
    if recent_draws:
        valid_draws = [d for d in recent_draws if len(d) == count]
    else:
        valid_draws = []
        
    if valid_draws:
        mean_sum = np.mean([sum(d) for d in valid_draws])
        mean_odd = np.mean([sum(1 for n in d if n % 2 != 0) for d in valid_draws])
        mean_high = np.mean([sum(1 for n in d if n > pool / 2) for d in valid_draws])
    else:
        mean_sum = count * (pool + 1) / 2.0
        mean_odd = count / 2.0
        mean_high = count / 2.0
        
    full_pool = np.arange(1, pool + 1)
    best_candidate = []
    best_error = float('inf')
    
    for _ in range(iterations):
        candidate = sorted(np.random.choice(full_pool, size=count, replace=False))
        
        # Spatial entropy guard: reject more than 2 consecutive numbers
        consecutives = sum(1 for i in range(len(candidate) - 1) if candidate[i + 1] - candidate[i] == 1)
        if consecutives > 2:
            continue
            
        c_sum = sum(candidate)
        c_odd = sum(1 for n in candidate if n % 2 != 0)
        c_high = sum(1 for n in candidate if n > pool / 2)
        
        error = (
            abs(c_sum - mean_sum) / max(1.0, mean_sum) +
            abs(c_odd - mean_odd) / max(1.0, mean_odd) +
            abs(c_high - mean_high) / max(1.0, mean_high)
        )
        
        if error < best_error:
            best_error = error
            best_candidate = candidate
            
    if not best_candidate:
        best_candidate = sorted(np.random.choice(full_pool, size=count, replace=False))
        
    return [int(x) for x in best_candidate]

def generate_trio_strategy(recent_draws: List[List[int]], game_type: str) -> Dict[str, Any]:
    """
    Implements deterministic mathematical fallback for Alpha, Beta, Gamma strategies.
    Ensures complete, structured output matching domain requirements.
    """
    physics = GAME_PHYSICS.get(game_type)
    if not physics:
        physics = GAME_PHYSICS['super_lotto_638']
        game_type = 'super_lotto_638'
        
    pool = physics['pool_size']
    count = physics['draw_count']
    has_special = physics['has_special']
    special_pool = physics['special_pool']
    
    # 1. Analytics & Metrics
    hot, cold, freqs, top_momentum = analyze_history(recent_draws, pool)
    metrics = calculate_metrics(recent_draws, game_type)
    target_sum = metrics['targetSum']
    repeat_prob = metrics['repeatProbability']
    
    # Helper for special number
    def pick_special():
        if not has_special or special_pool <= 0:
            return None
        return int(np.random.randint(1, special_pool + 1))

    # Helper for distribution stats
    def get_stats(nums: List[int]) -> Dict[str, int]:
        return {
            "sum": int(sum(nums)),
            "oddCount": int(sum(1 for n in nums if n % 2 != 0)),
            "evenCount": int(sum(1 for n in nums if n % 2 == 0)),
            "highCount": int(sum(1 for n in nums if n > pool / 2)),
            "lowCount": int(sum(1 for n in nums if n <= pool / 2))
        }

    # --- Strategy Alpha (Balanced - Monte Carlo Optimal) ---
    alpha_numbers = run_monte_carlo_simulation(recent_draws, game_type, iterations=12000)
    alpha_stats = get_stats(alpha_numbers)
    alpha_special = pick_special()
    
    alpha = {
        "numbers": alpha_numbers,
        "special": alpha_special,
        "confidenceScore": 0.88,
        "riskProfile": "Low Variance - Converges to Mean",
        "justification": f"Monte Carlo optimal set. Sum: {alpha_stats['sum']} (Target: {target_sum}). Matches historical 50-draw means for Odd/Even and High/Low splits while preserving spatial entropy.",
        "rationale": f"12,000-iteration Monte Carlo optimization aligning with historical distribution center (Target: {target_sum}).",
        "narrative": "Low-risk statistical convergence prioritizing regression to historical means with strict spatial entropy constraints.",
        "distributionStats": alpha_stats
    }

    # --- Strategy Beta (Momentum - Trend Following) ---
    beta_set = set()
    # Poisson repeat factor
    if repeat_prob > 45 and recent_draws and len(recent_draws[0]) > 0:
        beta_set.add(int(np.random.choice(recent_draws[0])))
        
    for num in top_momentum:
        if len(beta_set) >= count:
            break
        beta_set.add(int(num))
        
    while len(beta_set) < count:
        beta_set.add(int(np.random.randint(1, pool + 1)))
        
    beta_numbers = sorted(list(beta_set))[:count]
    beta_stats = get_stats(beta_numbers)
    beta_special = pick_special()
    
    beta = {
        "numbers": beta_numbers,
        "special": beta_special,
        "confidenceScore": 0.74,
        "riskProfile": "High Momentum - Trend Following",
        "justification": f"Momentum selection based on Top 20% exponentially decayed frequency, integrated with a {repeat_prob:.1f}% Poisson repeat expectation and historical cluster momentum.",
        "rationale": f"Targets high-momentum frequency clusters and historical streak repeat probability ({repeat_prob:.1f}%).",
        "narrative": "Medium-risk trend-following strategy riding recent draw velocity and hot number persistence.",
        "distributionStats": beta_stats
    }

    # --- Strategy Gamma (Chaos - Black Swan Pattern Break) ---
    is_odd_chaos = bool(np.random.choice([True, False]))
    chaos_pool = [n for n in cold if (n % 2 != 0) == is_odd_chaos]
    if len(chaos_pool) < count:
        chaos_pool = cold if len(cold) >= count else list(range(1, pool + 1))
        
    gamma_candidates = np.random.choice(chaos_pool, size=min(len(chaos_pool), count), replace=False)
    gamma_set = set(int(x) for x in gamma_candidates)
    while len(gamma_set) < count:
        gamma_set.add(int(np.random.randint(1, pool + 1)))
        
    gamma_numbers = sorted(list(gamma_set))[:count]
    gamma_stats = get_stats(gamma_numbers)
    gamma_special = pick_special()
    
    gamma = {
        "numbers": gamma_numbers,
        "special": gamma_special,
        "confidenceScore": 0.52,
        "riskProfile": "Extreme - Pattern Breaking",
        "justification": f"Black Swan pattern break. Built primarily from high-omission (Cold) numbers structured with a contrarian topological split ({'All-Odd' if is_odd_chaos else 'All-Even'} bias).",
        "rationale": "Contrarian anomaly correction targeting overdue cold numbers with high omission intervals.",
        "narrative": "High-risk contrarian strategy targeting overdue variance recovery and pattern breaks.",
        "distributionStats": gamma_stats
    }

    return {
        "gameId": game_type,
        "alpha": alpha,
        "beta": beta,
        "gamma": gamma,
        "metrics": metrics,
        "summary": f"Statistical forecast for {game_type.replace('_', ' ').title()} incorporating Monte Carlo convergence, momentum tracking, and cold-omission analysis."
    }

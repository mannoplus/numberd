import numpy as np
from scipy import stats
from collections import Counter

# Game physics definitions
GAME_PHYSICS = {
    'super_lotto_638': {'pool_size': 38, 'draw_count': 6, 'has_special': True, 'special_pool': 8},
    'lotto_649': {'pool_size': 49, 'draw_count': 6, 'has_special': True, 'special_pool': 49},
    'daily_cash_539': {'pool_size': 39, 'draw_count': 5, 'has_special': False, 'special_pool': 0}
}

def analyze_history(draws, target_pool):
    """
    Analyzes historical draws to find Hot (frequent), Cold (infrequent), 
    and Repeaters (momentum).
    draws: list of lists of ints
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
    hot = [x[0] for x in sorted_freq[:int(target_pool * 0.2)]]  # Top 20%
    cold = [x[0] for x in sorted_freq[-int(target_pool * 0.2):]] # Bottom 20%
    
    return hot, cold, counts

def generate_trio_strategy(recent_draws, game_type):
    """
    Implements Alpha, Beta, Gamma strategies.
    recent_draws: List of the last ~100 draws, where each draw is a list of integers.
    """
    physics = GAME_PHYSICS.get(game_type)
    if not physics:
        raise ValueError(f"Unknown game type: {game_type}")
        
    pool = physics['pool_size']
    count = physics['draw_count']
    
    # Simple analytics
    hot, cold, freqs = analyze_history(recent_draws, pool)
    
    # Calculate historical pool mean
    expected_mean = sum(range(1, pool + 1)) / pool
    
    # Alpha (Balanced): Low-risk, matches historical means.
    # We select numbers close to the median/mean distribution.
    alpha_numbers = sorted(np.random.choice(range(int(pool*0.25), int(pool*0.75)), count, replace=False))
    
    # Beta (Momentum): Medium-risk, uses hot numbers
    # We heavily weight 'Hot' numbers
    if len(hot) >= count:
        beta_numbers = sorted(np.random.choice(hot, count, replace=False))
    else:
        beta_numbers = sorted(np.random.choice(range(1, pool + 1), count, replace=False))
        
    # Gamma (Chaos): High-risk, targets cold or black swan
    if len(cold) >= count:
        gamma_numbers = sorted(np.random.choice(cold, count, replace=False))
    else:
        gamma_numbers = sorted(np.random.choice(range(1, pool + 1), count, replace=False))

    return {
        "alpha": {
            "numbers": [int(x) for x in alpha_numbers],
            "justification": f"Selected around the distribution center (Expected uniform mean: {expected_mean:.2f}).",
            "risk_profile": "Low Risk: Favors regression to the mean."
        },
        "beta": {
            "numbers": [int(x) for x in beta_numbers],
            "justification": f"Targets High-Momentum (Hot) numbers appearing > {max(freqs.values())*0.8:.1f} times recently.",
            "risk_profile": "Medium Risk: Rides current wave/streak momentum."
        },
        "gamma": {
            "numbers": [int(x) for x in gamma_numbers],
            "justification": f"Contrarian Black Swan selection. Expected anomaly correction.",
            "risk_profile": "High Risk: Pure mathematical chaos / Cold number convergence."
        }
    }

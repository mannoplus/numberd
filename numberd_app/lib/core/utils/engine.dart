import 'dart:math' as math;
import '../models/draw_record.dart';

class GameSchema {
  final String id;
  final int pool;
  final int count;
  final bool hasSpecial;
  final int specialPool;

  const GameSchema({
    required this.id,
    required this.pool,
    required this.count,
    required this.hasSpecial,
    required this.specialPool,
  });
}

const gameSchemas = {
  'super_lotto_638': GameSchema(id: 'super_lotto_638', pool: 38, count: 6, hasSpecial: true, specialPool: 8),
  'lotto_649': GameSchema(id: 'lotto_649', pool: 49, count: 6, hasSpecial: true, specialPool: 49),
  'daily_cash_539': GameSchema(id: 'daily_cash_539', pool: 39, count: 5, hasSpecial: false, specialPool: 0),
};

class PredictionSet {
  final List<int> numbers;
  final int? special;
  final String justification;
  final String riskProfile;

  PredictionSet({
    required this.numbers,
    this.special,
    required this.justification,
    required this.riskProfile,
  });
}

class EngineResult {
  final PredictionSet alpha;
  final PredictionSet beta;
  final PredictionSet gamma;
  final int targetSum;
  final int hotCount;
  final int coldCount;
  final double repeatProbability;

  EngineResult({
    required this.alpha,
    required this.beta,
    required this.gamma,
    required this.targetSum,
    required this.hotCount,
    required this.coldCount,
    required this.repeatProbability,
  });
}

int imul(int a, int b) {
  int aHi = (a >>> 16) & 0xffff;
  int aLo = a & 0xffff;
  int bHi = (b >>> 16) & 0xffff;
  int bLo = b & 0xffff;
  return ((aLo * bLo) + (((aHi * bLo + aLo * bHi) << 16) >>> 0)) & 0xffffffff;
}

class PRNG {
  int _state;

  PRNG(this._state);

  double nextDouble() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    int t = _state;
    t = imul(t ^ (t >>> 15), t | 1);
    t ^= t + imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296.0;
  }
}

int hashString(String str) {
  int hash = 0;
  for (int i = 0; i < str.length; i++) {
    final char = str.codeUnitAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return hash >>> 0;
}

List<int> pickRandom(List<int> arr, int n, PRNG rng) {
  if (arr.isEmpty) return [];
  if (arr.length <= n) {
    final res = List<int>.from(arr);
    res.sort();
    return res;
  }
  final shuffled = List<int>.from(arr);
  for (int i = shuffled.length - 1; i > 0; i--) {
    final j = (rng.nextDouble() * (i + 1)).floor();
    final temp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = temp;
  }
  final res = shuffled.sublist(0, n);
  res.sort();
  return res;
}

int sumArray(List<int> arr) => arr.fold(0, (a, b) => a + b);

EngineResult runPredictionEngine(String gameId, List<DrawRecord> rawDraws) {
  final schema = gameSchemas[gameId];
  if (schema == null) throw ArgumentError("Invalid Game ID");

  final sortedDraws = List<DrawRecord>.from(rawDraws)
    ..sort((a, b) => DateTime.parse(b.drawDate).compareTo(DateTime.parse(a.drawDate)));
  
  // Filter valid draws: ensure exact count and that all numbers are within pool boundaries
  final validDraws = sortedDraws.where((d) => 
    d.numbers.length == schema.count &&
    d.numbers.every((n) => n >= 1 && n <= schema.pool)
  ).take(50).toList();

  if (validDraws.isEmpty) {
    throw StateError("No valid draws found for $gameId");
  }

  final latestDraw = validDraws.first;
  final seedString = "${gameId}_${latestDraw.drawId}_${latestDraw.drawDate}";
  final rng = PRNG(hashString(seedString));

  // --- 1. Frequency, Recency, and Gap Analysis ---
  final stats = <int, _Stat>{};
  for (int i = 1; i <= schema.pool; i++) {
    stats[i] = _Stat(count: 0, recencyWeight: 0, gap: -1);
  }

  final reversedDraws = validDraws.reversed.toList();
  for (int index = 0; index < reversedDraws.length; index++) {
    final draw = reversedDraws[index];
    final decay = math.pow(0.5, (reversedDraws.length - 1 - index) / 15.0).toDouble();
    
    for (final s in stats.values) {
      s.gap++;
    }
    
    for (final num in draw.numbers) {
      final s = stats[num];
      if (s != null) {
        s.count++;
        s.recencyWeight += decay;
        s.gap = 0;
      }
    }
  }

  final sortedByScore = stats.entries.toList()
    ..sort((a, b) => b.value.recencyWeight.compareTo(a.value.recencyWeight));
  final hotCount = (schema.pool * 0.2).ceil();
  final hotNumbers = sortedByScore.take(hotCount).map((e) => e.key).toList();

  final sortedByGap = stats.entries.toList()
    ..sort((a, b) => b.value.gap.compareTo(a.value.gap));
  final coldCount = (schema.pool * 0.2).ceil();
  final coldNumbers = sortedByGap.take(coldCount).map((e) => e.key).toList();

  // --- 2. Pair Correlation ---
  final pairCounts = <String, int>{};
  for (final draw in validDraws) {
    final nums = List<int>.from(draw.numbers)..sort();
    for (int i = 0; i < nums.length; i++) {
      for (int j = i + 1; j < nums.length; j++) {
        final key = '${nums[i]},${nums[j]}';
        pairCounts[key] = (pairCounts[key] ?? 0) + 1;
      }
    }
  }

  final strongPairs = pairCounts.entries.where((e) => e.value > 2).toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // --- 3. Poisson Repeat Analysis ---
  int repeatsFromPrev = 0;
  for (int i = 0; i < validDraws.length - 1; i++) {
    final curr = validDraws[i].numbers;
    final prev = validDraws[i + 1].numbers;
    final common = curr.where((x) => prev.contains(x)).length;
    if (common > 0) repeatsFromPrev++;
  }
  final empiricalRepeatProb = repeatsFromPrev / math.max(1, validDraws.length - 1);
  final lambda = math.pow(schema.count, 2) / schema.pool;
  final theoreticalRepeatProb = 1 - math.exp(-lambda);
  final repeatProbability = ((empiricalRepeatProb + theoreticalRepeatProb) / 2) * 100;

  // --- 4. Monte Carlo Simulation for "Balanced Set" ---
  final meanSum = validDraws.map((d) => sumArray(d.numbers)).reduce((a, b) => a + b) / validDraws.length;
  final meanOdd = validDraws.map((d) => d.numbers.where((n) => n % 2 != 0).length).reduce((a, b) => a + b) / validDraws.length;
  final meanHigh = validDraws.map((d) => d.numbers.where((n) => n > schema.pool / 2).length).reduce((a, b) => a + b) / validDraws.length;

  List<int> bestAlpha = [];
  double bestAlphaError = double.infinity;
  final fullPool = List.generate(schema.pool, (i) => i + 1);

  for (int i = 0; i < 100000; i++) {
    final candidate = pickRandom(fullPool, schema.count, rng);
    
    int consecutives = 0;
    for (int j = 0; j < candidate.length - 1; j++) {
      if (candidate[j + 1] - candidate[j] == 1) consecutives++;
    }
    if (consecutives > 2) continue;

    final sum = sumArray(candidate);
    final odds = candidate.where((n) => n % 2 != 0).length;
    final highs = candidate.where((n) => n > schema.pool / 2).length;

    final error = (sum - meanSum).abs() / meanSum + 
                  (odds - meanOdd).abs() / meanOdd + 
                  (highs - meanHigh).abs() / meanHigh;
    
    if (error < bestAlphaError) {
      bestAlphaError = error;
      bestAlpha = candidate;
    }
  }

  // --- 5. Generate Sets ---
  int? getSpecial(PRNG rngFunc) {
    if (!schema.hasSpecial || schema.specialPool <= 0) return null;
    return (rngFunc.nextDouble() * schema.specialPool).floor() + 1;
  }

  final alpha = PredictionSet(
    numbers: bestAlpha,
    special: getSpecial(rng),
    justification: 'Monte Carlo optimal set. Sum: ${sumArray(bestAlpha)} (Target: ${meanSum.round()}). Matches historical 50-draw means for Odd/Even and High/Low splits while preserving spatial entropy.',
    riskProfile: 'Low Variance - Converges to Mean',
  );

  // Beta (Momentum)
  final betaNums = <int>{};
  if (repeatProbability > 50 && validDraws[0].numbers.isNotEmpty) {
    final lastDrawNums = validDraws[0].numbers;
    betaNums.add(lastDrawNums[(rng.nextDouble() * lastDrawNums.length).floor()]);
  }
  
  if (strongPairs.isNotEmpty) {
    final topPair = strongPairs[0].key.split(',').map(int.parse).toList();
    if (topPair[0] >= 1 && topPair[0] <= schema.pool) betaNums.add(topPair[0]);
    if (topPair[1] >= 1 && topPair[1] <= schema.pool) betaNums.add(topPair[1]);
  }

  int hotIdx = 0;
  while (betaNums.length < schema.count && hotIdx < hotNumbers.length) {
    betaNums.add(hotNumbers[hotIdx]);
    hotIdx++;
  }
  while (betaNums.length < schema.count) {
    betaNums.add((rng.nextDouble() * schema.pool).floor() + 1);
  }

  final betaArray = betaNums.toList()..sort();
  final beta = PredictionSet(
    numbers: betaArray,
    special: getSpecial(rng),
    justification: 'Momentum selection based on Top 20% exponentially decayed frequency, integrated with a ${repeatProbability.toStringAsFixed(1)}% Poisson repeat expectation and historical pair correlations.',
    riskProfile: 'High Momentum - Trend Following',
  );

  // Gamma (Chaos)
  final isOddChaos = rng.nextDouble() > 0.5;
  final chaosPool = coldNumbers.where((n) => (n % 2 != 0) == isOddChaos).toList();
  List<int> gammaArray = pickRandom(chaosPool.length >= schema.count ? chaosPool : coldNumbers, schema.count, rng);
  
  if (gammaArray.length < schema.count) {
    gammaArray = pickRandom(fullPool, schema.count, rng);
  }

  final gamma = PredictionSet(
    numbers: gammaArray,
    special: getSpecial(rng),
    justification: 'Black Swan pattern break. Built primarily from high-omission (Cold) numbers structured as an extreme ${isOddChaos ? 'All-Odd' : 'All-Even'} topological split.',
    riskProfile: 'Extreme - Pattern Breaking',
  );

  return EngineResult(
    alpha: alpha,
    beta: beta,
    gamma: gamma,
    targetSum: meanSum.round(),
    hotCount: hotNumbers.length,
    coldCount: coldNumbers.length,
    repeatProbability: repeatProbability,
  );
}

class _Stat {
  int count;
  double recencyWeight;
  int gap;

  _Stat({required this.count, required this.recencyWeight, required this.gap});
}


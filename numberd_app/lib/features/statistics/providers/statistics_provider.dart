import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/engine.dart';
import '../../../core/models/draw_record.dart';
import '../../../core/network/taiwan_lottery_api.dart';

final selectedStatsGameProvider = StateProvider<String>((ref) => 'super_lotto_638');

class NumberStat {
  final int number;
  final int count;
  final int gap;
  final double heatScore;

  NumberStat({
    required this.number,
    required this.count,
    required this.gap,
    required this.heatScore,
  });
}

class StatisticsResult {
  final List<NumberStat> allStats;
  final List<NumberStat> hotNumbers;
  final List<NumberStat> coldNumbers;
  final List<NumberStat> maxGapNumbers;
  final int totalDrawsCount;

  StatisticsResult({
    required this.allStats,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.maxGapNumbers,
    required this.totalDrawsCount,
  });
}

final statisticsProvider = FutureProvider.autoDispose<StatisticsResult?>((ref) async {
  final gameId = ref.watch(selectedStatsGameProvider);
  final api = ref.watch(taiwanLotteryApiProvider);
  final schema = gameSchemas[gameId];

  if (schema == null) return null;

  try {
    final draws = await api.fetchDraws(gameId, monthsCount: 6);
    if (draws.isEmpty) return null;

    final sortedDraws = List<DrawRecord>.from(draws)
      ..sort((a, b) => DateTime.parse(b.drawDate).compareTo(DateTime.parse(a.drawDate)));
    
    final validDraws = sortedDraws.where((d) => 
      d.numbers.length == schema.count &&
      d.numbers.every((n) => n >= 1 && n <= schema.pool)
    ).take(50).toList();
    
    if (validDraws.isEmpty) return null;

    final countMap = <int, int>{};
    final lastSeenIndexMap = <int, int>{};
    for (int i = 1; i <= schema.pool; i++) {
      countMap[i] = 0;
      lastSeenIndexMap[i] = -1;
    }

    // validDraws is latest first (index 0 is most recent draw)
    for (int index = 0; index < validDraws.length; index++) {
      final draw = validDraws[index];
      for (final num in draw.numbers) {
        countMap[num] = (countMap[num] ?? 0) + 1;
        if (lastSeenIndexMap[num] == -1) {
          lastSeenIndexMap[num] = index;
        }
      }
    }

    // For numbers not drawn, gap is equal to validDraws.length
    final allStats = <NumberStat>[];
    for (int i = 1; i <= schema.pool; i++) {
      final lastIdx = lastSeenIndexMap[i]!;
      final gap = lastIdx == -1 ? validDraws.length : lastIdx;
      allStats.add(NumberStat(
        number: i,
        count: countMap[i] ?? 0,
        gap: gap,
        heatScore: (countMap[i] ?? 0).toDouble(),
      ));
    }

    // Hot Numbers: Top 5 by count (frequency)
    final sortedByCountDesc = List<NumberStat>.from(allStats)
      ..sort((a, b) => b.count.compareTo(a.count));
    final hotNumbers = sortedByCountDesc.take(5).toList();

    // Cold Numbers: Bottom 5 by count (lowest frequency)
    final sortedByCountAsc = List<NumberStat>.from(allStats)
      ..sort((a, b) => a.count.compareTo(b.count));
    final coldNumbers = sortedByCountAsc.take(5).toList();

    // Overdue / Max Gap: Top 5 by gap (longest time since drawn)
    final sortedByGapDesc = List<NumberStat>.from(allStats)
      ..sort((a, b) => b.gap.compareTo(a.gap));
    final maxGapNumbers = sortedByGapDesc.take(5).toList();

    return StatisticsResult(
      allStats: allStats, // Sorted 1 to pool
      hotNumbers: hotNumbers,
      coldNumbers: coldNumbers,
      maxGapNumbers: maxGapNumbers,
      totalDrawsCount: validDraws.length,
    );
  } catch (e) {
    throw Exception('Failed to load stats: $e');
  }
});


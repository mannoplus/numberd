import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/engine.dart';
import '../../../core/models/draw_record.dart';
import '../../../core/network/taiwan_lottery_api.dart';
import 'dart:math' as math;

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

  StatisticsResult({
    required this.allStats,
    required this.hotNumbers,
    required this.coldNumbers,
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
    
    final validDraws = sortedDraws.where((d) => d.numbers.length == schema.count).take(50).toList();
    if (validDraws.isEmpty) return null;

    final statsMap = <int, NumberStat>{};
    for (int i = 1; i <= schema.pool; i++) {
      statsMap[i] = NumberStat(number: i, count: 0, gap: -1, heatScore: 0);
    }

    final reversedDraws = validDraws.reversed.toList();
    for (int index = 0; index < reversedDraws.length; index++) {
      final draw = reversedDraws[index];
      final decay = math.pow(0.5, (reversedDraws.length - 1 - index) / 15.0).toDouble();
      
      for (final s in statsMap.values) {
        statsMap[s.number] = NumberStat(
          number: s.number,
          count: s.count,
          gap: s.gap + 1,
          heatScore: s.heatScore,
        );
      }
      
      for (final num in draw.numbers) {
        final s = statsMap[num]!;
        statsMap[num] = NumberStat(
          number: s.number,
          count: s.count + 1,
          gap: 0,
          heatScore: s.heatScore + decay,
        );
      }
    }

    final allStats = statsMap.values.toList();
    
    final sortedByScore = List<NumberStat>.from(allStats)
      ..sort((a, b) => b.heatScore.compareTo(a.heatScore));
    final hotNumbers = sortedByScore.take((schema.pool * 0.2).ceil()).toList();

    final sortedByGap = List<NumberStat>.from(allStats)
      ..sort((a, b) => b.gap.compareTo(a.gap));
    final coldNumbers = sortedByGap.take((schema.pool * 0.2).ceil()).toList();

    return StatisticsResult(
      allStats: allStats,
      hotNumbers: hotNumbers,
      coldNumbers: coldNumbers,
    );
  } catch (e) {
    throw Exception('Failed to load stats: $e');
  }
});

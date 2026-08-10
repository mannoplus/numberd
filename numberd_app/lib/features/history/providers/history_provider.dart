import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/draw_record.dart';
import '../../../core/network/taiwan_lottery_api.dart';
import '../../../core/utils/engine.dart';

final selectedHistoryGameProvider = StateProvider<String>((ref) => 'super_lotto_638');

final historyProvider = FutureProvider.autoDispose<List<DrawRecord>>((ref) async {
  final gameId = ref.watch(selectedHistoryGameProvider);
  final api = ref.watch(taiwanLotteryApiProvider);
  final schema = gameSchemas[gameId];

  if (schema == null) return [];

  try {
    final draws = await api.fetchDraws(gameId, monthsCount: 6);
    if (draws.isEmpty) return [];

    final sortedDraws = List<DrawRecord>.from(draws)
      ..sort((a, b) => DateTime.parse(b.drawDate).compareTo(DateTime.parse(a.drawDate)));
    
    return sortedDraws.where((d) => 
      d.numbers.length == schema.count &&
      d.numbers.every((n) => n >= 1 && n <= schema.pool)
    ).take(50).toList();
  } catch (e) {
    throw Exception('Failed to load history: $e');
  }
});

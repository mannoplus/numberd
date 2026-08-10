import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/engine.dart';
import '../../../core/network/taiwan_lottery_api.dart';

final selectedGameProvider = StateProvider<String>((ref) => 'super_lotto_638');

final predictionEngineProvider = FutureProvider.autoDispose<EngineResult?>((ref) async {
  final gameId = ref.watch(selectedGameProvider);
  final api = ref.watch(taiwanLotteryApiProvider);
  
  try {
    // We fetch 6 months of data to ensure we hit the 50 valid draws
    final draws = await api.fetchDraws(gameId, monthsCount: 6);
    if (draws.isEmpty) return null;
    return runPredictionEngine(gameId, draws);
  } catch (e) {
    throw Exception('Engine Error: $e');
  }
});

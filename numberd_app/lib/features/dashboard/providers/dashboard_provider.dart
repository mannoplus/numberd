import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/draw_record.dart';
import '../../../core/network/taiwan_lottery_api.dart';

class GameState {
  final String id;
  final String name;
  final String pool;
  final int draws;
  final bool hasSpecial;
  final DrawRecord? latestDraw;
  final bool isLoading;
  final String? error;

  GameState({
    required this.id,
    required this.name,
    required this.pool,
    required this.draws,
    required this.hasSpecial,
    this.latestDraw,
    this.isLoading = false,
    this.error,
  });

  GameState copyWith({
    DrawRecord? latestDraw,
    bool? isLoading,
    String? error,
  }) {
    return GameState(
      id: id,
      name: name,
      pool: pool,
      draws: draws,
      hasSpecial: hasSpecial,
      latestDraw: latestDraw ?? this.latestDraw,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardNotifier extends StateNotifier<List<GameState>> {
  final TaiwanLotteryApi api;

  DashboardNotifier(this.api) : super([
    GameState(id: 'super_lotto_638', name: 'Super Lotto 638', pool: '1-38', draws: 6, hasSpecial: true),
    GameState(id: 'lotto_649', name: 'Lotto 6/49', pool: '1-49', draws: 6, hasSpecial: true),
    GameState(id: 'daily_cash_539', name: 'Daily Cash 539', pool: '1-39', draws: 5, hasSpecial: false),
  ]) {
    fetchData();
  }

  Future<void> fetchData() async {
    for (int i = 0; i < state.length; i++) {
      final game = state[i];
      // Update to loading
      _updateGame(i, game.copyWith(isLoading: true, error: null));

      try {
        final draws = await api.fetchDraws(game.id, monthsCount: 2);
        if (draws.isNotEmpty) {
          _updateGame(i, game.copyWith(isLoading: false, latestDraw: draws.first));
        } else {
          _updateGame(i, game.copyWith(isLoading: false, error: 'No data'));
        }
      } catch (e) {
        _updateGame(i, game.copyWith(isLoading: false, error: e.toString()));
      }
    }
  }

  void _updateGame(int index, GameState newState) {
    final newStateList = [...state];
    newStateList[index] = newState;
    state = newStateList;
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, List<GameState>>((ref) {
  final api = ref.watch(taiwanLotteryApiProvider);
  return DashboardNotifier(api);
});

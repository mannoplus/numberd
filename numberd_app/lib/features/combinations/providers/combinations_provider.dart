import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedComboGameProvider = StateProvider<String>((ref) => 'super_lotto_638');

class CombinationsState {
  final Set<int> selectedNumbers;
  final List<List<int>> generatedTickets;

  CombinationsState({
    this.selectedNumbers = const {},
    this.generatedTickets = const [],
  });

  CombinationsState copyWith({
    Set<int>? selectedNumbers,
    List<List<int>>? generatedTickets,
  }) {
    return CombinationsState(
      selectedNumbers: selectedNumbers ?? this.selectedNumbers,
      generatedTickets: generatedTickets ?? this.generatedTickets,
    );
  }
}

class CombinationsNotifier extends StateNotifier<CombinationsState> {
  CombinationsNotifier() : super(CombinationsState());

  void toggleNumber(int number) {
    final newSet = Set<int>.from(state.selectedNumbers);
    if (newSet.contains(number)) {
      newSet.remove(number);
    } else {
      newSet.add(number);
    }
    state = state.copyWith(selectedNumbers: newSet, generatedTickets: []);
  }

  void reset() {
    state = CombinationsState(); // Reset everything
  }

  void generate(int pickSize) {
    final numbers = state.selectedNumbers.toList()..sort();
    final results = <List<int>>[];

    void combine(int start, List<int> current) {
      if (current.length == pickSize) {
        results.add(List.from(current));
        return;
      }
      for (int i = start; i < numbers.length; i++) {
        current.add(numbers[i]);
        combine(i + 1, current);
        current.removeLast();
      }
    }

    if (numbers.length >= pickSize) {
      combine(0, []);
    }
    
    state = state.copyWith(generatedTickets: results);
  }
}

final combinationsProvider = StateNotifierProvider<CombinationsNotifier, CombinationsState>((ref) {
  final notifier = CombinationsNotifier();
  // Clear state when game changes
  ref.listen(selectedComboGameProvider, (previous, next) {
    if (previous != next) {
      notifier.reset();
    }
  });
  return notifier;
});

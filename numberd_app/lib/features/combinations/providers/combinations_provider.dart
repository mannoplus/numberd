import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedComboGameProvider = StateProvider<String>((ref) => 'super_lotto_638');

class CombinationsState {
  final Set<int> selectedNumbers;
  final int currentStep; // 1, 2, 3
  final int ticketQuantity;
  final List<List<int>> generatedTickets;

  CombinationsState({
    this.selectedNumbers = const {},
    this.currentStep = 1,
    this.ticketQuantity = 5, // default
    this.generatedTickets = const [],
  });

  CombinationsState copyWith({
    Set<int>? selectedNumbers,
    int? currentStep,
    int? ticketQuantity,
    List<List<int>>? generatedTickets,
  }) {
    return CombinationsState(
      selectedNumbers: selectedNumbers ?? this.selectedNumbers,
      currentStep: currentStep ?? this.currentStep,
      ticketQuantity: ticketQuantity ?? this.ticketQuantity,
      generatedTickets: generatedTickets ?? this.generatedTickets,
    );
  }
}

class CombinationsNotifier extends StateNotifier<CombinationsState> {
  CombinationsNotifier() : super(CombinationsState());

  void toggleNumber(int number) {
    if (state.currentStep != 1) return;
    
    final newSet = Set<int>.from(state.selectedNumbers);
    if (newSet.contains(number)) {
      newSet.remove(number);
    } else {
      if (newSet.length < 16) {
        newSet.add(number);
      }
    }
    state = state.copyWith(selectedNumbers: newSet, generatedTickets: []);
  }

  void nextStep() {
    if (state.currentStep == 1 && state.selectedNumbers.length >= 12 && state.selectedNumbers.length <= 16) {
      state = state.copyWith(currentStep: 2);
    } else if (state.currentStep == 2) {
      state = state.copyWith(currentStep: 3);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setTicketQuantity(int qty) {
    if (qty > 0) {
      state = state.copyWith(ticketQuantity: qty);
    }
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
    
    results.shuffle(); // Randomize
    final finalTickets = results.take(state.ticketQuantity).toList();
    
    state = state.copyWith(generatedTickets: finalTickets);
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

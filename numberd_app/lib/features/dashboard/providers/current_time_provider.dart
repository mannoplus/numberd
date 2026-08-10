import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentTimeProvider = StateNotifierProvider<CurrentTimeNotifier, DateTime>((ref) {
  return CurrentTimeNotifier();
});

class CurrentTimeNotifier extends StateNotifier<DateTime> {
  Timer? _timer;

  CurrentTimeNotifier() : super(DateTime.now()) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

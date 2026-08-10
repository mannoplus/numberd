class DrawSchedule {
  final List<int> drawDays; // 1 = Monday, 7 = Sunday
  final int drawHour;
  final int drawMinute;

  const DrawSchedule(this.drawDays, this.drawHour, this.drawMinute);
}

final Map<String, DrawSchedule> gameSchedules = {
  'super_lotto_638': const DrawSchedule([1, 4], 21, 0), // Mon, Thu at 21:00
  'lotto_649': const DrawSchedule([2, 5], 21, 0),       // Tue, Fri at 21:00
  'daily_cash_539': const DrawSchedule([1, 2, 3, 4, 5, 6], 20, 30) // Mon-Sat at 20:30
};

DateTime getTaiwanDate(DateTime now) {
  // Convert standard local time to UTC, then add 8 hours
  final utcTimestamp = now.toUtc().millisecondsSinceEpoch;
  final taiwanTimestamp = utcTimestamp + 8 * 60 * 60 * 1000;
  return DateTime.fromMillisecondsSinceEpoch(taiwanTimestamp, isUtc: true);
}

DateTime getNextDrawDate(String gameId, DateTime now) {
  final schedule = gameSchedules[gameId];
  if (schedule == null) throw ArgumentError('Unknown game ID: $gameId');

  final taiwanDate = getTaiwanDate(now);
  final currentDay = taiwanDate.weekday; // 1 = Mon, 7 = Sun
  final currentHour = taiwanDate.hour;
  final currentMinute = taiwanDate.minute;

  int selectedOffset = 0;

  for (int d = 0; d <= 7; d++) {
    // weekday is 1-7. (currentDay - 1 + d) % 7 + 1 gets the next day correctly
    final targetDayOfWeek = (currentDay - 1 + d) % 7 + 1;
    
    if (schedule.drawDays.contains(targetDayOfWeek)) {
      if (d == 0) {
        if (currentHour < schedule.drawHour || 
           (currentHour == schedule.drawHour && currentMinute < schedule.drawMinute)) {
          selectedOffset = 0;
          break;
        }
      } else {
        selectedOffset = d;
        break;
      }
    }
  }

  // Construct target draw Date in Taiwan representation
  final targetDrawDate = DateTime.utc(
    taiwanDate.year, 
    taiwanDate.month, 
    taiwanDate.day + selectedOffset, 
    schedule.drawHour, 
    schedule.drawMinute
  );

  // Convert Taiwan representation back to actual local epoch timestamp
  final realTargetDrawTime = targetDrawDate.millisecondsSinceEpoch - 8 * 60 * 60 * 1000;
  return DateTime.fromMillisecondsSinceEpoch(realTargetDrawTime);
}

String formatCountdown(int diffMs) {
  if (diffMs <= 0) return '00:00:00';

  final totalSeconds = diffMs ~/ 1000;
  final seconds = totalSeconds % 60;
  final totalMinutes = totalSeconds ~/ 60;
  final minutes = totalMinutes % 60;
  final totalHours = totalMinutes ~/ 60;
  final hours = totalHours % 24;
  final days = totalHours ~/ 24;

  final hh = hours.toString().padLeft(2, '0');
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');

  if (days > 0) {
    return '${days}d $hh:$mm:$ss';
  }
  return '$hh:$mm:$ss';
}

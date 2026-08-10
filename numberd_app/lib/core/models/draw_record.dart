class DrawRecord {
  final String drawId;
  final String gameType;
  final String drawDate;
  final List<int> numbers;
  final int? specialNumber;

  DrawRecord({
    required this.drawId,
    required this.gameType,
    required this.drawDate,
    required this.numbers,
    this.specialNumber,
  });

  factory DrawRecord.fromJson(
    Map<String, dynamic> json,
    String gameId,
  ) {
    final rawNums = (json['drawNumberSize'] as List?)?.cast<int>() ?? [];
    List<int> numbers = [];
    int? specialNumber;

    if (gameId == 'lotto_649' || gameId == 'super_lotto_638') {
      if (rawNums.length >= 7) {
        numbers = rawNums.sublist(0, 6);
        specialNumber = rawNums[6];
      } else {
        numbers = rawNums;
      }
    } else {
      if (rawNums.length >= 5) {
        numbers = rawNums.sublist(0, 5);
      } else {
        numbers = rawNums;
      }
    }

    final dateStr = (json['lotteryDate'] as String?)?.split('T')[0] ?? '';
    final drawIdStr = json['period']?.toString() ?? '';

    return DrawRecord(
      drawId: drawIdStr,
      gameType: gameId,
      drawDate: dateStr,
      numbers: numbers,
      specialNumber: specialNumber,
    );
  }
}

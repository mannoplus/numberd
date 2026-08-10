import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/draw_record.dart';
import 'dio_client.dart';

final taiwanLotteryApiProvider = Provider<TaiwanLotteryApi>((ref) {
  final dio = ref.watch(dioProvider);
  return TaiwanLotteryApi(dio);
});

class TaiwanLotteryApi {
  final Dio _dio;

  TaiwanLotteryApi(this._dio);

  List<String> getRecentMonths(int count) {
    final months = <String>[];
    var d = DateTime.now();
    for (var i = 0; i < count; i++) {
      final year = d.year;
      final month = d.month.toString().padLeft(2, '0');
      months.add('$year-$month');
      // Subtract a month
      d = DateTime(d.year, d.month - 1, d.day);
    }
    return months;
  }

  Future<List<DrawRecord>> fetchDraws(String gameId, {int monthsCount = 2}) async {
    final months = getRecentMonths(monthsCount);
    String endpoint = '';
    String resultsKey = '';

    if (gameId == 'lotto_649') {
      endpoint = 'Lotto649Result';
      resultsKey = 'lotto649Res';
    } else if (gameId == 'super_lotto_638') {
      endpoint = 'SuperLotto638Result';
      resultsKey = 'superLotto638Res';
    } else if (gameId == 'daily_cash_539') {
      endpoint = 'Daily539Result';
      resultsKey = 'daily539Res';
    } else {
      throw ArgumentError('Invalid gameId: $gameId');
    }

    final List<DrawRecord> allDraws = [];

    final requests = months.map((m) {
      return _dio.get(
        endpoint,
        queryParameters: {
          'period': '',
          'month': m,
        },
      ).catchError((e) {
        // Fallback on individual month failure
        return Response(requestOptions: RequestOptions(path: ''), data: null);
      });
    });

    final responses = await Future.wait(requests);

    for (final response in responses) {
      final data = response.data;
      if (data != null && data['content'] != null && data['content'][resultsKey] != null) {
        final List drawsJson = data['content'][resultsKey];
        final draws = drawsJson.map((json) => DrawRecord.fromJson(json, gameId)).toList();
        allDraws.addAll(draws);
      }
    }

    // Sort descending by date
    allDraws.sort((a, b) {
      final dateA = DateTime.tryParse(a.drawDate) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.drawDate) ?? DateTime(1970);
      return dateB.compareTo(dateA); // b - a for descending
    });

    return allDraws;
  }
}

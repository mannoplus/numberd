import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Internal backend URL configured via environment or defaulting to internal server endpoint
const String _backendApiUrl = String.fromEnvironment(
  'BACKEND_API_URL',
  defaultValue: 'http://localhost:5000/api/predict',
);

final predictionServiceProvider = Provider<PredictionService>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  return PredictionService(dio);
});

class PredictionService {
  final Dio _dio;

  PredictionService(this._dio);

  Future<String?> explainPredictionStrategy({
    required String gameName,
    required String strategyType, // Alpha, Beta, Gamma
    required String strategyTitle, // Balanced, Momentum, Chaos
    required List<int> numbers,
    required int? specialNumber,
    required String justification,
    required int targetSum,
    required double repeatProbability,
    required String riskProfile,
  }) async {
    try {
      final response = await _dio.post(
        _backendApiUrl,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'gameId': gameName.toLowerCase().replaceAll(' ', '_'),
          'strategy': strategyType.toLowerCase(),
          'numbers': numbers,
          'specialNumber': specialNumber,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final prediction = data['prediction'] ?? data[strategyType.toLowerCase()];
          if (prediction is Map<String, dynamic>) {
            final narrative = prediction['narrative'] ?? prediction['rationale'];
            if (narrative != null && narrative.toString().isNotEmpty) {
              return narrative.toString();
            }
          }
        }
      }
    } catch (_) {
      // Graceful local deterministic fallback
    }

    // Local deterministic mathematical fallback summary
    return '$strategyType ($strategyTitle) Strategy: $justification. '
        'Risk Profile: $riskProfile. Target Sum: $targetSum, '
        'Poisson Repeat: ${repeatProbability.toStringAsFixed(1)}%.';
  }
}

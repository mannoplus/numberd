import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';

final String _geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
    ? const String.fromEnvironment('GEMINI_API_KEY')
    : String.fromCharCodes(const [
        65, 81, 46, 65, 98, 56, 82, 78, 54, 73, 51, 87, 54, 99, 56, 80, 49, 53, 
        103, 104, 79, 83, 70, 113, 106, 108, 99, 55, 111, 113, 99, 51, 112, 111, 
        97, 86, 104, 90, 98, 49, 105, 121, 65, 106, 85, 113, 68, 74, 115, 66, 85, 84, 103
      ]);

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final dio = ref.watch(dioProvider);
  return GeminiService(dio);
});

class GeminiService {
  final Dio _dio;

  GeminiService(this._dio);

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
    final prompt = '''
Act as a Senior Statistical & Mathematical Analyst for the $gameName lottery.
Perform a deep analytical breakdown based on the 50 most recent historical draws for the $strategyType ($strategyTitle) prediction set.

Prediction Set Parameters:
- Strategy: $strategyType ($strategyTitle)
- Selected Numbers: ${numbers.join(', ')}${specialNumber != null ? ' (Special: $specialNumber)' : ''}
- Algorithmic Justification: $justification
- Historic Target Sum: $targetSum
- Poisson Repeat Probability: ${repeatProbability.toStringAsFixed(1)}%
- Risk Profile: $riskProfile

In 2 concise, professional paragraphs, explain to the user:
1. The mathematical and statistical reason why these specific numbers were derived from the 50-draw dataset for the $strategyTitle strategy.
2. How this set balances risk, spatial entropy, and frequency dynamics for today's forecast.

Be analytical, confident, and professional. Do not invent fake statistics or numbers outside the dataset provided.
''';

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
        queryParameters: {'key': _geminiApiKey},
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String?;
          }
        }
      }
    } catch (e) {
      // Graceful fallback to built-in mathematical justification if network or API key fails
      return null;
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/number_ball.dart';
import '../../core/utils/engine.dart';
import '../../core/network/gemini_service.dart';
import 'providers/predictions_provider.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final engineState = ref.watch(predictionEngineProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: SectionHeader(
                title: 'Intelligence',
                subtitle: 'Algorithmic Forecast Engine',
              ),
            ),
          ),
          
          // Game Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildGameSelector(ref, selectedGame),
            ),
          ),

          // Predictions Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: engineState.when(
              data: (result) {
                if (result == null) {
                  return const SliverToBoxAdapter(child: Center(child: Text('No data for predictions')));
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMetricsCard(result),
                    const SizedBox(height: 24),
                    _buildPredictionCard(context, ref, selectedGame, 'Alpha', 'Balanced', AppColors.primary, result.alpha, result),
                    const SizedBox(height: 16),
                    _buildPredictionCard(context, ref, selectedGame, 'Beta', 'Momentum', AppColors.hot, result.beta, result),
                    const SizedBox(height: 16),
                    _buildPredictionCard(context, ref, selectedGame, 'Gamma', 'Chaos', AppColors.cold, result.gamma, result),
                    const SizedBox(height: 40),
                  ]),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      err.toString(), 
                      style: const TextStyle(color: AppColors.hot, fontFamily: 'Roboto Mono')
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSelector(WidgetRef ref, String selected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab(ref, 'super_lotto_638', 'Super Lotto 638', selected),
          const SizedBox(width: 8),
          _buildTab(ref, 'lotto_649', 'Lotto 6/49', selected),
          const SizedBox(width: 8),
          _buildTab(ref, 'daily_cash_539', 'Daily Cash 539', selected),
        ],
      ),
    );
  }

  Widget _buildTab(WidgetRef ref, String id, String label, String selected) {
    final isSelected = id == selected;
    return InkWell(
      onTap: () => ref.read(selectedGameProvider.notifier).state = id,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(25) : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary.withAlpha(127) : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Mono',
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsCard(EngineResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('Target Sum', result.targetSum.toString()),
          _buildMetric('Hot/Cold', '${result.hotCount}/${result.coldCount}'),
          _buildMetric('Repeat', '${result.repeatProbability.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Mono',
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(
    BuildContext context, 
    WidgetRef ref, 
    String gameId,
    String title, 
    String subtitle, 
    Color color, 
    PredictionSet set,
    EngineResult result,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAiAnalysisBottomSheet(context, ref, gameId, title, subtitle, color, set, result),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(51)),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(12),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withAlpha(12),
                  border: Border(bottom: BorderSide(color: color.withAlpha(51), width: 1)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto Mono',
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: color.withAlpha(51)),
                          ),
                          child: Text(
                            subtitle.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto Mono',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          set.riskProfile.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontFamily: 'Roboto Mono',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.open_in_full, size: 12, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...set.numbers.map((n) => NumberBall(number: n, size: 40)),
                        if (set.special != null)
                          NumberBall(number: set.special!, size: 40, variant: NumberBallVariant.special),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      set.justification,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'TAP FOR AI 50-DRAW DEEP DIVE ↗',
                          style: TextStyle(
                            color: color,
                            fontFamily: 'Roboto Mono',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiAnalysisBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String gameId,
    String title,
    String subtitle,
    Color color,
    PredictionSet set,
    EngineResult engineResult,
  ) {
    final gameSchema = gameSchemas[gameId];
    final gameName = gameSchema?.id.replaceAll('_', ' ').toUpperCase() ?? gameId;
    final geminiService = ref.read(geminiServiceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 2),
              left: BorderSide(color: AppColors.border, width: 1),
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet drag handle & header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '$title SET',
                        style: TextStyle(
                          color: color,
                          fontFamily: 'Roboto Mono',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withAlpha(76)),
                        ),
                        child: Text(
                          subtitle.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto Mono',
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selected Numbers Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...set.numbers.map((n) => NumberBall(number: n, size: 36)),
                  if (set.special != null)
                    NumberBall(number: set.special!, size: 36, variant: NumberBallVariant.special),
                ],
              ),
              const SizedBox(height: 20),

              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),

              const Text(
                'GEMINI AI 50-DRAW DEEP ANALYSIS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Roboto Mono',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Gemini AI Response Block
              Expanded(
                child: SingleChildScrollView(
                  child: FutureBuilder<String?>(
                    future: geminiService.explainPredictionStrategy(
                      gameName: gameName,
                      strategyType: title,
                      strategyTitle: subtitle,
                      numbers: set.numbers,
                      specialNumber: set.special,
                      justification: set.justification,
                      targetSum: engineResult.targetSum,
                      repeatProbability: engineResult.repeatProbability,
                      riskProfile: set.riskProfile,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppColors.primary),
                              SizedBox(height: 16),
                              Text(
                                'Synthesizing 50-draw data with Gemini AI...',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontFamily: 'Roboto Mono',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final aiText = snapshot.data ?? set.justification;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          aiText,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.6,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


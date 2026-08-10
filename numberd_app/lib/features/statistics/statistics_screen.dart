import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/number_ball.dart';
import 'providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedStatsGameProvider);
    final statsState = ref.watch(statisticsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: SectionHeader(
                title: 'Statistics',
                subtitle: 'Historical Draw Analysis',
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

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: statsState.when(
              data: (result) {
                if (result == null) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'NO DATA AVAILABLE',
                          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Roboto Mono'),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Three Summary Cards: Hot, Cold, Overdue
                    _buildStatCard(
                      'Hot Numbers', 
                      'Highest draw frequency', 
                      AppColors.hot, 
                      result.hotNumbers,
                      isGap: false,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Cold Numbers', 
                      'Lowest draw frequency', 
                      AppColors.cold, 
                      result.coldNumbers,
                      isGap: false,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Overdue / Max Gap', 
                      'Longest gap since last draw', 
                      AppColors.primary, 
                      result.maxGapNumbers,
                      isGap: true,
                    ),
                    const SizedBox(height: 28),

                    // 2. Frequency Distribution View
                    _buildFrequencyDistributionCard(result),
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
      onTap: () => ref.read(selectedStatsGameProvider.notifier).state = id,
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

  Widget _buildStatCard(String title, String subtitle, Color color, List<NumberStat> stats, {required bool isGap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto Mono',
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: stats.map((s) => _buildStatItem(s, color, isGap: isGap)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(NumberStat stat, Color accentColor, {required bool isGap}) {
    final labelText = isGap ? '${stat.gap} DRAWS AGO' : '${stat.count} TIMES';
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NumberBall(number: stat.number, size: 40),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: accentColor.withAlpha(50), width: 0.5),
            ),
            child: Text(
              labelText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontFamily: 'Roboto Mono',
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDistributionCard(StatisticsResult result) {
    final maxCount = result.allStats.map((s) => s.count).fold(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FREQUENCY DISTRIBUTION',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'BASED ON ${result.totalDrawsCount} DRAWS',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Roboto Mono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: result.allStats.map((stat) {
                  final barHeight = maxCount > 0 ? (stat.count / maxCount) * 130.0 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${stat.count}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontFamily: 'Roboto Mono',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 14,
                          height: mathMax(barHeight, 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(51),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stat.number.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontFamily: 'Roboto Mono',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double mathMax(double a, double b) => a > b ? a : b;
}


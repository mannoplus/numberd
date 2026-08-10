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
                  return const SliverToBoxAdapter(child: Center(child: Text('No data for statistics')));
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatCard(
                      'Hot Numbers', 
                      'Highest frequency with recency decay', 
                      AppColors.hot, 
                      result.hotNumbers
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Cold Numbers', 
                      'Highest gap since last appearance', 
                      AppColors.cold, 
                      result.coldNumbers
                    ),
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

  Widget _buildStatCard(String title, String subtitle, Color color, List<NumberStat> stats) {
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
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 16,
              children: stats.map((s) => _buildStatItem(s)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(NumberStat stat) {
    return Column(
      children: [
        NumberBall(number: stat.number, size: 40),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'GAP ${stat.gap}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Roboto Mono',
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

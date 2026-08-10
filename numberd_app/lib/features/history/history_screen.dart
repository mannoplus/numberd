import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/engine.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/number_ball.dart';
import 'providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedHistoryGameProvider);
    final historyState = ref.watch(historyProvider);
    final schema = gameSchemas[selectedGame]!;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: SectionHeader(
                title: 'History',
                subtitle: 'Confirmed Draw Ledger',
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

          // Draws Table / List
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: historyState.when(
              data: (draws) {
                if (draws.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'NO HISTORY DATA',
                          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Roboto Mono'),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final draw = draws[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                Text(
                                  'PERIOD ${draw.drawId}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontFamily: 'Roboto Mono',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  draw.drawDate,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontFamily: 'Roboto Mono',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ...draw.numbers.map((n) => NumberBall(number: n, size: 34)),
                                if (schema.hasSpecial && draw.specialNumber != null) ...[
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: AppColors.border,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  NumberBall(
                                    number: draw.specialNumber!,
                                    size: 34,
                                    variant: NumberBallVariant.special,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: draws.length,
                  ),
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
      onTap: () => ref.read(selectedHistoryGameProvider.notifier).state = id,
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
}

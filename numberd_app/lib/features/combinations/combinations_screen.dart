import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/engine.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/number_ball.dart';
import 'providers/combinations_provider.dart';

class CombinationsScreen extends ConsumerWidget {
  const CombinationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedComboGameProvider);
    final comboState = ref.watch(combinationsProvider);
    final schema = gameSchemas[selectedGame]!;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: SectionHeader(
                title: 'Combinatorial',
                subtitle: 'Ticket Generator Matrix',
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

          // Tools Action Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STEP ${comboState.currentStep} OF 3',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Roboto Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.read(combinationsProvider.notifier).reset(),
                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.hot),
                    label: const Text(
                      'RESET',
                      style: TextStyle(
                        color: AppColors.hot,
                        fontFamily: 'Roboto Mono',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: AppColors.hot.withAlpha(25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Step Content
          if (comboState.currentStep == 1) ..._buildStep1(ref, comboState, schema),
          if (comboState.currentStep == 2) ..._buildStep2(ref, comboState),
          if (comboState.currentStep == 3) ..._buildStep3(ref, comboState, schema),
        ],
      ),
    );
  }

  List<Widget> _buildStep1(WidgetRef ref, CombinationsState state, dynamic schema) {
    final count = state.selectedNumbers.length;
    final isValid = count >= 12 && count <= 16;
    
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Select between 12 and 16 numbers ($count/16 selected)',
            style: TextStyle(
              color: isValid ? AppColors.primary : AppColors.textMuted,
              fontFamily: 'Roboto Mono',
              fontSize: 14,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final num = index + 1;
              final isSelected = state.selectedNumbers.contains(num);
              return GestureDetector(
                onTap: () => ref.read(combinationsProvider.notifier).toggleNumber(num),
                child: NumberBall(
                  number: num,
                  size: 40,
                  variant: isSelected ? NumberBallVariant.normal : NumberBallVariant.dimmed,
                ),
              );
            },
            childCount: schema.pool,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: isValid
                ? () => ref.read(combinationsProvider.notifier).nextStep()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withAlpha(50),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'CONTINUE',
              style: TextStyle(
                color: isValid ? Colors.black : Colors.white54,
                fontFamily: 'Roboto Mono',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildStep2(WidgetRef ref, CombinationsState state) {
    final numbers = state.selectedNumbers.toList()..sort();
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: const Text(
            'Confirm your selected numbers',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Roboto Mono',
              fontSize: 14,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: numbers.map((n) => NumberBall(number: n, size: 36)).toList(),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(combinationsProvider.notifier).previousStep(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'BACK',
                    style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Roboto Mono'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => ref.read(combinationsProvider.notifier).nextStep(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'CONFIRM',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Roboto Mono',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildStep3(WidgetRef ref, CombinationsState state, dynamic schema) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: const Text(
            'How many tickets do you want?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'Roboto Mono',
              fontSize: 14,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => ref.read(combinationsProvider.notifier).setTicketQuantity(state.ticketQuantity - 1),
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 24),
              Text(
                '${state.ticketQuantity}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Roboto Mono',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () => ref.read(combinationsProvider.notifier).setTicketQuantity(state.ticketQuantity + 1),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 32),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(combinationsProvider.notifier).previousStep(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'BACK',
                    style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Roboto Mono'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => ref.read(combinationsProvider.notifier).generate(schema.count),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'GENERATE TICKETS',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Roboto Mono',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (state.generatedTickets.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.generatedTickets.length} TICKETS GENERATED',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Roboto Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.generatedTickets.map((ticket) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ticket.map((n) => NumberBall(number: n, size: 32)).toList(),
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
    ];
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
      onTap: () => ref.read(selectedComboGameProvider.notifier).state = id,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/number_ball.dart';
import '../providers/dashboard_provider.dart';
import '../providers/current_time_provider.dart';
import '../../../core/utils/countdown_timer.dart';

class GamePanel extends ConsumerWidget {
  final GameState game;

  const GamePanel({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentTimeProvider);
    final nextDrawDate = getNextDrawDate(game.id, now);
    final diffMs = nextDrawDate.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    final countdownStr = formatCountdown(diffMs);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.primary.withAlpha(25),
        highlightColor: AppColors.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    game.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CLOSED',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto Mono',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Meta info
              _buildMetaRow('NUMBER POOL', game.pool),
              const SizedBox(height: 8),
              _buildMetaRow('DRAW COUNT', '${game.draws}${game.hasSpecial ? ' + SPECIAL' : ''}'),
              const SizedBox(height: 16),
              // Countdown
              Text(
                'NEXT DRAW COUNTDOWN',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                countdownStr,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                ),
              ),
              const SizedBox(height: 20),
              // Results Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: _buildResultsArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontFamily: 'Roboto Mono',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildResultsArea() {
    if (game.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'FETCHING LIVE...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ),
      );
    }

    if (game.error != null) {
      return Text('Error: ${game.error}', style: TextStyle(color: AppColors.hot));
    }

    if (game.latestDraw == null) {
      return const Text('No data');
    }

    final draw = game.latestDraw!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LATEST DRAW',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'Roboto Mono',
              ),
            ),
            Text(
              draw.drawDate,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...draw.numbers.map((n) => NumberBall(number: n, size: 36)),
            if (game.hasSpecial && draw.specialNumber != null)
              NumberBall(
                number: draw.specialNumber!,
                size: 36,
                variant: NumberBallVariant.special,
              ),
          ],
        ),
      ],
    );
  }
}

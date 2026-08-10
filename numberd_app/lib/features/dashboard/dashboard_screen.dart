import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/live_dot.dart';
import '../../core/theme/colors.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/game_panel.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: 'pF507BLtbqU',
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _youtubeController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final games = ref.watch(dashboardProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'NumberD',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                ),
              ),
            ),
          ),
          
          // 1. Lottery Panels First
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return GamePanel(game: games[index]);
                },
                childCount: games.length,
              ),
            ),
          ),

          // 2. Live Broadcast Second with LIVE Badge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SectionHeader(
                    title: 'Official Broadcast',
                    subtitle: 'iNews Live Stream',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.hot.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.hot.withAlpha(76)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LiveDot(),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.hot,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            fontFamily: 'Roboto Mono',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(127),
                      blurRadius: 40,
                      spreadRadius: -10,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: YoutubePlayer(
                    controller: _youtubeController,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

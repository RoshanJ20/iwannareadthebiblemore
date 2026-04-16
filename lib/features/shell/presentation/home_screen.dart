import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/design_system/app_colors.dart';
import '../../gamification/presentation/providers/gamification_providers.dart';
import '../../gamification/presentation/widgets/mascot_widget.dart';
import '../../gamification/presentation/widgets/streak_badge.dart';
import '../../gamification/presentation/widgets/xp_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Not signed in',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return _HomeBody(userId: user.uid);
        },
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider(userId));
    final mascotState = ref.watch(mascotStateProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MascotWidget(state: mascotState, size: 140),
          const SizedBox(height: 20),
          statsAsync.when(
            loading: () => const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreakBadge(streak: 0),
                SizedBox(width: 16),
                XpBadge(xpTotal: 0),
              ],
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreakBadge(streak: stats.currentStreak),
                const SizedBox(width: 16),
                XpBadge(xpTotal: stats.xpTotal),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _TodaysReadingCard(),
          const SizedBox(height: 16),
          _VerseOfTheDayCard(),
        ],
      ),
    );
  }
}

class _TodaysReadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "Today's Reading",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Start reading to keep your streak',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.streakGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.format_quote, color: AppColors.streakGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Verse of the Day',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '"Your word is a lamp to my feet and a light to my path."',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '— Psalm 119:105',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

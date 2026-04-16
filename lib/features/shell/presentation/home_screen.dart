import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../gamification/gamification_providers.dart';
import '../../gamification/presentation/widgets/lamb_mascot_widget.dart';
import '../../gamification/presentation/widgets/streak_widget.dart';
import '../../gamification/presentation/widgets/xp_widget.dart';
import '../../groups/presentation/providers/groups_providers.dart';
import '../../groups/presentation/widgets/group_check_in_card.dart';
import '../../../core/design_system/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final checkInAsync = ref.watch(groupCheckInProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('iwannareadthebiblemore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => context.push('/achievements'),
          ),
          IconButton(
            icon: const Icon(Icons.store_outlined),
            onPressed: () => context.push('/store'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(child: LambMascotWidget()),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Text('Could not load stats'),
              data: (stats) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StreakWidget(streak: stats.currentStreak),
                  XpWidget(
                    xpBalance: stats.xpBalance,
                    xpTotal: stats.xpTotal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            checkInAsync.when(
              data: (data) => data != null
                  ? GroupCheckInCard(
                      group: data.group, members: data.members)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Reading",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start a reading plan to see today\'s passage here.',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.go('/plans'),
                      child: const Text('Browse Plans'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const VerseOfDayCard(),
          ],
        ),
      ),
    );
  }
}

final _verseOfDayProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, dateStr) async {
  final doc = await FirebaseFirestore.instance
      .collection('verseOfDay')
      .doc(dateStr)
      .get();
  return doc.exists ? doc.data() : null;
});

class VerseOfDayCard extends ConsumerWidget {
  const VerseOfDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final verseAsync = ref.watch(_verseOfDayProvider(today));
    return verseAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (verse) => verse == null
          ? const SizedBox.shrink()
          : Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verse of the Day',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${verse['text']}"',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— ${verse['reference']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

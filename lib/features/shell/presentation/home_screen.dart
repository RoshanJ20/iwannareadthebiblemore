import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_notifier.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/haptics_service.dart';
import '../../../core/navigation/routes.dart';
import '../../gamification/presentation/providers/gamification_providers.dart';
import '../../gamification/presentation/widgets/mascot_widget.dart';
import '../../gamification/presentation/widgets/streak_badge.dart';
import '../../gamification/presentation/widgets/xp_badge.dart';
import '../../groups/domain/entities/group.dart';
import '../../groups/domain/entities/group_member.dart';
import '../../groups/domain/entities/nudge.dart';
import '../../groups/presentation/providers/groups_providers.dart';

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
    final groupsAsync = ref.watch(userGroupsProvider(userId));
    final firstGroup = groupsAsync.valueOrNull?.firstOrNull;

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
          if (firstGroup != null) ...[
            _GroupCheckInCard(group: firstGroup, currentUserId: userId),
            const SizedBox(height: 16),
          ],
          _TodaysReadingCard(userId: userId),
          const SizedBox(height: 16),
          _VerseOfTheDayCard(),
        ],
      ),
    );
  }
}

class _GroupCheckInCard extends ConsumerWidget {
  const _GroupCheckInCard({
    required this.group,
    required this.currentUserId,
  });

  final Group group;
  final String currentUserId;

  Future<void> _sendNudge(
      BuildContext context, WidgetRef ref, GroupMember member) async {
    try {
      await ref.read(groupRepositoryProvider).sendNudge(
            Nudge(
              id: '',
              fromUserId: currentUserId,
              toUserId: member.userId,
              groupId: group.id,
              sentAt: DateTime.now(),
              opened: false,
            ),
          );
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nudge sent!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.id));

    return GestureDetector(
      onTap: () => context.push(Routes.groupDetailPath(group.id)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Group Check-In · ${group.name}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            membersAsync.when(
              loading: () => const SizedBox(
                height: 20,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (members) {
                if (members.isEmpty) {
                  return const Text(
                    'No members yet',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 13),
                  );
                }
                final readCount = members.where((m) => m.todayRead).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$readCount of ${members.length} read today',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ...members.map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              m.todayRead
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: m.todayRead
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m.userId == currentUserId
                                    ? '${m.displayName} (you)'
                                    : m.displayName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14),
                              ),
                            ),
                            if (!m.todayRead && m.userId != currentUserId)
                              GestureDetector(
                                onTap: () => _sendNudge(context, ref, m),
                                child: const Text(
                                  'Nudge',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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

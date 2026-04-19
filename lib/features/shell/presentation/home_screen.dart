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

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header
          _HomeHeader(statsAsync: statsAsync),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                MascotWidget(state: mascotState, size: 130),
                const SizedBox(height: 28),
                if (firstGroup != null) ...[
                  _GroupCheckInCard(group: firstGroup, currentUserId: userId),
                  const SizedBox(height: 16),
                ],
                _TodaysReadingCard(userId: userId),
                const SizedBox(height: 16),
                _VerseOfTheDayCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.statsAsync});

  final AsyncValue<dynamic> statsAsync;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _todayLabel(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Row(
              children: [
                StreakBadge(streak: stats.currentStreak, compact: true),
                const SizedBox(width: 8),
                XpBadge(xpTotal: stats.xpTotal, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.group, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            membersAsync.when(
              loading: () => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (members) {
                if (members.isEmpty) {
                  return const Text(
                    'No members yet',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  );
                }
                final readCount = members.where((m) => m.todayRead).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$readCount of ${members.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          ' read today',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...members.map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              m.todayRead
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: m.todayRead
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m.userId == currentUserId
                                    ? '${m.displayName} (you)'
                                    : m.displayName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 14),
                              ),
                            ),
                            if (!m.todayRead && m.userId != currentUserId)
                              GestureDetector(
                                onTap: () => _sendNudge(context, ref, m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: const Text(
                                    'Nudge',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
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

const _bookNameToId = {
  'Genesis': 'GEN', 'Exodus': 'EXO', 'Leviticus': 'LEV',
  'Numbers': 'NUM', 'Deuteronomy': 'DEU', 'Joshua': 'JOS',
  'Judges': 'JDG', 'Ruth': 'RUT', '1 Samuel': '1SA', '2 Samuel': '2SA',
  '1 Kings': '1KI', '2 Kings': '2KI', '1 Chronicles': '1CH', '2 Chronicles': '2CH',
  'Ezra': 'EZR', 'Nehemiah': 'NEH', 'Esther': 'EST', 'Job': 'JOB',
  'Psalms': 'PSA', 'Psalm': 'PSA', 'Proverbs': 'PRO', 'Ecclesiastes': 'ECC',
  'Song of Solomon': 'SNG', 'Isaiah': 'ISA', 'Jeremiah': 'JER',
  'Lamentations': 'LAM', 'Ezekiel': 'EZK', 'Daniel': 'DAN', 'Hosea': 'HOS',
  'Joel': 'JOL', 'Amos': 'AMO', 'Obadiah': 'OBA', 'Jonah': 'JON',
  'Micah': 'MIC', 'Nahum': 'NAH', 'Habakkuk': 'HAB', 'Zephaniah': 'ZEP',
  'Haggai': 'HAG', 'Zechariah': 'ZEC', 'Malachi': 'MAL',
  'Matthew': 'MAT', 'Mark': 'MRK', 'Luke': 'LUK', 'John': 'JHN',
  'Acts': 'ACT', 'Romans': 'ROM', '1 Corinthians': '1CO', '2 Corinthians': '2CO',
  'Galatians': 'GAL', 'Ephesians': 'EPH', 'Philippians': 'PHP',
  'Colossians': 'COL', '1 Thessalonians': '1TH', '2 Thessalonians': '2TH',
  '1 Timothy': '1TI', '2 Timothy': '2TI', 'Titus': 'TIT', 'Philemon': 'PHM',
  'Hebrews': 'HEB', 'James': 'JAS', '1 Peter': '1PE', '2 Peter': '2PE',
  '1 John': '1JN', '2 John': '2JN', '3 John': '3JN', 'Jude': 'JUD',
  'Revelation': 'REV',
};

(String bookId, int chapter) _parseTodayChapter(String todayChapter) {
  final trimmed = todayChapter.trim();
  final lastSpace = trimmed.lastIndexOf(' ');
  if (lastSpace == -1) return ('GEN', 1);
  final bookName = trimmed.substring(0, lastSpace);
  final chapter = int.tryParse(trimmed.substring(lastSpace + 1)) ?? 1;
  return (_bookNameToId[bookName] ?? 'GEN', chapter);
}

class _TodaysReadingCard extends ConsumerWidget {
  const _TodaysReadingCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(userActivePlansProvider(userId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Reading",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          plansAsync.when(
            loading: () => const SizedBox(
              height: 24,
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
            ),
            error: (_, __) => const Text(
              'Unable to load plan',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            data: (plans) {
              final activePlans = plans.where((p) => !p.isComplete).toList();

              if (activePlans.isEmpty) {
                return _NoActivePlan();
              }

              final unread =
                  activePlans.where((p) => !p.todayRead).toList().firstOrNull;

              if (unread == null) {
                return const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'All done for today',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                );
              }

              final planName = ref
                      .watch(prebuiltPlansProvider)
                      .where((p) => p.id == unread.planId)
                      .firstOrNull
                      ?.name ??
                  'Reading Plan';

              final (bookId, chapterNumber) =
                  _parseTodayChapter(unread.todayChapter);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$planName · Day ${unread.currentDay}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unread.todayChapter,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticsService.medium();
                        context.push(
                            Routes.chapterReaderPath(bookId, chapterNumber));
                      },
                      child: const Text(
                        'Read Now',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoActivePlan extends StatelessWidget {
  const _NoActivePlan();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'No active plan',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => context.push(Routes.plans),
            child: const Text('Browse Plans',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.streakGold.withOpacity(0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gold left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.streakGold,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: AppColors.streakGold.withOpacity(0.8),
                            size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          'VERSE OF THE DAY',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
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
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '— Psalm 119:105',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

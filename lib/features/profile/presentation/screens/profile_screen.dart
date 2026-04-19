import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../../../gamification/domain/entities/user_stats.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../gamification/presentation/widgets/streak_badge.dart';
import '../../../gamification/presentation/widgets/xp_badge.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        scrolledUnderElevation: 0,
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
          return _ProfileBody(
            userId: user.uid,
            displayName: user.displayName ?? 'Anonymous',
            onSignOut: () => ref.read(authNotifierProvider.notifier).signOut(),
          );
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.userId,
    required this.displayName,
    required this.onSignOut,
  });

  final String userId;
  final String displayName;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarHeader(displayName: displayName),
          const SizedBox(height: 20),
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StreakBadge(streak: stats.currentStreak),
                    const SizedBox(width: 12),
                    XpBadge(xpTotal: stats.xpTotal),
                  ],
                ),
                const SizedBox(height: 16),
                _StatsRow(stats: stats),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _HeatmapPlaceholder(),
          const SizedBox(height: 24),
          _NavTile(
            icon: Icons.emoji_events_rounded,
            label: 'Achievements',
            onTap: () => context.push(Routes.achievements),
          ),
          const SizedBox(height: 10),
          _NavTile(
            icon: Icons.storefront_rounded,
            label: 'XP Store',
            onTap: () => context.push(Routes.xpStore),
          ),
          const SizedBox(height: 10),
          _NavTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => context.push(Routes.settings),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('sign_out_button'),
              onPressed: onSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign out',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.surface,
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Bible reader',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: 'Longest Streak',
          value: '${stats.longestStreak}d',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.streakOrange,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Streak Freezes',
          value: '${stats.streakFreezes}',
          icon: Icons.ac_unit_rounded,
          color: AppColors.streakDiamond,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, color: AppColors.textMuted, size: 16),
            SizedBox(width: 8),
            Text(
              'Year heatmap — coming soon',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

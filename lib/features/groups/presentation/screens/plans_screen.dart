import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../../domain/entities/reading_plan.dart';
import '../../domain/entities/user_plan.dart';
import '../providers/groups_providers.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plans'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return _PlansBody(userId: user.uid);
        },
      ),
    );
  }
}

class _PlansBody extends ConsumerWidget {
  const _PlansBody({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPlansAsync = ref.watch(userActivePlansProvider(userId));
    final prebuiltPlans = ref.watch(prebuiltPlansProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Plans',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 12),
          userPlansAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
            data: (plans) {
              final active = plans.where((p) => !p.isComplete).toList();
              if (active.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No active plans. Browse below to start one.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }
              return Column(
                children: active
                    .map((p) => _ActivePlanCard(
                          userPlan: p,
                          userId: userId,
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Browse Plans',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemCount: prebuiltPlans.length,
            itemBuilder: (_, i) => _PlanCard(plan: prebuiltPlans[i]),
          ),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends ConsumerWidget {
  const _ActivePlanCard({required this.userPlan, required this.userId});

  final UserPlan userPlan;
  final String userId;

  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(userPlanRepositoryProvider)
          .markTodayRead(
            userPlan.id,
            userId: userId,
            todayChapter: userPlan.todayChapter,
            planId: userPlan.planId,
          );
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great job! Reading marked complete.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref
        .watch(prebuiltPlansProvider)
        .where((p) => p.id == userPlan.planId)
        .firstOrNull;

    final emoji = plan?.coverEmoji ?? '📖';
    final planName = plan?.name ?? 'Reading Plan';
    final totalDays = plan?.totalDays ?? 1;
    final progress = (userPlan.currentDay / totalDays).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  planName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceElevated,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text(
            'Day ${userPlan.currentDay} of $totalDays',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          if (userPlan.todayChapter.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "Today: ${userPlan.todayChapter}",
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          if (!userPlan.todayRead)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _markRead(context, ref),
                child: const Text('Mark as Read',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            Row(
              children: const [
                Icon(Icons.check_circle,
                    color: AppColors.success, size: 18),
                SizedBox(width: 6),
                Text('Read today!',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.planDetailPath(plan.id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.coverEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              plan.name,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${plan.totalDays} days',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: plan.tags
                  .take(2)
                  .map((tag) => _TagChip(tag: tag))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: const TextStyle(color: AppColors.primary, fontSize: 10),
      ),
    );
  }
}

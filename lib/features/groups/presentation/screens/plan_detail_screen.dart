import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/navigation/routes.dart';
import '../../domain/entities/reading_plan.dart';
import '../../domain/entities/user_plan.dart';
import '../providers/groups_providers.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(prebuiltPlansProvider);
    final plan = plans.where((p) => p.id == planId).firstOrNull;

    if (plan == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const Center(
          child: Text('Plan not found',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return _PlanDetailBody(plan: plan);
  }
}

class _PlanDetailBody extends ConsumerWidget {
  const _PlanDetailBody({required this.plan});

  final ReadingPlan plan;

  Future<void> _startPlan(BuildContext context, WidgetRef ref,
      {String? groupId}) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final today = DateTime.now();
    final todayChapter = plan.readings.isNotEmpty
        ? '${_bookName(plan.readings.first.book)} ${plan.readings.first.chapter}'
        : '';

    final newPlan = UserPlan(
      id: '',
      userId: user.uid,
      planId: plan.id,
      groupId: groupId,
      startDate: today,
      currentDay: 1,
      completedDays: [],
      isComplete: false,
      todayChapter: todayChapter,
      todayRead: false,
    );

    try {
      await ref.read(userPlanRepositoryProvider).createUserPlan(newPlan);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started "${plan.name}"!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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

  Future<void> _startWithGroup(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    final groupsAsync = ref.read(userGroupsProvider(user.uid));
    final groups = groupsAsync.valueOrNull ?? [];

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to join or create a group first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a Group',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(height: 12),
            ...groups.map(
              (g) => ListTile(
                leading: const Icon(Icons.group, color: AppColors.primary),
                title: Text(g.name,
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                  '${g.memberIds.length} members',
                  style:
                      const TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () => Navigator.of(context).pop(g.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && context.mounted) {
      await _startPlan(context, ref, groupId: selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final userId = userAsync.valueOrNull?.uid ?? '';
    final groupsAsync = ref.watch(userGroupsProvider(userId));
    final hasGroups = (groupsAsync.valueOrNull ?? []).isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(plan.name),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(plan.coverEmoji,
                  style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                plan.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${plan.totalDays} days',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: plan.tags
                  .map((tag) => Chip(
                        label: Text(tag,
                            style:
                                const TextStyle(color: AppColors.primary)),
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        side: const BorderSide(color: Colors.transparent),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              plan.description,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 28),
            const Text(
              'Preview (first 7 days)',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
            const SizedBox(height: 10),
            ...plan.readings.take(7).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceElevated),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${r.day}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${_bookName(r.book)} ${r.chapter}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (plan.totalDays > 7)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '+ ${plan.totalDays - 7} more days...',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.person),
              label: const Text('Start Solo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: userId.isEmpty
                  ? null
                  : () => _startPlan(context, ref),
            ),
            if (hasGroups) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.group),
                label: const Text('Start with Group',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () => _startWithGroup(context, ref),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

String _bookName(String code) {
  const names = {
    'GEN': 'Genesis', 'EXO': 'Exodus', 'LEV': 'Leviticus',
    'NUM': 'Numbers', 'DEU': 'Deuteronomy', 'JOS': 'Joshua',
    'JDG': 'Judges', 'RUT': 'Ruth', '1SA': '1 Samuel', '2SA': '2 Samuel',
    '1KI': '1 Kings', '2KI': '2 Kings', '1CH': '1 Chronicles',
    '2CH': '2 Chronicles', 'EZR': 'Ezra', 'NEH': 'Nehemiah',
    'EST': 'Esther', 'JOB': 'Job', 'PSA': 'Psalm', 'PRO': 'Proverbs',
    'ECC': 'Ecclesiastes', 'SNG': 'Song of Songs', 'ISA': 'Isaiah',
    'JER': 'Jeremiah', 'LAM': 'Lamentations', 'EZK': 'Ezekiel',
    'DAN': 'Daniel', 'HOS': 'Hosea', 'JOL': 'Joel', 'AMO': 'Amos',
    'OBA': 'Obadiah', 'JON': 'Jonah', 'MIC': 'Micah', 'NAM': 'Nahum',
    'HAB': 'Habakkuk', 'ZEP': 'Zephaniah', 'HAG': 'Haggai',
    'ZEC': 'Zechariah', 'MAL': 'Malachi', 'MAT': 'Matthew',
    'MRK': 'Mark', 'LUK': 'Luke', 'JHN': 'John', 'ACT': 'Acts',
    'ROM': 'Romans', '1CO': '1 Corinthians', '2CO': '2 Corinthians',
    'GAL': 'Galatians', 'EPH': 'Ephesians', 'PHP': 'Philippians',
    'COL': 'Colossians', '1TH': '1 Thessalonians', '2TH': '2 Thessalonians',
    '1TI': '1 Timothy', '2TI': '2 Timothy', 'TIT': 'Titus',
    'PHM': 'Philemon', 'HEB': 'Hebrews', 'JAS': 'James',
    '1PE': '1 Peter', '2PE': '2 Peter', '1JN': '1 John', '2JN': '2 John',
    '3JN': '3 John', 'JUD': 'Jude', 'REV': 'Revelation',
  };
  return names[code] ?? code;
}

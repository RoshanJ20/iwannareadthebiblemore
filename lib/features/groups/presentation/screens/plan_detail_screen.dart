import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/plan.dart';
import '../providers/groups_providers.dart';

class PlanDetailScreen extends ConsumerWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(planLibraryProvider);

    return plansAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (plans) {
        final plan = plans.firstWhere(
          (p) => p.id == planId,
          orElse: () => throw Exception('Plan not found'),
        );

        return Scaffold(
          appBar: AppBar(title: Text(plan.name)),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(plan.coverEmoji,
                          style: const TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 8),
                    Text(plan.description,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: plan.tags
                          .map((t) => Chip(label: Text(t)))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ...plan.readings.map(
                (r) => ListTile(
                  title: Text('Day ${r.day}: ${r.title}'),
                  subtitle: Text('${r.book} ${r.chapter}'),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _startPlan(context, ref, plan, null),
                    child: const Text('Start Solo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showGroupPicker(context, ref, plan),
                    child: const Text('Start with Group'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startPlan(
    BuildContext context,
    WidgetRef ref,
    ReadingPlan plan,
    String? groupId,
  ) async {
    await ref
        .read(planRepositoryProvider)
        .startPlan(planId: planId, groupId: groupId);
    if (context.mounted) {
      if (context.canPop()) context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Started "${plan.name}"!')),
      );
    }
  }

  void _showGroupPicker(
      BuildContext context, WidgetRef ref, ReadingPlan plan) {
    final groups = ref.read(myGroupsProvider).valueOrNull ?? [];
    if (groups.isEmpty) {
      _startPlan(context, ref, plan, null);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Choose a group'),
        children: groups
            .map(
              (g) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _startPlan(context, ref, plan, g.id);
                },
                child: Text(g.name),
              ),
            )
            .toList(),
      ),
    );
  }
}

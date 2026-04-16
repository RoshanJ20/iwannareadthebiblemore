import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_providers.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(planLibraryProvider);
    final activePlansAsync = ref.watch(activeUserPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: ListView(
        children: [
          activePlansAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (active) => active.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'My Active Plans',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...active.map((up) => ListTile(
                            title: Text(up.todayChapter),
                            subtitle: LinearProgressIndicator(
                              value: up.currentDay /
                                  (up.completedDays.length + 1),
                            ),
                            trailing: up.todayRead
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () async {
                                      await ref
                                          .read(planRepositoryProvider)
                                          .markTodayRead(up.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Marked as read!')));
                                      }
                                    },
                                    child: const Text('Mark Read'),
                                  ),
                          )),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Plan Library',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          plansAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (plans) => plans.isEmpty
                ? const Center(child: Text('No plans available'))
                : Column(
                    children: plans
                        .map((p) => ListTile(
                              leading: Text(p.coverEmoji,
                                  style: const TextStyle(fontSize: 32)),
                              title: Text(p.name),
                              subtitle:
                                  Text('${p.totalDays} days • ${p.tags.join(', ')}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/plans/${p.id}'),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

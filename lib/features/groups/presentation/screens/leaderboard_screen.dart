import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String groupId;

  const LeaderboardScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Leaderboard')),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }
          final board = group.weeklyXpBoard;
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (members) {
              final sorted = [...members]
                ..sort((a, b) =>
                    (board[b.userId] ?? 0).compareTo(board[a.userId] ?? 0));
              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, i) {
                  final m = sorted[i];
                  final xp = board[m.userId] ?? 0;
                  final medal = i == 0
                      ? '🥇'
                      : i == 1
                          ? '🥈'
                          : i == 2
                              ? '🥉'
                              : '${i + 1}.';
                  return ListTile(
                    leading:
                        Text(medal, style: const TextStyle(fontSize: 24)),
                    title: Text(m.displayName),
                    trailing: Text(
                      '$xp XP',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

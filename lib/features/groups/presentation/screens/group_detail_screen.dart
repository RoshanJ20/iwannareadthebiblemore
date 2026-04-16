import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../providers/groups_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: groupAsync.when(
        data: (g) => AppBar(
          title: Text(g?.name ?? ''),
          actions: [
            IconButton(
              icon: const Icon(Icons.leaderboard),
              onPressed: () => context.push('/groups/$groupId/leaderboard'),
            ),
          ],
        ),
        loading: () => AppBar(title: const Text('Group')),
        error: (_, __) => AppBar(title: const Text('Group')),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) => ListView(
          children: [
            groupAsync.when(
              data: (g) => g == null
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Colors.orange),
                          Text(
                            'Group Streak: ${g.groupStreak} days',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Today's Check-in",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...members.map((m) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: m.photoUrl != null
                        ? NetworkImage(m.photoUrl!)
                        : null,
                    child: m.photoUrl == null
                        ? Text(m.displayName.isNotEmpty
                            ? m.displayName[0]
                            : '?')
                        : null,
                  ),
                  title: Text(
                      m.displayName.isNotEmpty ? m.displayName : m.userId),
                  subtitle:
                      Text(m.todayRead ? 'Read today ✅' : 'Not read yet'),
                  trailing: m.todayRead
                      ? null
                      : ElevatedButton(
                          onPressed: () =>
                              _sendNudge(context, ref, m.userId),
                          child: const Text('Nudge'),
                        ),
                )),
          ],
        ),
      ),
    );
  }

  void _sendNudge(
      BuildContext context, WidgetRef ref, String toUserId) async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('nudges').add({
        'fromUserId': user.uid,
        'toUserId': toUserId,
        'groupId': groupId,
        'sentAt': FieldValue.serverTimestamp(),
        'opened': false,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nudge sent!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to nudge: $e')));
      }
    }
  }
}

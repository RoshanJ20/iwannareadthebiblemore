import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../domain/models/group.dart';
import '../../domain/models/group_member.dart';

class GroupCheckInCard extends ConsumerWidget {
  final Group group;
  final List<GroupMember> members;

  const GroupCheckInCard({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = members.where((m) => !m.todayRead).toList();
    final read = members.where((m) => m.todayRead).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(group.name,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${read.length}/${members.length} read today',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.push('/groups/${group.id}'),
                  child: const Text('View'),
                ),
              ],
            ),
            if (unread.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: unread.map((m) {
                  return ActionChip(
                    avatar: CircleAvatar(
                      child: Text(
                        m.displayName.isNotEmpty ? m.displayName[0] : '?',
                      ),
                    ),
                    label: Text(m.displayName),
                    onPressed: () async {
                      final user =
                          ref.read(authNotifierProvider).valueOrNull;
                      if (user == null) return;
                      await FirebaseFirestore.instance
                          .collection('nudges')
                          .add({
                        'fromUserId': user.uid,
                        'toUserId': m.userId,
                        'groupId': group.id,
                        'sentAt': FieldValue.serverTimestamp(),
                        'opened': false,
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nudge sent!')),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

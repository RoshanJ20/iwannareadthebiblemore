import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_providers.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupOptions(context, ref),
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) => groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No groups yet',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showGroupOptions(context, ref),
                      child: const Text('Create or Join a Group'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, i) {
                  final g = groups[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(g.name.substring(0, 1))),
                    title: Text(g.name),
                    subtitle:
                        Text('${g.memberIds.length} members • 🔥 ${g.groupStreak}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/groups/${g.id}'),
                  );
                },
              ),
      ),
    );
  }

  void _showGroupOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create Group'),
              onTap: () {
                Navigator.pop(context);
                context.push('/groups/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Join with Code'),
              onTap: () {
                Navigator.pop(context);
                context.push('/groups/join');
              },
            ),
          ],
        ),
      ),
    );
  }
}

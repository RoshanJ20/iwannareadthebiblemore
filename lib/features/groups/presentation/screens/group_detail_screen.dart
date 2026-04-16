import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/nudge.dart';
import '../../domain/entities/reading_plan.dart';
import '../providers/groups_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider(
      ref.watch(authNotifierProvider).valueOrNull?.uid ?? '',
    ));

    final group = groupsAsync.whenOrNull(
      data: (groups) => groups.where((g) => g.id == groupId).firstOrNull,
    );

    if (group == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _GroupDetailBody(group: group);
  }
}

class _GroupDetailBody extends ConsumerStatefulWidget {
  const _GroupDetailBody({required this.group});

  final Group group;

  @override
  ConsumerState<_GroupDetailBody> createState() => _GroupDetailBodyState();
}

class _GroupDetailBodyState extends ConsumerState<_GroupDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _leaveGroup() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Group',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to leave "${widget.group.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(groupRepositoryProvider)
          .leaveGroup(widget.group.id, user.uid);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to leave: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave Group',
            onPressed: _leaveGroup,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MembersTab(group: widget.group),
          _ChatTab(groupId: widget.group.id),
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab({required this.group});

  final Group group;

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  ReadingPlan? _activePlan;

  @override
  void initState() {
    super.initState();
    _fetchActivePlan();
  }

  Future<void> _fetchActivePlan() async {
    final planId = widget.group.activePlanId;
    if (planId == null) return;
    final plan = await ref.read(planRepositoryProvider).getPlan(planId);
    if (mounted) setState(() => _activePlan = plan);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider(widget.group.id));
    final userId = ref.watch(authNotifierProvider).valueOrNull?.uid ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupStreakBanner(streak: widget.group.groupStreak),
          const SizedBox(height: 16),
          if (_activePlan != null) ...[
            _TodayReadingCard(plan: _activePlan!),
            const SizedBox(height: 16),
          ],
          const Text(
            'Members',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17),
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
            data: (members) => Column(
              children: members
                  .map((m) => _MemberTile(
                        member: m,
                        groupId: widget.group.id,
                        currentUserId: userId,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          _WeeklyLeaderboard(weeklyXpBoard: widget.group.weeklyXpBoard),
        ],
      ),
    );
  }
}

class _GroupStreakBanner extends StatelessWidget {
  const _GroupStreakBanner({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: streak > 0
            ? AppColors.streakGold.withOpacity(0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: streak > 0
              ? AppColors.streakGold.withOpacity(0.4)
              : AppColors.surfaceElevated,
        ),
      ),
      child: Row(
        children: [
          Text(streak > 0 ? '🔥' : '💤',
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Streak',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                streak > 0 ? '$streak day${streak == 1 ? '' : 's'}' : 'No streak yet',
                style: TextStyle(
                  color: streak > 0 ? AppColors.streakGold : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayReadingCard extends StatelessWidget {
  const _TodayReadingCard({required this.plan});

  final ReadingPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(plan.coverEmoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Plan",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  plan.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.groupId,
    required this.currentUserId,
  });

  final GroupMember member;
  final String groupId;
  final String currentUserId;

  Future<void> _sendNudge(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(groupRepositoryProvider).sendNudge(
            Nudge(
              id: '',
              fromUserId: currentUserId,
              toUserId: member.userId,
              groupId: groupId,
              sentAt: DateTime.now(),
              opened: false,
            ),
          );
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nudge sent!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to nudge: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = member.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: member.photoUrl != null
                ? NetworkImage(member.photoUrl!)
                : null,
            child: member.photoUrl == null
                ? Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${member.displayName} (you)' : member.displayName,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
                if (member.streak > 0)
                  Text(
                    '🔥 ${member.streak}',
                    style: const TextStyle(
                        color: AppColors.streakGold, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (member.todayRead)
            const Icon(Icons.check_circle, color: AppColors.success, size: 22)
          else
            const Icon(Icons.radio_button_unchecked,
                color: AppColors.textMuted, size: 22),
          if (!member.todayRead && !isMe) ...[
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _sendNudge(context, ref),
              child: const Text('Nudge', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyLeaderboard extends StatelessWidget {
  const _WeeklyLeaderboard({required this.weeklyXpBoard});

  final Map<String, int> weeklyXpBoard;

  @override
  Widget build(BuildContext context) {
    if (weeklyXpBoard.isEmpty) return const SizedBox.shrink();

    final sorted = weeklyXpBoard.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly XP Board',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        const SizedBox(height: 8),
        ...sorted.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final userId = entry.value.key;
          final xp = entry.value.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppColors.streakGold.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rank == 1
                    ? AppColors.streakGold.withOpacity(0.4)
                    : AppColors.surfaceElevated,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Text(
                    userId,
                    style: const TextStyle(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$xp XP',
                  style: TextStyle(
                    color: rank == 1
                        ? AppColors.streakGold
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _messagesStream() {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return;

    _messageController.clear();
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'text': text,
      'type': 'message',
      'timestamp': FieldValue.serverTimestamp(),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(authNotifierProvider).valueOrNull?.uid ?? '';

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet. Say hello!',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (ctx, i) {
                  final msg = messages[i];
                  final isMe = msg['senderId'] == currentUserId;
                  final type = msg['type'] as String? ?? 'message';
                  if (type == 'system') {
                    return _SystemMessage(text: msg['text'] as String? ?? '');
                  }
                  return _ChatBubble(
                      message: msg, isMe: isMe);
                },
              );
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.surfaceElevated),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle:
                          const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMe});

  final Map<String, dynamic> message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                Radius.circular(isMe ? 18 : 4),
            bottomRight:
                Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(
          message['text'] as String? ?? '',
          style: TextStyle(
            color: isMe ? AppColors.background : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }
}

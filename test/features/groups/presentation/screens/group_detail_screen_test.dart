import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group_member.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/group_detail_screen.dart';

void main() {
  final group = Group(
    id: 'g1',
    name: 'Morning Crew',
    description: '',
    creatorId: 'user1',
    inviteCode: 'ABC123',
    memberIds: ['user1', 'user2'],
    groupStreak: 3,
    weeklyXpBoard: {},
  );

  final members = [
    GroupMember(
        userId: 'user1', displayName: 'Alice', todayRead: true, streak: 5),
    GroupMember(
        userId: 'user2', displayName: 'Bob', todayRead: false, streak: 2),
  ];

  testWidgets('GroupDetailScreen renders group name and streak',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const GroupDetailScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Morning Crew'), findsOneWidget);
    expect(find.text('Group Streak: 3 days'), findsOneWidget);
  });

  testWidgets('GroupDetailScreen shows checkmark for members who read',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const GroupDetailScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Read today ✅'), findsOneWidget);
    expect(find.text('Not read yet'), findsOneWidget);
  });

  testWidgets(
      'GroupDetailScreen shows Nudge button only for unread members',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupDetailProvider('g1').overrideWith((_) => Stream.value(group)),
          groupMembersProvider('g1').overrideWith((_) => Stream.value(members)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const GroupDetailScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nudge'), findsOneWidget);
  });
}

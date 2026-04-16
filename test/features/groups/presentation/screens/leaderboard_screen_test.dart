import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group_member.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/leaderboard_screen.dart';

void main() {
  final group = Group(
    id: 'g1',
    name: 'Morning Crew',
    description: '',
    creatorId: 'user1',
    inviteCode: 'ABC123',
    memberIds: ['user1', 'user2', 'user3'],
    groupStreak: 0,
    weeklyXpBoard: {'user1': 150, 'user2': 200, 'user3': 50},
  );

  final members = [
    GroupMember(
        userId: 'user1', displayName: 'Alice', todayRead: true, streak: 5),
    GroupMember(
        userId: 'user2', displayName: 'Bob', todayRead: true, streak: 7),
    GroupMember(
        userId: 'user3', displayName: 'Carol', todayRead: false, streak: 1),
  ];

  testWidgets('LeaderboardScreen sorts members by weekly XP descending',
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
              builder: (_, __) => const LeaderboardScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('200 XP'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen shows gold medal for first place',
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
              builder: (_, __) => const LeaderboardScreen(groupId: 'g1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('🥇'), findsOneWidget);
    expect(find.text('🥈'), findsOneWidget);
    expect(find.text('🥉'), findsOneWidget);
  });
}

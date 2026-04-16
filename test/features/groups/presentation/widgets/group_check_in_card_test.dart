import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group_member.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/widgets/group_check_in_card.dart';
import 'package:iwannareadthebiblemore/core/auth/auth_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => 'user1';
}

void main() {
  final group = Group(
    id: 'g1',
    name: 'Morning Crew',
    description: '',
    creatorId: 'user1',
    inviteCode: 'ABC123',
    memberIds: ['user1', 'user2', 'user3'],
    groupStreak: 4,
    weeklyXpBoard: {},
  );

  final members = [
    GroupMember(
        userId: 'user1', displayName: 'Alice', todayRead: true, streak: 5),
    GroupMember(
        userId: 'user2', displayName: 'Bob', todayRead: false, streak: 2),
    GroupMember(
        userId: 'user3', displayName: 'Carol', todayRead: false, streak: 1),
  ];

  testWidgets('GroupCheckInCard shows nudge chips for unread members only',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => AuthNotifier()
              ..state = AsyncValue.data(MockUser()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Scaffold(
                body: GroupCheckInCard(group: group, members: members),
              ),
            ),
            GoRoute(
                path: '/groups/:groupId',
                builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(2));
  });

  testWidgets('GroupCheckInCard shows read count', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => AuthNotifier()
              ..state = AsyncValue.data(MockUser()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Scaffold(
                body: GroupCheckInCard(group: group, members: members),
              ),
            ),
            GoRoute(
                path: '/groups/:groupId',
                builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1/3 read today'), findsOneWidget);
  });
}

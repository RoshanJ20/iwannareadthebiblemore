import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/groups_screen.dart';

void main() {
  testWidgets('GroupsScreen renders list of groups', (tester) async {
    final groups = [
      Group(
        id: 'g1',
        name: 'Morning Crew',
        description: '',
        creatorId: 'user1',
        inviteCode: 'ABC123',
        memberIds: ['user1', 'user2'],
        groupStreak: 5,
        weeklyXpBoard: {},
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((_) => Stream.value(groups)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const GroupsScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Morning Crew'), findsOneWidget);
    expect(find.text('2 members • 🔥 5'), findsOneWidget);
  });

  testWidgets('GroupsScreen shows empty state when no groups', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const GroupsScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('GroupsScreen FAB shows bottom sheet with options',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myGroupsProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const GroupsScreen()),
            GoRoute(
                path: '/groups/create', builder: (_, __) => const Scaffold()),
            GoRoute(
                path: '/groups/join', builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Create Group'), findsOneWidget);
    expect(find.text('Join with Code'), findsOneWidget);
  });
}

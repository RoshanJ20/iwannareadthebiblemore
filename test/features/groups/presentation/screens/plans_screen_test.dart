import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/plan.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/user_plan.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/plans_screen.dart';

void main() {
  final plans = [
    ReadingPlan(
      id: 'p1',
      name: 'Gospel of John',
      description: 'Read through John',
      coverEmoji: '✝️',
      totalDays: 21,
      tags: ['gospel'],
      readings: [],
    ),
  ];

  testWidgets('PlansScreen renders plan library', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value(plans)),
          activeUserPlansProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const PlansScreen()),
            GoRoute(
                path: '/plans/:planId',
                builder: (_, __) => const Scaffold()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Gospel of John'), findsOneWidget);
    expect(find.text('21 days • gospel'), findsOneWidget);
    expect(find.text('Plan Library'), findsOneWidget);
  });

  testWidgets('PlansScreen shows active plan with Mark Read button',
      (tester) async {
    final activePlans = [
      UserPlan(
        id: 'up1',
        userId: 'user1',
        planId: 'p1',
        startDate: DateTime.now(),
        currentDay: 3,
        completedDays: [1, 2],
        isComplete: false,
        todayRead: false,
        todayChapter: 'John 3',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value(plans)),
          activeUserPlansProvider
              .overrideWith((_) => Stream.value(activePlans)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const PlansScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('My Active Plans'), findsOneWidget);
    expect(find.text('John 3'), findsOneWidget);
    expect(find.text('Mark Read'), findsOneWidget);
  });

  testWidgets('PlansScreen shows check icon when todayRead is true',
      (tester) async {
    final activePlans = [
      UserPlan(
        id: 'up1',
        userId: 'user1',
        planId: 'p1',
        startDate: DateTime.now(),
        currentDay: 3,
        completedDays: [1, 2],
        isComplete: false,
        todayRead: true,
        todayChapter: 'John 3',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value(plans)),
          activeUserPlansProvider
              .overrideWith((_) => Stream.value(activePlans)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const PlansScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Mark Read'), findsNothing);
  });
}

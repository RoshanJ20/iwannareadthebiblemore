import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/plan.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/plan_detail_screen.dart';

void main() {
  final plan = ReadingPlan(
    id: 'p1',
    name: 'Gospel of John',
    description: 'Read through the Gospel of John',
    coverEmoji: '✝️',
    totalDays: 21,
    tags: ['gospel', 'john'],
    readings: [
      PlanReading(day: 1, book: 'John', chapter: '1', title: 'The Word'),
      PlanReading(
          day: 2, book: 'John', chapter: '2', title: 'Wedding at Cana'),
    ],
  );

  testWidgets('PlanDetailScreen renders plan info and readings',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value([plan])),
          myGroupsProvider.overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const PlanDetailScreen(planId: 'p1'),
            ),
          ]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Gospel of John'), findsOneWidget);
    expect(find.text('Read through the Gospel of John'), findsOneWidget);
    expect(find.text('Day 1: The Word'), findsOneWidget);
    expect(find.text('John 1'), findsOneWidget);
    expect(find.text('Start Solo'), findsOneWidget);
    expect(find.text('Start with Group'), findsOneWidget);
  });

  testWidgets(
      'PlanDetailScreen Start Solo creates a userPlan document',
      (tester) async {
    final fakeFirestore = FakeFirebaseFirestore();
    // Seed the plan doc so startPlan can find it
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Gospel of John',
      'description': 'Read through the Gospel of John',
      'coverEmoji': '✝️',
      'totalDays': 21,
      'tags': ['gospel', 'john'],
      'isCustom': false,
      'readings': [
        {'day': 1, 'book': 'John', 'chapter': '1', 'title': 'The Word'},
      ],
    });
    final repo = PlanRepository(fakeFirestore, 'user1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planLibraryProvider.overrideWith((_) => Stream.value([plan])),
          myGroupsProvider.overrideWith((_) => Stream.value([])),
          planRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/detail',
            routes: [
              GoRoute(path: '/', builder: (_, __) => const Scaffold()),
              GoRoute(
                path: '/detail',
                builder: (_, __) => const PlanDetailScreen(planId: 'p1'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Solo'));
    await tester.pumpAndSettle();

    final snap = await fakeFirestore.collection('userPlans').get();
    expect(snap.docs.length, 1);
    expect(snap.docs.first.data()['planId'], 'p1');
    expect(snap.docs.first.data()['groupId'], isNull);
  });
}

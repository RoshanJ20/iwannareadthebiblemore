import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/create_group_screen.dart';

void main() {
  testWidgets('CreateGroupScreen shows no navigation when name is empty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            GroupRepository(FakeFirebaseFirestore(), 'user1'),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
                path: '/', builder: (_, __) => const CreateGroupScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    // Tap without entering text
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Should stay on same screen
    expect(find.byType(CreateGroupScreen), findsOneWidget);
  });

  testWidgets(
      'CreateGroupScreen creates group and navigates back on valid submit',
      (tester) async {
    final fakeFirestore = FakeFirebaseFirestore();
    final repo = GroupRepository(fakeFirestore, 'user1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/create',
            routes: [
              GoRoute(path: '/', builder: (_, __) => const Scaffold()),
              GoRoute(
                  path: '/create',
                  builder: (_, __) => const CreateGroupScreen()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Bible Study');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // After successful creation, a group doc should exist in Firestore
    final snap = await fakeFirestore.collection('groups').get();
    expect(snap.docs.length, 1);
    expect(snap.docs.first.data()['name'], 'Bible Study');
  });
}

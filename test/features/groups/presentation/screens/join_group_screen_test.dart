import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/screens/join_group_screen.dart';

void main() {
  testWidgets('JoinGroupScreen does not submit when code is too short',
      (tester) async {
    final fakeFirestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            GroupRepository(fakeFirestore, 'user1'),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const JoinGroupScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ABC');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Should stay on same screen (no navigation occurred)
    expect(find.byType(JoinGroupScreen), findsOneWidget);
  });

  testWidgets('JoinGroupScreen shows error snackbar for invalid code',
      (tester) async {
    final fakeFirestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            GroupRepository(fakeFirestore, 'user1'),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const JoinGroupScreen()),
          ]),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'BADCOD');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Group not found -> snackbar with error
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

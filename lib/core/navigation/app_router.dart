import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../../features/shell/presentation/home_screen.dart';
import '../../features/shell/presentation/login_screen.dart';
import '../../features/bible/presentation/screens/bible_screen.dart';
import '../../features/bible/presentation/screens/chapter_list_screen.dart';
import '../../features/bible/presentation/screens/chapter_reader_screen.dart';
import '../../features/bible/presentation/screens/bible_search_screen.dart';
import '../../features/bible/presentation/screens/bookmarks_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/gamification/presentation/screens/xp_store_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/join_group_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/leaderboard_screen.dart';
import '../../features/groups/presentation/screens/plans_screen.dart';
import '../../features/groups/presentation/screens/plan_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'routes.dart';

class AppRouter {
  static GoRouter create(ProviderContainer container) {
    final authListenable = _AuthListenable(container);

    return GoRouter(
      initialLocation: Routes.home,
      refreshListenable: authListenable,
      redirect: (context, state) {
        final authState = container.read(authNotifierProvider);
        // Hold current location while auth is resolving — re-evaluated on next notify.
        if (authState.isLoading) return null;

        final user = authState.valueOrNull;
        final isLoggingIn = state.matchedLocation == Routes.login;

        if (user == null && !isLoggingIn) return Routes.login;
        if (user != null && isLoggingIn) return Routes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: Routes.login,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: Routes.achievements,
          builder: (_, __) => const AchievementsScreen(),
        ),
        GoRoute(
          path: Routes.store,
          builder: (_, __) => const XpStoreScreen(),
        ),
        GoRoute(
          path: '/groups/create',
          builder: (_, __) => const CreateGroupScreen(),
        ),
        GoRoute(
          path: '/groups/join',
          builder: (_, __) => const JoinGroupScreen(),
        ),
        GoRoute(
          path: '/groups/:groupId',
          builder: (_, state) =>
              GroupDetailScreen(groupId: state.pathParameters['groupId']!),
          routes: [
            GoRoute(
              path: 'leaderboard',
              builder: (_, state) =>
                  LeaderboardScreen(groupId: state.pathParameters['groupId']!),
            ),
          ],
        ),
        GoRoute(
          path: '/plans/:planId',
          builder: (_, state) =>
              PlanDetailScreen(planId: state.pathParameters['planId']!),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => ShellScreen(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.read,
                builder: (_, __) => const BibleScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (_, __) => const BibleSearchScreen(),
                  ),
                  GoRoute(
                    path: 'bookmarks',
                    builder: (_, __) => const BookmarksScreen(),
                  ),
                  GoRoute(
                    path: ':bookId',
                    builder: (_, state) => ChapterListScreen(
                      bookId: state.pathParameters['bookId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: ':chapterNumber',
                        builder: (_, state) => ChapterReaderScreen(
                          bookId: state.pathParameters['bookId']!,
                          chapterNumber: int.parse(
                            state.pathParameters['chapterNumber']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: Routes.groups, builder: (_, __) => const GroupsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: Routes.plans, builder: (_, __) => const PlansScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),
      ],
    );
  }
}

/// Makes GoRouter re-evaluate redirects when auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(ProviderContainer container) {
    _sub = container.listen(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<User?>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

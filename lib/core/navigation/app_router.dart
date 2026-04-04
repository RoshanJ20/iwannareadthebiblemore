import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../../features/shell/presentation/home_screen.dart';
import '../../features/shell/presentation/login_screen.dart';
import '../../features/bible/presentation/screens/bible_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/plans_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'routes.dart';

class AppRouter {
  static GoRouter create(ProviderContainer container) {
    final authListenable = _AuthListenable(container);

    return GoRouter(
      initialLocation: Routes.home,
      refreshListenable: authListenable,
      redirect: (context, state) {
        final user = container.read(authNotifierProvider).valueOrNull;
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
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => ShellScreen(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: Routes.read, builder: (_, __) => const BibleScreen()),
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
    container.listen(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Accessed via ref in App widget; not used in tests (tests call AppRouter.create directly).
  throw UnimplementedError('routerProvider must be overridden in tests');
});

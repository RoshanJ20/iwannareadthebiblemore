import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/design_system/app_theme.dart';
import 'core/navigation/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ProviderScope.containerOf requires an inherited widget lookup —
    // must be called in didChangeDependencies, not initState.
    _router ??= AppRouter.create(ProviderScope.containerOf(context));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iwannareadthebiblemore',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}

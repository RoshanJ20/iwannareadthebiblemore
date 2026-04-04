import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', route: Routes.home),
    (icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Read', route: Routes.read),
    (icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Groups', route: Routes.groups),
    (icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Plans', route: Routes.plans),
    (icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Profile', route: Routes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

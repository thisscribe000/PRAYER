import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = <_TabItem>[
    _TabItem(label: 'Home', path: '/home', icon: Icons.home_outlined),
    _TabItem(label: 'Bank', path: '/bank', icon: Icons.bookmark_border),
    _TabItem(label: 'Rooms', path: '/rooms', icon: Icons.groups_outlined),
    _TabItem(label: 'Invite', path: '/invite', icon: Icons.person_add_alt_1),
    _TabItem(label: 'Settings', path: '/settings', icon: Icons.settings_outlined),
  ];

  int _locationToIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final String path;
  final IconData icon;
  const _TabItem({
    required this.label,
    required this.path,
    required this.icon,
  });
}

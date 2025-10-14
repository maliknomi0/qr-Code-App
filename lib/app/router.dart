import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/generate/presentation/generate_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

GoRouter buildAppRouter(Ref ref) {
  return GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _HomeShell(shell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'scan',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ScanScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/generate',
                name: 'generate',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: GenerateScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HistoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    _NavTab('Scan', Icons.qr_code_scanner),
    _NavTab('Generate', Icons.add_box_outlined),
    _NavTab('History', Icons.history),
    _NavTab('Settings', Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _NavTab {
  const _NavTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

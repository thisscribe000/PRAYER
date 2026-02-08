import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bank/presentation/bank_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/invite/presentation/invite_screen.dart';
import '../../features/rooms/presentation/rooms_screen.dart';
import '../../features/session/presentation/pray_now_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/bank', builder: (c, s) => const BankScreen()),
          GoRoute(path: '/rooms', builder: (c, s) => const RoomsScreen()),
          GoRoute(path: '/invite', builder: (c, s) => const InviteScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),

      // Full-screen flows (not part of bottom tabs)
      GoRoute(path: '/session', builder: (c, s) => const PrayNowScreen()),
      GoRoute(path: '/pray', builder: (c, s) => const PrayNowScreen()),
    ],
  );
});

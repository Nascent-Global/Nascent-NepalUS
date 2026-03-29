import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_providers.dart';
import '../screens/alerts_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/check_in_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/recovery_screen.dart';
import '../screens/tasks_pressure_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/aura_background.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Daily Check-in',
    'Tasks',
    'Recovery',
    'Focus',
    'Alerts',
  ];

  final _screens = const [
    DashboardScreen(),
    CheckInScreen(),
    TasksPressureScreen(),
    RecoveryScreen(),
    FocusScreen(),
    AlertsScreen(),
  ];

  Future<void> _openAuthScreen(AuthScreenMode mode) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AuthScreen(initialMode: mode)));
  }

  Future<void> _openProfileSheet() async {
    final authState = ref.read(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (!authState.isAuthenticated) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('You are in guest mode.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _openAuthScreen(AuthScreenMode.login);
                    },
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _openAuthScreen(AuthScreenMode.register);
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = authState.session!.user;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user.username,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await authController.logout();
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_titles[_index]),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: _openProfileSheet,
              tooltip: authState.isAuthenticated
                  ? 'Profile'
                  : 'Login / Register',
              icon: Icon(
                authState.isAuthenticated
                    ? Icons.account_circle_rounded
                    : Icons.person_outline_rounded,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _screens[_index],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          indicatorColor: AppTheme.mint.withValues(alpha: 0.5),
          onDestinationSelected: (index) {
            setState(() => _index = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_rounded),
              label: 'Check',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_rounded),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.air_rounded),
              label: 'Recover',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_rounded),
              label: 'Focus',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}

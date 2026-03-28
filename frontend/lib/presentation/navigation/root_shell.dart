import 'package:flutter/material.dart';

import '../screens/alerts_screen.dart';
import '../screens/check_in_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/recovery_screen.dart';
import '../screens/tasks_pressure_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/aura_background.dart';

class RootShell extends StatefulWidget {
  const RootShell({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Daily Check-in',
    'Tasks & Pressure',
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

  @override
  Widget build(BuildContext context) {
    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_titles[_index]),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: widget.onLogout,
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded),
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

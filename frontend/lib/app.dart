import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth_providers.dart';
import 'presentation/navigation/root_shell.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/theme/app_theme.dart';

class BurnoutRadarApp extends ConsumerWidget {
  const BurnoutRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Burnout Radar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: authState.isAuthenticated
          ? RootShell(
              onLogout: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            )
          : const AuthScreen(),
    );
  }
}

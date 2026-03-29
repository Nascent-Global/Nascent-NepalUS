import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'presentation/navigation/root_shell.dart';
import 'presentation/theme/app_theme.dart';

class BurnoutRadarApp extends ConsumerWidget {
  const BurnoutRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncBootstrapProvider);

    return MaterialApp(
      title: 'Burnout Radar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}

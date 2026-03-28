import 'package:flutter/material.dart';

import 'presentation/navigation/root_shell.dart';
import 'presentation/theme/app_theme.dart';

class BurnoutRadarApp extends StatelessWidget {
  const BurnoutRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burnout Radar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}

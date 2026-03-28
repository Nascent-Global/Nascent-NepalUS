import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuraBackground extends StatelessWidget {
  const AuraBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7FAFF), Color(0xFFE6EDFF)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -40,
          child: _AuraBlob(color: AppTheme.cobalt.withValues(alpha: 0.22)),
        ),
        Positioned(
          right: -60,
          bottom: -100,
          child: _AuraBlob(color: AppTheme.mint.withValues(alpha: 0.28)),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: const SizedBox.expand(),
          ),
        ),
        child,
      ],
    );
  }
}

class _AuraBlob extends StatelessWidget {
  const _AuraBlob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(180),
      ),
    );
  }
}

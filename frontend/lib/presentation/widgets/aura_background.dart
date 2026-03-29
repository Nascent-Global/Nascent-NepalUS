import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'sky_decorations.dart';

class AuraBackground extends StatelessWidget {
  const AuraBackground({
    required this.child,
    super.key,
    this.showDecorations = true,
    this.decorations,
  });

  final Widget child;
  final bool showDecorations;
  final Widget? decorations;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.skyGradient),
          ),
        ),
        Positioned(
          top: -120,
          left: -70,
          child: _AuraBlob(
            width: 310,
            height: 310,
            colors: <Color>[
              AppTheme.primarySoft.withValues(alpha: 0.4),
              AppTheme.primary.withValues(alpha: 0.08),
            ],
          ),
        ),
        Positioned(
          right: -80,
          bottom: -110,
          child: _AuraBlob(
            width: 300,
            height: 300,
            colors: <Color>[
              AppTheme.secondarySoft.withValues(alpha: 0.46),
              AppTheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        if (showDecorations)
          Positioned.fill(
            child: IgnorePointer(
              child: decorations ?? const SkyDecorations(opacity: 0.92),
            ),
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
  const _AuraBlob({required this.colors, this.width = 260, this.height = 260});

  final List<Color> colors;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors, stops: const <double>[0, 1]),
      ),
    );
  }
}

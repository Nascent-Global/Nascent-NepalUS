import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GlassCardVariant { frosted, primary, secondary }

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.variant = GlassCardVariant.frosted,
    this.borderRadius = 22,
    this.blurSigma = 8,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final GlassCardVariant variant;
  final double borderRadius;
  final double blurSigma;

  Gradient _gradientForVariant() {
    switch (variant) {
      case GlassCardVariant.primary:
        return AppTheme.primaryGradient;
      case GlassCardVariant.secondary:
        return AppTheme.secondaryGradient;
      case GlassCardVariant.frosted:
        return AppTheme.frostedGradient;
    }
  }

  Color _borderColorForVariant() {
    switch (variant) {
      case GlassCardVariant.primary:
        return Colors.white.withValues(alpha: 0.42);
      case GlassCardVariant.secondary:
        return AppTheme.secondaryDark.withValues(alpha: 0.28);
      case GlassCardVariant.frosted:
        return Colors.white.withValues(alpha: 0.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: _gradientForVariant(),
            color: AppTheme.cardTint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _borderColorForVariant(), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: body,
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SkyDecorations extends StatelessWidget {
  const SkyDecorations({
    super.key,
    this.opacity = 1,
    this.showSun = true,
    this.showClouds = true,
    this.showSmileBadge = true,
  });

  final double opacity;
  final bool showSun;
  final bool showClouds;
  final bool showSmileBadge;

  @override
  Widget build(BuildContext context) {
    final normalizedOpacity = opacity.clamp(0.0, 1.0).toDouble();
    return Opacity(
      opacity: normalizedOpacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: <Widget>[
              if (showClouds) ...<Widget>[
                Positioned(
                  top: height * 0.08,
                  left: -width * 0.09,
                  child: _Cloud(
                    width: width * 0.34,
                    height: math.max(64, height * 0.11),
                    color: Colors.white.withValues(alpha: 0.7),
                    borderColor: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                Positioned(
                  top: height * 0.2,
                  right: -width * 0.06,
                  child: _Cloud(
                    width: width * 0.28,
                    height: math.max(56, height * 0.09),
                    color: Colors.white.withValues(alpha: 0.6),
                    borderColor: AppTheme.secondary.withValues(alpha: 0.22),
                  ),
                ),
                Positioned(
                  bottom: height * 0.14,
                  left: width * 0.06,
                  child: _Cloud(
                    width: width * 0.2,
                    height: math.max(48, height * 0.08),
                    color: Colors.white.withValues(alpha: 0.52),
                    borderColor: AppTheme.primary.withValues(alpha: 0.16),
                  ),
                ),
              ],
              if (showSun)
                Positioned(
                  top: height * 0.02,
                  right: width * 0.06,
                  child: _SunBadge(size: math.max(74, width * 0.12)),
                ),
              if (showSmileBadge)
                Positioned(
                  bottom: height * 0.06,
                  right: width * 0.08,
                  child: _SmileChip(
                    width: math.max(76, width * 0.16),
                    height: math.max(38, height * 0.06),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({
    required this.width,
    required this.height,
    required this.color,
    required this.borderColor,
  });

  final double width;
  final double height;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final puffSize = height * 0.78;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: width * 0.06,
            top: height * 0.28,
            child: Container(
              width: width * 0.82,
              height: height * 0.56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height * 0.6),
                border: Border.all(color: borderColor, width: 1),
              ),
            ),
          ),
          Positioned(
            left: width * 0.14,
            top: height * 0.06,
            child: _CloudPuff(
              size: puffSize,
              color: color,
              borderColor: borderColor,
            ),
          ),
          Positioned(
            left: width * 0.36,
            top: 0,
            child: _CloudPuff(
              size: puffSize * 1.06,
              color: color,
              borderColor: borderColor,
            ),
          ),
          Positioned(
            left: width * 0.58,
            top: height * 0.08,
            child: _CloudPuff(
              size: puffSize * 0.84,
              color: color,
              borderColor: borderColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudPuff extends StatelessWidget {
  const _CloudPuff({
    required this.size,
    required this.color,
    required this.borderColor,
  });

  final double size;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
      ),
    );
  }
}

class _SunBadge extends StatelessWidget {
  const _SunBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final rayColor = AppTheme.secondary.withValues(alpha: 0.35);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          for (var i = 0; i < 8; i++)
            Transform.rotate(
              angle: i * (math.pi / 4),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: size * 0.1,
                  height: size * 0.26,
                  decoration: BoxDecoration(
                    color: rayColor,
                    borderRadius: BorderRadius.circular(size * 0.1),
                  ),
                ),
              ),
            ),
          Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppTheme.secondarySoft, AppTheme.secondary],
              ),
              border: Border.all(
                color: AppTheme.secondaryDark.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.secondary.withValues(alpha: 0.34),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.05),
                ),
              ],
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              size: size * 0.3,
              color: AppTheme.secondaryDark.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmileChip extends StatelessWidget {
  const _SmileChip({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            AppTheme.primarySoft.withValues(alpha: 0.66),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      padding: EdgeInsets.symmetric(horizontal: height * 0.28),
      child: Row(
        children: <Widget>[
          Container(
            width: height * 0.56,
            height: height * 0.56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondary.withValues(alpha: 0.36),
            ),
            child: Icon(
              Icons.sentiment_satisfied_alt_rounded,
              size: height * 0.38,
              color: AppTheme.secondaryDark,
            ),
          ),
          SizedBox(width: height * 0.2),
          Text(
            'breathe',
            style: TextStyle(
              fontSize: height * 0.32,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink.withValues(alpha: 0.8),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

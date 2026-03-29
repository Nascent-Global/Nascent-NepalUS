import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Primary and secondary brand colors. Change these two values to retone
  // the whole visual system.
  static const Color primary = Color(0xFF4AA7F8);
  static const Color secondary = Color(0xFFFFD56A);

  static const Color surface = Color(0xFFF4FAFF);
  static const Color ink = Color(0xFF153153);
  static const Color cardTint = Color(0xE8FFFFFF);

  static const Color primaryDark = Color(0xFF2088DB);
  static const Color primarySoft = Color(0xFFB1DEFF);
  static const Color secondaryDark = Color(0xFFC38000);
  static const Color secondarySoft = Color(0xFFFFF1C8);
  static const Color warning = Color(0xFFF9A44A);
  static const Color danger = Color(0xFFE25A6A);

  static LinearGradient get skyGradient => LinearGradient(
    colors: <Color>[
      surface,
      primarySoft.withValues(alpha: 0.46),
      secondarySoft.withValues(alpha: 0.52),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get primaryGradient => LinearGradient(
    colors: <Color>[primaryDark, primary, primarySoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get secondaryGradient => LinearGradient(
    colors: <Color>[secondarySoft, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get frostedGradient => LinearGradient(
    colors: <Color>[
      Colors.white.withValues(alpha: 0.95),
      surface,
      primarySoft.withValues(alpha: 0.2),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    final scheme = ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: secondaryDark,
      onSurface: ink,
      error: danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: BorderSide(color: primaryDark, width: 1.2),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.26)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryDark, width: 1.4),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.2),
        thumbColor: primaryDark,
        overlayColor: primary.withValues(alpha: 0.16),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

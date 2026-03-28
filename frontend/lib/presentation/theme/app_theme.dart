import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color surface = Color(0xFFF3F6FF);
  static const Color navy = Color(0xFF0C1B46);
  static const Color cobalt = Color(0xFF2F4DB8);
  static const Color mint = Color(0xFFB8F15A);
  static const Color cardTint = Color(0xCCFFFFFF);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cobalt,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: navy,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w700,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
      ),
    );
  }
}

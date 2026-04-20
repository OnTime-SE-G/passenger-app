import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography: Space Grotesk for headlines, Manrope for body/labels.
class AppTypography {
  AppTypography._();

  static TextStyle headline(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: AppColors.onSurface,
        letterSpacing: -0.3,
      );

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurfaceVariant,
      );

  static TextStyle label(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurfaceVariant,
        letterSpacing: 0.8,
      );

  static TextTheme textTheme(BuildContext context) {
    return TextTheme(
      displayLarge: headline(36, weight: FontWeight.w900),
      headlineLarge: headline(28),
      headlineMedium: headline(22),
      titleLarge: headline(20, weight: FontWeight.w600),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      bodyLarge: body(16),
      bodyMedium: body(14),
      bodySmall: body(12, color: AppColors.outline),
      labelLarge: label(14),
      labelMedium: label(12),
      labelSmall: label(10),
    );
  }
}

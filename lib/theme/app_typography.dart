import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Inter — matches ontime-web font family.
class AppTypography {
  AppTypography._();

  static TextStyle headline(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: AppColors.onSurface,
        letterSpacing: -0.025,
        height: 1.15,
      );

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurfaceVariant,
        height: 1.5,
      );

  static TextStyle label(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.onSurfaceVariant,
        letterSpacing: 0.02,
      );

  static TextTheme textTheme(BuildContext context) {
    return TextTheme(
      displayLarge: headline(36, weight: FontWeight.w800),
      headlineLarge: headline(28),
      headlineMedium: headline(22),
      titleLarge: headline(20, weight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        letterSpacing: -0.015,
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

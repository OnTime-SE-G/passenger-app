import 'package:flutter/material.dart';

/// Signal Flux Design System — Dark Midnight Indigo palette.
/// Shared across Passenger App & Driver App.
class AppColors {
  AppColors._();

  // Primary — Indigo/Lavender
  static const Color primary = Color(0xFFBCC2FF);
  static const Color primaryContainer = Color(0xFF142283);
  static const Color onPrimaryContainer = Color(0xFF8390F2);
  static const Color onPrimary = Color(0xFF152383);
  static const Color primaryFixed = Color(0xFFDFE0FF);
  static const Color primaryFixedDim = Color(0xFFBCC2FF);

  // Secondary — Cyan/Teal (signal color for "Live" states)
  static const Color secondary = Color(0xFF44D8F1);
  static const Color secondaryContainer = Color(0xFF00BCD4);
  static const Color onSecondaryContainer = Color(0xFF004650);

  // Tertiary
  static const Color tertiary = Color(0xFF00DAF3);
  static const Color tertiaryContainer = Color(0xFF00363D);

  // Error
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // Surfaces — tonal layering hierarchy
  static const Color background = Color(0xFF11131C);

  /// Behind `icon.png` on splash: matches the asset’s solid canvas so transparent
  /// pixels (shown as checkerboard on web) read as a seamless full-screen fill.
  static const Color splashIconBackdrop = Color(0xFF2F2F34);
  static const Color surface = Color(0xFF11131C);
  static const Color surfaceDim = Color(0xFF11131C);
  static const Color surfaceContainerLowest = Color(0xFF0C0E17);
  static const Color surfaceContainerLow = Color(0xFF191B24);
  static const Color surfaceContainer = Color(0xFF1D1F29);
  static const Color surfaceContainerHigh = Color(0xFF282933);
  static const Color surfaceContainerHighest = Color(0xFF32343E);
  static const Color surfaceBright = Color(0xFF373943);
  static const Color surfaceVariant = Color(0xFF32343E);

  // On-Surface text
  static const Color onSurface = Color(0xFFE1E1EF);
  static const Color onSurfaceVariant = Color(0xFFC6C5D4);
  static const Color onBackground = Color(0xFFE1E1EF);

  // Outlines
  static const Color outline = Color(0xFF908F9D);
  static const Color outlineVariant = Color(0xFF454652);

  // Inverse
  static const Color inverseSurface = Color(0xFFE1E1EF);
  static const Color inverseOnSurface = Color(0xFF2E303A);

  // Surface tint
  static const Color surfaceTint = Color(0xFFBCC2FF);

  // Map
  static const Color routeLine = Color(0xFF44D8F1);
  static const Color routePassed = Color(0xFF454652);
}

import 'package:flutter/material.dart';

/// Light modern palette — cool slate neutrals + teal primary + cyan accents (mobile-first, not web clone).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F766E);
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFE6FFFA);
  static const Color primaryFixedDim = Color(0xFF5EEAD4);
  static const Color onPrimaryFixed = Color(0xFF042F2E);

  static const Color secondary = Color(0xFF0891B2);
  static const Color secondaryContainer = Color(0xFFCFFAFE);
  static const Color onSecondaryContainer = Color(0xFF164E63);

  static const Color tertiary = Color(0xFFF97316);

  static const Color error = Color(0xFFB91C1C);
  static const Color errorBright = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static const Color success = Color(0xFF059669);
  static const Color successMuted = Color(0xFFD1FAE5);
  static const Color onSuccessDark = Color(0xFF065F46);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF1F5F9);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);

  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);

  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  static const Color inverseSurface = Color(0xFF1E293B);
  static const Color inverseOnSurface = Color(0xFFF8FAFC);

  static const Color sidebarTint = Color(0xFFF1F5F9);
  static const Color navInactive = Color(0xFF94A3B8);
  static const Color navActiveBlue = primary;

  static const Color routePassed = Color(0xFFCBD5E1);
  static const Color routeAhead = Color(0xFF0EA5E9);

  static const Color surfaceVariant = surfaceContainerHigh;
}

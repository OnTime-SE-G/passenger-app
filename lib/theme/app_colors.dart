import 'package:flutter/material.dart';

/// Matches ontime-web's Kinetic Stream design system — #004ac6 blue palette.
class AppColors {
  AppColors._();

  // Primary: #004ac6 (matches --color-primary in ontime-web globals.css)
  static const Color primary = Color(0xFF004AC6);
  static const Color primaryContainer = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color primaryFixedDim = Color(0xFFB4C5FF);
  static const Color onPrimaryFixed = Color(0xFF00174B);

  static const Color secondary = Color(0xFF495C95);
  static const Color secondaryContainer = Color(0xFFACBFFF);
  static const Color onSecondaryContainer = Color(0xFF394C84);

  static const Color tertiary = Color(0xFF943700);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorBright = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const Color success = Color(0xFF16A34A);
  static const Color successMuted = Color(0xFFDCFCE7);
  static const Color onSuccessDark = Color(0xFF14532D);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFD9DADB);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);

  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF434655);

  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);

  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);

  static const Color sidebarTint = Color(0xFFF3F4F5);
  static const Color navInactive = Color(0xFF737686);
  static const Color navActiveBlue = primary;

  static const Color routePassed = Color(0xFFC3C6D7);
  static const Color routeAhead = Color(0xFF004AC6);

  static const Color surfaceVariant = surfaceContainerHigh;
}

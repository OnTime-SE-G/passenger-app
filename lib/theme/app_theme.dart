import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build(BuildContext context) {
    final textTheme = AppTypography.textTheme(context);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.errorBright,
        outline: AppColors.outline,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withOpacity(0.94),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: AppColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shadowColor: const Color(0x14000000),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle:
              GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurfaceVariant,
          minimumSize: const Size.fromHeight(44),
          side: BorderSide.none,
          backgroundColor: AppColors.surfaceContainerHigh,
          textStyle:
              GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDim,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle:
            GoogleFonts.plusJakartaSans(color: AppColors.outline, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withOpacity(0.85),
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.94),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

/// Soft diffuse shadow for elevated surfaces on light backgrounds.
const List<BoxShadow> kAmbientShadow = [
  BoxShadow(
    color: Color(0x14000000),
    blurRadius: 32,
    offset: Offset(0, 12),
    spreadRadius: -8,
  ),
];

/// Frosted panel on maps / overlays — reads lighter than heavy glass.
BoxDecoration glassPanelDecoration({double radius = 16}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.94),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.95)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 28,
        offset: Offset(0, 12),
        spreadRadius: -6,
      ),
    ],
  );
}

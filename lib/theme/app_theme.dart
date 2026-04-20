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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Color(0xFF00363E),
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
          letterSpacing: 3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.primaryFixed,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurfaceVariant,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
          textStyle: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: GoogleFonts.manrope(color: AppColors.outline, fontSize: 14),
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
          borderSide: BorderSide(color: AppColors.secondary.withOpacity(0.3), width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.onSurfaceVariant,
      ),
    );
  }
}

/// Ambient shadow for floating cards.
const List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Color(0x33000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  ),
];

/// Glass panel decoration.
BoxDecoration glassDecoration({
  double opacity = 0.6,
  double blur = 20,
  double borderRadius = 32,
}) {
  return BoxDecoration(
    color: AppColors.surfaceContainerHighest.withOpacity(opacity),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: Colors.white.withOpacity(0.05)),
  );
}

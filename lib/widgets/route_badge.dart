import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Route number badge — rounded capsule with optional emphasis.
class RouteBadge extends StatelessWidget {
  const RouteBadge({
    super.key,
    required this.code,
    this.size = 48,
    this.featured = false,
  });

  final String code;
  final double size;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: featured ? AppSpacing.xl : AppSpacing.md,
        vertical: featured ? AppSpacing.md : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: featured
            ? AppColors.primary
            : AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Text(
        code,
        style: GoogleFonts.plusJakartaSans(
          color: featured ? AppColors.onPrimary : AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: featured ? 28 : size * 0.36,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

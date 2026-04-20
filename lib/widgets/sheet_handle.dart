import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Drag handle for bottom sheets — outline-variant colored.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.outlineVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        ),
      ),
    );
  }
}

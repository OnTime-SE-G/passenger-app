import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Search field — neutral fill, rounded, theme-driven.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.leading = Icons.search,
    this.trailing,
    this.onTrailingTap,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData leading;
  final IconData? trailing;
  final VoidCallback? onTrailingTap;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      readOnly: readOnly,
      onTap: onTap,
      style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(leading, color: AppColors.onSurfaceVariant, size: 20),
        suffixIcon: trailing != null
            ? IconButton(
                icon: Icon(trailing, color: AppColors.primary, size: 20),
                onPressed: onTrailingTap,
              )
            : null,
      ),
    );
  }
}

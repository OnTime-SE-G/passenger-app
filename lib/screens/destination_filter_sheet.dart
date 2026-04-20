import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';
import '../widgets/search_field.dart';
import '../widgets/sheet_handle.dart';

class FilterResult {
  final String destination;
  final String status;
  final bool navigateToSelection;
  const FilterResult(this.destination, this.status, this.navigateToSelection);
}

/// Screen 5 — Destination filter bottom sheet (dark theme).
class DestinationFilterSheet extends StatefulWidget {
  const DestinationFilterSheet({
    super.key,
    required this.initialDestination,
    required this.initialStatus,
  });

  final String initialDestination;
  final String initialStatus;

  @override
  State<DestinationFilterSheet> createState() => _DestinationFilterSheetState();
}

class _DestinationFilterSheetState extends State<DestinationFilterSheet> {
  late final TextEditingController _destCtl;
  late String _status;

  static const _statuses = ['All', 'On time', 'Arriving', 'Delayed'];

  @override
  void initState() {
    super.initState();
    _destCtl = TextEditingController(text: widget.initialDestination);
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _destCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter buses',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Narrow down to the best option',
                      style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xl),
                  Text('DESTINATION',
                      style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 2)),
                  const SizedBox(height: AppSpacing.sm),
                  SearchField(
                    hint: 'e.g. Tech Park Gate',
                    controller: _destCtl,
                    leading: Icons.place_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('STATUS',
                      style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 2)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _statuses.map((s) {
                      final selected = s == _status;
                      return GestureDetector(
                        onTap: () => setState(() => _status = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                            border: selected
                                ? Border.all(color: AppColors.primary.withOpacity(0.3))
                                : null,
                          ),
                          child: Text(s,
                              style: GoogleFonts.manrope(
                                color: selected ? AppColors.primaryFixed : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Find Best Buses',
                    icon: Icons.auto_awesome,
                    onPressed: () {
                      Navigator.of(context).pop(FilterResult(_destCtl.text.trim(), _status, true));
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Apply Filters',
                    onPressed: () {
                      Navigator.of(context).pop(FilterResult(_destCtl.text.trim(), _status, false));
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

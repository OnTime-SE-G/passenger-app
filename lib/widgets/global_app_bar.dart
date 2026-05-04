import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/api_repository.dart';
import '../services/app_tab_controller.dart';
import '../theme/app_colors.dart';
import 'notifications_sheet.dart';

/// Shared top-right action trio that mirrors the web reference:
/// [Refresh]  [Bell w/ badge]  [Profile avatar]
///
/// • Bell  → opens the Notifications bottom sheet (web-style panel)
/// • Avatar → jumps to the Profile tab via AppTabController
class GlobalHeaderActions extends StatelessWidget {
  const GlobalHeaderActions({
    super.key,
    required this.onRefresh,
    this.onNotifications, // optional override; defaults to sheet
    this.onProfile,       // optional override; defaults to tab jump
  });

  final VoidCallback onRefresh;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final alertCount = ApiRepository.instance.alerts.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Refresh ────────────────────────────────────────────────
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 22),
          color: AppColors.onSurfaceVariant,
          splashRadius: 20,
        ),

        // ── Badged notification bell ───────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: onNotifications ??
                  () => NotificationsSheet.show(context),
              icon: const Icon(Icons.notifications_outlined, size: 22),
              color: AppColors.onSurfaceVariant,
              splashRadius: 20,
            ),
            if (alertCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$alertCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // ── Profile avatar → Profile tab ──────────────────────────
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Tooltip(
            message: 'Profile',
            child: GestureDetector(
              onTap: onProfile ??
                  () => AppTabController.instance.jumpTo(5),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_repository.dart';
import '../theme/app_colors.dart';

/// Shared top-right action trio that mirrors the web reference:
/// [Refresh]  [Bell w/ badge]  [Profile avatar]
///
/// Drop this into any screen's AppBar.actions or as a Row in a custom header.
class GlobalHeaderActions extends StatelessWidget {
  const GlobalHeaderActions({
    super.key,
    required this.onRefresh,
    this.onNotifications,
    this.onProfile,
  });

  final VoidCallback onRefresh;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final alertCount = DemoRepository.instance.alerts.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Refresh
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          color: AppColors.onSurfaceVariant,
        ),

        // Badged bell
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: onNotifications ?? () {},
              icon: const Icon(Icons.notifications_outlined),
              color: AppColors.onSurfaceVariant,
            ),
            if (alertCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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

        // Profile avatar
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: onProfile ?? () {},
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
      ],
    );
  }
}

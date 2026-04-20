import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ontime_logo.dart';

/// Alerts screen — matches Signal Flux operator control center style.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
        title: const OnTimeLogo(size: OnTimeLogoSize.small),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 72,
          bottom: 120,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live Alerts', style: AppTypography.headline(28)),
                const SizedBox(height: AppSpacing.sm),
                Text('System notifications and service updates',
                    style: AppTypography.body(14)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _AlertItem(
            severity: 'CRITICAL',
            severityColor: AppColors.error,
            title: 'Unit 704: Signal Loss',
            subtitle: 'GPS intermittent near Sector 12 tunnel entrance.',
            time: '2m ago',
          ),
          _AlertItem(
            severity: 'STATUS UPDATE',
            severityColor: AppColors.secondary,
            title: 'Route B Re-routed',
            subtitle: 'Standard deviation applied due to road block on 5th Ave.',
            time: '14m ago',
          ),
          _AlertItem(
            severity: 'RESOLVED',
            severityColor: AppColors.onSurfaceVariant,
            title: 'Unit 112 Power Cycle',
            subtitle: 'Remote reboot successful. Unit returning to route.',
            time: '45m ago',
            dimmed: true,
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.severity,
    required this.severityColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.dimmed = false,
  });

  final String severity;
  final Color severityColor;
  final String title;
  final String subtitle;
  final String time;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.7 : 1.0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border(left: BorderSide(color: severityColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  severity,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: severityColor,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(time,
                    style: GoogleFonts.manrope(fontSize: 10, color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title,
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/api_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/global_app_bar.dart';

/// Service Alerts screen — mirrors the web "Service Alerts" page.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _repo = ApiRepository.instance;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _repo.alerts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Service Alerts',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          GlobalHeaderActions(
            onRefresh: _refresh,
            onNotifications: () {},
            onProfile: () {},
          ),
        ],
      ),
      body: _refreshing
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Live updates for routes in your area',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Live',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    100,
                  ),
                  sliver: SliverList.separated(
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _AlertCard(alert: alerts[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final ServiceAlert alert;

  @override
  Widget build(BuildContext context) {
    final cfg = _alertConfig(alert.type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: cfg.borderColor.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cfg.iconBg,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              alignment: Alignment.center,
              child: Icon(cfg.icon, color: cfg.iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeChip(label: cfg.label, color: cfg.labelColor, bg: cfg.labelBg),
                      const SizedBox(width: 8),
                      _RouteChip(code: alert.routeCode),
                      const Spacer(),
                      Text(
                        _formatTime(alert.timestamp),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.body,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  _AlertCfg _alertConfig(AlertType t) {
    switch (t) {
      case AlertType.disruption:
        return _AlertCfg(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBg: const Color(0xFFDC2626).withOpacity(0.10),
          borderColor: const Color(0xFFDC2626),
          label: 'DISRUPTION',
          labelColor: const Color(0xFFDC2626),
          labelBg: const Color(0xFFDC2626).withOpacity(0.10),
        );
      case AlertType.delay:
        return _AlertCfg(
          icon: Icons.watch_later_outlined,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFD97706).withOpacity(0.10),
          borderColor: const Color(0xFFD97706),
          label: 'DELAY',
          labelColor: const Color(0xFFD97706),
          labelBg: const Color(0xFFD97706).withOpacity(0.10),
        );
      case AlertType.info:
        return _AlertCfg(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primary.withOpacity(0.10),
          borderColor: AppColors.primary,
          label: 'INFO',
          labelColor: AppColors.primary,
          labelBg: AppColors.primary.withOpacity(0.10),
        );
    }
  }
}

class _AlertCfg {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color borderColor;
  final String label;
  final Color labelColor;
  final Color labelBg;

  const _AlertCfg({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.borderColor,
    required this.label,
    required this.labelColor,
    required this.labelBg,
  });
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Route $code',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

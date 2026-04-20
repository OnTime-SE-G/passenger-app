import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ontime_logo.dart';
import '../widgets/route_badge.dart';
import '../widgets/status_chip.dart';
import 'stop_details_screen.dart';

/// Routes screen — "Transit Flux" layout matching the reference.
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final _repo = DemoRepository.instance;
  String _filter = 'ALL ROUTES';

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
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppColors.primary), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 72,
          bottom: 120,
        ),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transit Flux', style: AppTypography.headline(36).copyWith(color: AppColors.primary)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Real-time terminal connections and active route monitoring across the metropolitan grid.',
                  style: AppTypography.body(14),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              children: ['ALL ROUTES', 'BUS', 'EXPRESS', 'NIGHT'].map((f) {
                final active = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (active) ...[
                            const Icon(Icons.filter_list, size: 14, color: AppColors.primaryFixed),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            f,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: active ? AppColors.primaryFixed : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Featured route card
          if (_repo.routes.isNotEmpty)
            _FeaturedRouteCard(route: _repo.routes[0]),
          const SizedBox(height: AppSpacing.lg),

          // Route cards grid
          ..._repo.routes.skip(1).map((r) => Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                child: _RouteCard(route: r),
              )),

          // Network flux density
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _NetworkFluxDensity(),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRouteCard extends StatelessWidget {
  const _FeaturedRouteCard({required this.route});
  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final repo = DemoRepository.instance;
    final busCount = repo.busesForRoute(route.id).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteBadge(code: route.code, featured: true),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIGH VELOCITY EXPRESS',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(route.name, style: AppTypography.headline(22)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(route.origin.toUpperCase(),
                    style: GoogleFonts.manrope(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Icon(Icons.trending_flat, color: AppColors.secondary, size: 16),
                ),
                Text(route.destination.toUpperCase(),
                    style: GoogleFonts.manrope(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$busCount ACTIVE BUSES',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Frequency: Every 8 mins',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});
  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final repo = DemoRepository.instance;
    final busCount = repo.busesForRoute(route.id).length;
    final pos = repo.buses.where((b) => b.routeId == route.id).isNotEmpty
        ? repo.snapshotFor(repo.buses.firstWhere((b) => b.routeId == route.id).id)
        : null;
    final isDelayed = pos?.status == BusLiveStatus.delayed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RouteBadge(code: route.code),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDelayed ? AppColors.error : AppColors.secondary).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDelayed ? AppColors.error : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDelayed ? 'DELAYED' : '$busCount LIVE',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDelayed ? AppColors.error : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'ROUTE PATH',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(route.name, style: AppTypography.headline(18)),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text(route.origin.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 1, color: AppColors.outlineVariant.withOpacity(0.3)),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: (isDelayed ? AppColors.error : AppColors.primary).withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(route.destination.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkFluxDensity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.secondary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text('Network Flux Density', style: AppTypography.headline(18)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _FluxBar(label: 'Downtown Transit Hub', value: 0.85, accent: 'HIGH LOAD', isHigh: true),
          const SizedBox(height: AppSpacing.xl),
          _FluxBar(label: 'Midtown East Terminals', value: 0.42, accent: 'STABLE', isHigh: false),
        ],
      ),
    );
  }
}

class _FluxBar extends StatelessWidget {
  const _FluxBar({
    required this.label,
    required this.value,
    required this.accent,
    required this.isHigh,
  });

  final String label;
  final double value;
  final String accent;
  final bool isHigh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isHigh
                  ? [AppColors.secondary, AppColors.secondaryContainer]
                  : [AppColors.outlineVariant.withOpacity(0.3), AppColors.outlineVariant.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  Text(accent,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isHigh ? AppColors.secondary : AppColors.onSurfaceVariant,
                      )),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(isHigh ? AppColors.secondary : AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

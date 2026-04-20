import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/ontime_logo.dart';
import '../widgets/route_badge.dart';
import '../widgets/search_field.dart';
import '../widgets/status_chip.dart';
import 'nearby_stops_screen.dart';
import 'live_tracking_screen.dart';

/// Home screen — matches Signal Flux "Home / Passenger View" exactly.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = DemoRepository.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
        title: const OnTimeLogo(size: OnTimeLogoSize.small),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.person, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 72,
          bottom: 120,
        ),
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: AppTypography.label(11, color: AppColors.onSurfaceVariant).copyWith(
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good Morning, Alex',
                  style: AppTypography.headline(28),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SearchField(
              hint: 'Search route / bus',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NearbyStopsScreen()),
                );
              },
              readOnly: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Nearby Buses
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Text('Nearby buses', style: AppTypography.headline(20)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NearbyStopsScreen()),
                    );
                  },
                  child: Text(
                    'SEE ALL',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Horizontal bus cards
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: repo.buses.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
              itemBuilder: (_, i) {
                final bus = repo.buses[i];
                final route = repo.routeById(bus.routeId);
                final pos = repo.snapshotFor(bus.id);
                final status = _mapStatus(pos.status);
                return _NearbyBusCard(
                  code: route.code,
                  destination: route.destination,
                  eta: pos.etaMinutes,
                  stopName: repo.stops.isNotEmpty ? repo.stops.first.name : '',
                  status: status,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LiveTrackingScreen(busId: bus.id)),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.my_location,
                  label: 'TRACK BUS',
                  highlighted: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NearbyStopsScreen()),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                _QuickAction(
                  icon: Icons.map_outlined,
                  label: 'VIEW ROUTES',
                  onTap: () {},
                ),
                const SizedBox(width: AppSpacing.md),
                _QuickAction(
                  icon: Icons.report_outlined,
                  label: 'REPORT',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Favorite Routes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text('Favorite Routes', style: AppTypography.headline(20)),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FavoriteRouteItem(
            route: repo.routes[0],
            subtitle: 'Home → Workplace',
            isFirst: true,
          ),
          _FavoriteRouteItem(
            route: repo.routes[1],
            subtitle: 'Parkside → Downtown',
            isFirst: false,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Promo banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryContainer.withOpacity(0.4),
                    AppColors.background,
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NEW UPDATE',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Track 100% of Fleet in Real-Time',
                      style: AppTypography.headline(20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _NearbyBusCard extends StatelessWidget {
  const _NearbyBusCard({
    required this.code,
    required this.destination,
    required this.eta,
    required this.stopName,
    required this.status,
    required this.onTap,
  });

  final String code;
  final String destination;
  final int eta;
  final String stopName;
  final BusStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RouteBadge(code: code),
                StatusChip(status: status, dense: true),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'TO ${destination.toUpperCase()}',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$eta mins',
              style: AppTypography.headline(24),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    stopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.highlighted = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: highlighted ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlighted ? AppColors.primary : AppColors.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteRouteItem extends StatelessWidget {
  const _FavoriteRouteItem({
    required this.route,
    required this.subtitle,
    required this.isFirst,
  });

  final BusRoute route;
  final String subtitle;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flux stream line
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isFirst ? AppColors.secondary : AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
                Container(
                  width: 3,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isFirst
                          ? [AppColors.secondary, AppColors.secondaryContainer]
                          : [AppColors.secondaryContainer, AppColors.surfaceVariant],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBright,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route ${route.code}',
                          style: AppTypography.headline(16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.star, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BusStatus _mapStatus(BusLiveStatus s) {
  switch (s) {
    case BusLiveStatus.onTime:
      return BusStatus.onTime;
    case BusLiveStatus.delayed:
      return BusStatus.delayed;
    case BusLiveStatus.arriving:
      return BusStatus.arriving;
    case BusLiveStatus.cancelled:
      return BusStatus.cancelled;
  }
}

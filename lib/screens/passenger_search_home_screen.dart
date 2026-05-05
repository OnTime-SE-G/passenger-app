import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/map_widgets.dart';
import '../widgets/primary_button.dart';
import '../widgets/ontime_logo.dart';
import '../widgets/notifications_sheet.dart';
import '../services/app_tab_controller.dart';
import 'nearby_stops_screen.dart';
import 'profile_screen.dart';

/// Search home — origin / destination card + Voyager preview + recent routes.
class PassengerSearchHomeScreen extends StatefulWidget {
  const PassengerSearchHomeScreen({super.key});

  @override
  State<PassengerSearchHomeScreen> createState() =>
      _PassengerSearchHomeScreenState();
}

class _PassengerSearchHomeScreenState extends State<PassengerSearchHomeScreen> {
  final _repo = ApiRepository.instance;
  final _mapCtl = MapController();
  final _originCtl = TextEditingController(text: 'Current Location');
  final _destinationCtl = TextEditingController();

  @override
  void dispose() {
    _originCtl.dispose();
    _destinationCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _repo.userLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          OnTimeLogo(size: OnTimeLogoSize.normal),
                        ],
                      ),
                    ),
                    GlobalHeaderActions(
                      onRefresh: () => setState(() {}),
                      onNotifications: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const NotificationsSheet(),
                        );
                      },
                      onProfile: () {
                        AppTabController.instance.jumpTo(5);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where to?',
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.9,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Find the best route across the transit network.',
                      style: AppTypography.body(15, weight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Search card (origin / destination)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        boxShadow: kAmbientShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InputRow(
                            icon: Icons.my_location,
                            iconFilled: true,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Origin',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                              controller: _originCtl,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(left: 22),
                                  width: 2,
                                  height: 22,
                                  color: AppColors.surfaceContainerHigh,
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    final origin = _originCtl.text;
                                    final dest = _destinationCtl.text;
                                    setState(() {
                                      _originCtl.text = dest.isNotEmpty ? dest : 'Current Location';
                                      _destinationCtl.text = origin == 'Current Location' ? '' : origin;
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withOpacity(0.10),
                                    child: const Icon(
                                      Icons.swap_vert,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _InputRow(
                            icon: Icons.place_outlined,
                            iconFilled: false,
                            child: TextField(
                              controller: _destinationCtl,
                              decoration: const InputDecoration(
                                hintText: 'Destination',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: GoogleFonts.inter(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.schedule, size: 18),
                                  label: const Text('Leave Now'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Options',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PrimaryButton(
                            label: 'Search Route',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const NearbyStopsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      'RECENT SEARCHES',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._repo.recentSearches.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const NearbyStopsScreen(),
                                ),
                              );
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius,
                                ),
                                boxShadow: kAmbientShadow,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        AppColors.surfaceContainer,
                                    child: Icon(
                                      Icons.history,
                                      color: AppColors.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r.from} → ${r.to}',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Saved route · tap to open stops',
                                          style: AppTypography.body(13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Map preview — asymmetric column second half on web; stacked on mobile.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: SizedBox(
                        height: 280,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            buildMap(
                              controller: _mapCtl,
                              center: center,
                              zoom: 13,
                              interactive: false,
                              layers: [
                                const AppMapTiles(),
                                PolylineLayer(
                                  polylines: _repo.routes.map((route) {
                                    return Polyline(
                                      points: route.path,
                                      strokeWidth: 3,
                                      color: AppColors.primary.withOpacity(
                                        0.75,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: center,
                                      width: 48,
                                      height: 48,
                                      child: const UserLocationMarker(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              left: AppSpacing.md,
                              right: AppSpacing.md,
                              bottom: AppSpacing.md,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 16,
                                    sigmaY: 16,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: glassPanelDecoration(radius: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                              children: const [
                                                TextSpan(text: 'Live Network: '),
                                                TextSpan(
                                                  text: 'Good Service',
                                                  style: TextStyle(
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.my_location),
                                          color: AppColors.primary,
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.icon,
    required this.child,
    this.iconFilled = false,
  });

  final IconData icon;
  final Widget child;
  final bool iconFilled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Icon(
              icon,
              size: 20,
              color: iconFilled ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

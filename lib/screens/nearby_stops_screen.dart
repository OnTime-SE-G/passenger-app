import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../data/demo_repository.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_card.dart';
import '../widgets/map_widgets.dart';
import '../widgets/primary_button.dart';
import '../widgets/route_badge.dart';
import '../widgets/sheet_handle.dart';
import 'stop_details_screen.dart';

/// Screen 2 — Full dark map with nearby stops in a draggable bottom sheet.
class NearbyStopsScreen extends StatefulWidget {
  const NearbyStopsScreen({super.key, this.destinationQuery});
  final String? destinationQuery;

  @override
  State<NearbyStopsScreen> createState() => _NearbyStopsScreenState();
}

class _NearbyStopsScreenState extends State<NearbyStopsScreen> {
  final _repo = DemoRepository.instance;
  final _mapCtl = MapController();
  BusStop? _selected;

  @override
  void initState() {
    super.initState();
    final n = _repo.nearbyStops(_repo.userLocation);
    if (n.isNotEmpty) _selected = n.first.stop;
  }

  void _select(BusStop s) {
    setState(() => _selected = s);
    _mapCtl.move(s.location, 16);
  }

  @override
  Widget build(BuildContext context) {
    final nearby = _repo.nearbyStops(_repo.userLocation);

    return Scaffold(
      body: Stack(
        children: [
          buildMap(
            controller: _mapCtl,
            center: _repo.userLocation,
            zoom: 15,
            layers: [
              const AppMapTiles(),
              MarkerLayer(markers: [
                Marker(
                  point: _repo.userLocation,
                  width: 48,
                  height: 48,
                  child: const UserLocationMarker(),
                ),
                ..._repo.stops.map(
                  (s) => Marker(
                    point: s.location,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _select(s),
                      child: StopMarker(selected: _selected?.id == s.id),
                    ),
                  ),
                ),
              ]),
            ],
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(
                      widget.destinationQuery ?? 'Nearby Stops',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FABs
          Positioned(
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).size.height * 0.42 + AppSpacing.md,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.my_location,
                  onPressed: () => _mapCtl.move(_repo.userLocation, 15),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MapFab(icon: Icons.layers_outlined, onPressed: () {}),
              ],
            ),
          ),

          // Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.18,
            maxChildSize: 0.85,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  children: [
                    const SheetHandle(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Text('Nearby stops', style: AppTypography.headline(20)),
                          const Spacer(),
                          Text('${nearby.length} found',
                              style: GoogleFonts.manrope(color: AppColors.outline, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        itemCount: nearby.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final entry = nearby[i];
                          return _StopTile(
                            stop: entry.stop,
                            meters: entry.meters,
                            selected: _selected?.id == entry.stop.id,
                            onTap: () => _select(entry.stop),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
                      ),
                      child: PrimaryButton(
                        label: _selected == null
                            ? 'Select Stop'
                            : 'Select ${_selected!.name}',
                        icon: Icons.arrow_forward,
                        onPressed: _selected == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StopDetailsScreen(stop: _selected!),
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.meters,
    required this.selected,
    required this.onTap,
  });

  final BusStop stop;
  final double meters;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final repo = DemoRepository.instance;
    return AppCard(
      onTap: onTap,
      color: selected ? AppColors.primaryContainer.withOpacity(0.3) : AppColors.surfaceContainerLow,
      borderColor: selected ? AppColors.primary.withOpacity(0.4) : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary.withOpacity(0.2) : AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Icon(
              Icons.place,
              color: selected ? AppColors.secondary : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700, color: AppColors.onSurface, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${meters.toStringAsFixed(0)} m · ${stop.routeIds.length} routes',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppColors.outline),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: stop.routeIds
                .take(2)
                .map((id) => RouteBadge(code: repo.routeById(id).code, size: 32))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12),
          ],
        ),
        child: Icon(icon, color: AppColors.onSurface, size: 20),
      ),
    );
  }
}
